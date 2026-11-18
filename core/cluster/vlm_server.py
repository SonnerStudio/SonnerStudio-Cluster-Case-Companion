"""Startet den mlx-vlm-Server mit SS-CCC-Korrekturen.

Aufruf wie ``python -m mlx_vlm.server``; alle Argumente werden durchgereicht.

Korrektur 1 – Kaltstart statt Abbruch bei Prefix-Cache-Speicherdruck (mlx-vlm 0.8.0):
Bei einem Cache-Treffer lädt der Server den gespeicherten Snapshot (SSD oder RAM)
und verlangt zusätzlich das Doppelte seiner Größe als freien Speicher. Reicht das
nicht, wird die Wiederherstellung zurückgestellt – und weil sonst keine Anfrage
läuft, bricht der Server mit „cannot fit the APC prefill memory budget even
alone“ ab, obwohl die Anfrage ohne Cache (kalt) problemlos passt. Agenten-Clients
schicken jede Runde denselben, wachsenden Verlauf, treffen also immer den
Cache und scheitern ab ~50k Tokens bei jedem Versuch.

Die Korrektur nimmt die Anfrage in diesem Fall ohne Cache-Treffer an (Kaltstart),
sofern nichts anderes läuft. Läuft noch eine Anfrage, wartet sie wie bisher.
"""
from __future__ import annotations

import sys


_WS_MARGIN = 2 * 2**30   # Puffer für Aktivierungen und MTP-Entwurf


def _cold_fits_working_set(coordinator) -> bool:
    """Passt ein Kaltstart in den GPU-Arbeitsspeicher, auch wenn das APC-Budget ablehnt?

    Das APC-Budget rechnet mit dem doppelten KV-Bedarf und dem gerade freien
    System-RAM. Bei ~70k Tokens lehnt es deshalb selbst Kaltstarts ab, obwohl
    Modell plus Cache weit unter dem GPU-Arbeitsspeicher bleiben. Maßgeblich ist
    hier der tatsächliche Bedarf (halbe Reserve) gegen den Arbeitsspeicher;
    macOS lagert dafür notfalls andere Programme aus.
    """
    try:
        import mlx.core as mx
        need = coordinator.manager.memory_plan.reserve_bytes() // 2
        ws = int(mx.device_info()["max_recommended_working_set_size"])
        fits = mx.get_active_memory() + need + _WS_MARGIN <= ws
        print(f"[ssccc] APC-Budget lehnt ab; tatsächlicher Bedarf {need / 2**30:.1f} GB – "
              + ("Kaltstart trotzdem zugelassen" if fits else "passt nicht in den Arbeitsspeicher"),
              flush=True)
        return fits
    except Exception:
        return False


def _patch_cold_fallback() -> bool:
    try:
        from mlx_vlm import apc as _apc
        from mlx_vlm.generate import ar
    except Exception as e:  # andere mlx-vlm-Version: ohne Korrektur starten
        print(f"[ssccc] Kaltstart-Korrektur nicht aktiv: {e}", flush=True)
        return False
    cls = getattr(ar, "BatchGenerator", None)
    orig_admit = getattr(cls, "_admit_prefill", None)
    orig_pick = getattr(cls, "_apc_pick_for", None)
    if orig_admit is None or orig_pick is None or getattr(orig_admit, "_ssccc", False):
        return False

    def _admit_prefill(self, sequences):
        sequences_out, picks = orig_admit(self, sequences)
        if sequences_out or not sequences:
            return sequences_out, picks
        # Nichts zugelassen. Läuft noch eine andere Anfrage, später erneut versuchen.
        if len(getattr(self, "_generation_batch", ()) or ()):
            return sequences_out, picks
        coordinator = getattr(self, "apc", None)
        first = sequences[0]
        if coordinator is not None:
            # Speicher für den Kaltstart der ältesten Anfrage freiräumen/prüfen
            ok = coordinator.prepare_prefill(
                [len(first[1])],
                prefill_step_size=self._prefill_chunk_size(1),
                prefix_lengths=[0],
            )
            if not ok and not _cold_fits_working_set(coordinator):
                return sequences_out, picks
        diag = ""
        try:
            import mlx.core as mx
            m = getattr(self, "apc_manager", None)
            gb = lambda b: f"{b / 2**30:.1f}"
            diag = (f" (aktiv {gb(mx.get_active_memory())} GB, Puffer {gb(mx.get_cache_memory())} GB"
                    + (f", Spielraum {gb(m._memory_headroom())} GB, Cache {gb(m.resident_bytes())} GB"
                       if m is not None else "") + ")")
        except Exception:
            pass
        print(f"[ssccc] Prefix-Cache-Wiederherstellung passt nicht in den Speicher – "
              f"Kaltstart für {len(first[1])} Tokens{diag}", flush=True)
        return [first], [None]

    _admit_prefill._ssccc = True
    cls._admit_prefill = _admit_prefill
    _ = _apc  # Import prüft nur, dass das APC-Modul vorhanden ist
    print("[ssccc] Kaltstart-Rückfall für den Prefix-Cache aktiv", flush=True)
    return True


def _patch_disk_restore_budget() -> bool:
    """Korrektur 2 – SSD-Snapshot nicht doppelt zählen (mlx-vlm 0.8.0).

    Nach dem Laden eines Snapshots von der SSD liegen dessen Puffer schon im
    Speicher; trotzdem verlangt ``lookup_exact_cache`` noch einmal das Doppelte
    der Größe als freien Platz. Bei 50k Tokens (3,5 GB Snapshot) scheitert das
    praktisch immer – jede Agenten-Runde rechnet dann ~80 s den ganzen Verlauf
    neu. Für das Erweitern auf die Promptlänge reicht die einfache Größe; die
    übrigen Prüfungen (Reserve, Prefill-Budget, Kopie für den RAM-Cache)
    bleiben unverändert.
    """
    import inspect
    import textwrap
    try:
        from mlx_vlm import apc
    except Exception:
        return False
    cls = getattr(apc, "APCManager", None)
    fn = getattr(cls, "lookup_exact_cache", None)
    if fn is None or getattr(fn, "_ssccc", False):
        return False
    try:
        src = textwrap.dedent(inspect.getsource(fn))
    except (OSError, TypeError):
        return False
    old = "self._make_room(2 * expanded_bytes)"
    if src.count(old) != 1:
        print("[ssccc] SSD-Snapshot-Korrektur nicht anwendbar (andere mlx-vlm-Version)", flush=True)
        return False
    ns: dict = {}
    exec(compile(src.replace(old, "self._make_room(expanded_bytes)"),
                 inspect.getsourcefile(fn) or "<apc>", "exec"), apc.__dict__, ns)
    new = ns[fn.__name__]
    new._ssccc = True
    setattr(cls, fn.__name__, new)
    print("[ssccc] SSD-Snapshot-Wiederherstellung ohne Doppelzählung aktiv", flush=True)
    return True


def _debug_make_room() -> None:
    import os
    if not os.environ.get("SSCCC_APC_DEBUG"):
        return
    from mlx_vlm import apc
    orig = apc.APCManager._make_room

    def _make_room(self, allocation_bytes=0, *, retain_bytes=0):
        ok = orig(self, allocation_bytes, retain_bytes=retain_bytes)
        if not ok:
            gb = lambda b: f"{b / 2**30:.2f}"
            print(f"[ssccc-debug] make_room abgelehnt: alloc={gb(allocation_bytes)} retain={gb(retain_bytes)} "
                  f"prefill_reserve={gb(self._prefill_reserve_bytes)} reserve={gb(self.memory_reserve_bytes)} "
                  f"headroom={gb(self._memory_headroom())} resident={gb(self.resident_bytes())}", flush=True)
        return ok
    apc.APCManager._make_room = _make_room


def main() -> None:
    _patch_cold_fallback()
    _patch_disk_restore_budget()
    _debug_make_room()
    from mlx_vlm.server import main as server_main
    sys.argv[0] = "mlx_vlm.server"
    server_main()


if __name__ == "__main__":
    main()
