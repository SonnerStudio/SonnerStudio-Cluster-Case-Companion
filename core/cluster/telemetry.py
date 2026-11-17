"""Live-Telemetrie des Gateways (für das Forschungslabor der SS-CCC-App).

Misst je Chat-Anfrage Zeit bis zum ersten Token (TTFT), Gesamtdauer, erzeugte Token
und Token/s; dazu Zähler für abgelehnte Anfragen, Bilder, Neustarts und den
Speicherzustand des Rechners. Abruf: GET /ssccc/metrics.
"""

import collections
import time

try:
    import psutil
except ImportError:  # pragma: no cover
    psutil = None


class Telemetry:
    def __init__(self, keep: int = 50):
        self.started = time.time()
        self.recent = collections.deque(maxlen=keep)
        self.counters = collections.Counter()

    def record(self, *, path: str, ttft: float | None, duration: float, tokens: int,
               prompt_tokens: int | None, target: str, ok: bool = True):
        decode = duration - (ttft or 0)
        rate = tokens / decode if tokens > 1 and decode > 0 else None
        self.recent.append({"t": round(time.time(), 1), "path": path, "ttft_s": round(ttft, 3) if ttft else None,
                            "duration_s": round(duration, 2), "tokens": tokens, "prompt_tokens": prompt_tokens,
                            "tok_s": round(rate, 1) if rate else None, "target": target, "ok": ok})
        self.counters["requests"] += 1
        if not ok:
            self.counters["failed"] += 1

    def count(self, key: str, n: int = 1):
        self.counters[key] += n

    @staticmethod
    def memory() -> dict:
        if psutil is None:
            return {}
        vm, sw = psutil.virtual_memory(), psutil.swap_memory()
        return {"total_gb": round(vm.total / 2**30, 1), "available_gb": round(vm.available / 2**30, 1),
                "used_percent": vm.percent, "swap_used_gb": round(sw.used / 2**30, 1)}

    def summary(self) -> dict:
        rates = [r["tok_s"] for r in self.recent if r["tok_s"]]
        ttfts = [r["ttft_s"] for r in self.recent if r["ttft_s"]]
        return {
            "uptime_s": int(time.time() - self.started),
            "counters": dict(self.counters),
            "avg_tok_s": round(sum(rates) / len(rates), 1) if rates else None,
            "last_tok_s": rates[-1] if rates else None,
            "avg_ttft_s": round(sum(ttfts) / len(ttfts), 2) if ttfts else None,
            "recent": list(self.recent)[-20:],
            "memory": self.memory(),
        }
