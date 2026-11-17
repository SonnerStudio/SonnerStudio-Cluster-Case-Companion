# SS-CCC Verbund-Server (`core/cluster`)

Server-Teil des SonnerStudio Verbund-Begleiters: stellt lokale Sprach- und Bildmodelle
auf einem oder zwei Apple-Silicon-Macs als **OpenAI-kompatible Schnittstelle** bereit
(`http://<Leitrechner>:8000/v1`) – für Hermes, OpenCode, Antigravity, Cursor, VS Code und
die SS-CCC-App selbst.

Alles läuft unter dem **gemeinsamen Pfad `/Users/Shared/ssccc`** (auf jedem Mac gleich,
unabhängig vom Benutzernamen). Rechnerspezifische Werte stehen in
`/Users/Shared/ssccc/cluster.json` (Vorlage: `cluster.example.json`).

## Betriebsarten (`cluster.json` → `mode`, oder Datei `/Users/Shared/ssccc/modus`)

| Betriebsart | Leitrechner | Worker | Wofür |
|---|---|---|---|
| `multimodel` (Standard) | Sprachmodell + **MTP** (mlx-vlm), Bildmodell **auf Abruf** | Antwort-Reserve, lokale Weiterleitung | Tempo: ein Mac allein ist schneller als ein geteiltes Modell |
| `verbund` | Rang 0 eines geteilten Modells | Rang 1 | Kapazität: Modelle, die nicht auf einen Mac passen |

Gemessen (Mac Studio M5 Max 36 GB + Mac mini M4 16 GB, Qwen3.8-27B):
Verbund 8 Bit 49 Zeichen/s (≈ 11,6 tok/s) · Studio allein 4 Bit 105 · **4 Bit + MTP 170** (3,5×).

## Dateien

| Datei | Aufgabe |
|---|---|
| `ssccc_config.py` | lädt `cluster.json` + Standardwerte; `python ssccc_config.py env` liefert Shell-Variablen |
| `ssccc_gateway.py` | Gateway `:8000` im Multi-Model-Mode (Chat-Weiterleitung, Bilder, Reserve, Status) |
| `gemini_adapter.py` | Gemini-Protokoll (`/v1beta/models/…:streamGenerateContent`) für Google Antigravity |
| `ssccc_server.py` | Verbund-Server: `mlx_lm.server` mit speicher-/bandbreitengewichteter Pipeline-Aufteilung |
| `start_ssccc.sh` | Start durch den LaunchAgent, wählt die Betriebsart |
| `start_verbund.sh` | Verbund-Start, ermittelt Adressen live und wählt TB+LAN › TB › LAN › WLAN |
| `node_info.sh` | Hardware- und Bereitschaftsdaten eines Macs als JSON |
| `make_rank_shard.py` | erzeugt den Modellanteil eines Rangs (nur dessen Schichten) zum Verteilen per LAN |
| `forward.py` | Weiterleitung `127.0.0.1:8090` → Gateway (auf dem Worker) |
| `launchd/*.plist` | Vorlagen für Autostart, Reserve, Weiterleitung, dauerhafte GPU-Speicherfreigabe |
| `tools/` | Messwerkzeuge (Tempo, langer Kontext) |

## Schnittstellen

- `GET /v1/models` – mit `context_window`, `max_output_tokens` (Antigravity braucht das)
- `POST /v1/chat/completions`, `/v1/responses` … – an das Sprachmodell (jeder Modellname wird auf das geladene Modell abgebildet)
- `POST /v1/images/generations` – Bild in nativer Auflösung (~4 MP); `quality: "low"` = 1024²-Vorschau
- `POST /v1/images/edits` – Bearbeitung / bis zu 3 Referenzbilder (Multipart oder JSON)
- `POST /v1beta/models/<m>:streamGenerateContent` – Gemini-Format (Antigravity)
- `GET /ssccc/cluster` – Verbundstatus mit Prüfwerten je Mac (für die App)
- `GET /health`

## Anbindung der Programme

- **Hermes:** `providers.ssccc.base_url = http://<Leitrechner>:8000/v1`, `model.provider = ssccc`, `image_gen.provider = openai`, `image_gen.openai.provider = ssccc`
- **OpenCode:** Provider `@ai-sdk/openai-compatible` mit `baseURL` und `limit.context`
- **Antigravity (CLI):** `AGY_LLM_GATEWAY_URL`, `AGY_LLM_GATEWAY_WIRE_PROTOCOL=openai` (Befehl `agy-ssccc`). Entfernte Gateways verlangen `https://` → auf dem Worker über `forward.py` (`http://127.0.0.1:8090`). Die Desktop-IDE nutzt bei Google-Anmeldung nur Google-Modelle.
- **Auf dem Worker** immer `http://127.0.0.1:8090` statt `*.local` verwenden (siehe Stolpersteine).

## Erfahrungen / Stolpersteine aus der Einrichtung

1. **Gemeinsamer Pfad:** `mlx.launch` startet überall dieselbe Befehlszeile → `/Users/Shared/ssccc` statt Home-Ordner.
2. **Leitrechner ohne SSH zu sich selbst:** im Hostfile `"ssh": "127.0.0.1"` – dann startet `mlx.launch` lokal, „Entfernte Anmeldung“ ist nur auf Workern nötig.
3. **macOS „Lokales Netzwerk“:** per launchd gestartetes Python bekommt ohne Freigabe „No route to host“ (nur der Router ist erreichbar) → `python3.12` unter *Datenschutz & Sicherheit → Lokales Netzwerk* erlauben.
4. **IPv6 bei `*.local`:** Python/Node probieren zuerst link-local-IPv6-Adressen und hängen minutenlang → IPv4 direkt ermitteln bzw. lokale Weiterleitung.
5. **Thunderbolt erkennen:** Ein USB-C-Kabel ohne Thunderbolt baut nur ein USB-Netz (NCM, 100 Mbit) auf. Prüfen über den Transport „CIO“ im IORegistry bzw. `bridge0`; nur hintere Anschlüsse des Mac mini können Thunderbolt.
6. **WLAN vermeiden:** gemessen 5,4 ms statt 0,6 ms pro Austausch (Spitzen bis 55 ms). LAN+WLAN im selben Subnetz bündeln bringt nichts – macOS nutzt ohnehin den bevorzugten Anschluss.
7. **Aufteilung nach Bandbreite:** Der langsamere Mac bremst jede Schicht. Embedding nur auf dem letzten Rang, lm_head nach Vokabular teilen, 8-Bit-KV-Cache, `--prefill-step-size 512`, Prompt-Cache begrenzen.
8. **Modellnamen pinnen:** `mlx_lm.server`/`mlx-vlm` laden bei unbekanntem Modellnamen ein neues Modell aus dem Internet.
9. **`mlx.launch` und Optionen:** `--host` u. ä. wertet `mlx.launch` selbst aus → Server-Argumente über `SSCCC_SERVER_ARGS`.
10. **Selbstheilung:** Prozess bei Generierungsfehler beenden, launchd (`KeepAlive`) startet neu.
11. **Downloads:** Hugging-Face-Downloads über Xet bleiben hängen → `HF_HUB_DISABLE_XET=1` und Wiederholungen.
12. **Server „bereit“:** mlx-vlm antwortet auf `/v1/models`, bevor das Modell geladen ist (503) → auf eine echte Chat-Antwort warten.
13. **Speicherschutz:** `iogpu.wired_limit_mb` geht beim Neustart verloren → LaunchDaemon `de.sonnerstudio.wiredlimit`.
14. **Lizenzen:** Qwen-Image 2.1 und Ideogram 4 sind nicht kommerziell; HiDream-O1 (MIT) ist kommerziell nutzbar. BF16 verwenden (Q8/Q6 zeigen Raster bei nicht-quadratischen Formaten).
15. **Per SSH gestartete GUI-Apps** laufen außerhalb der Bildschirm-Sitzung (Zeitgeber pausieren) → Apps lokal starten.
16. **exFAT-Laufwerke** erzeugen `._*`-Dateien, die Git stören; macOS-`rsync` überspringt unmaskierte Pfade mit Leerzeichen ohne Fehlermeldung.
