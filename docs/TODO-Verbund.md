# SS-CCC – Todo-Liste Verbund (Stand 17.11.2026)

Arbeitsliste für den SonnerStudio-Verbund aus **Mac Studio M5 Max (36 GB, Rang 0)** und **Mac mini M4 (16 GB, Rang 1)** sowie für die Übernahme der dabei gesammelten Erfahrungen in die automatische Ersteinrichtung von SS-CCC.

Legende: `[x]` erledigt · `[~]` in Arbeit · `[ ]` offen

---

## Erreichter Stand

- [x] MLX-Pipeline-Verbund läuft (`mlx.launch --backend ring`, `mlx_lm.server --pipeline`), Qwen3.8-27B-8bit
- [x] Leistung optimiert: **7,9 → 11,6 tok/s** (Aufteilung 60/4, Embedding nur auf dem letzten Rang, lm_head nach Vokabular geteilt, 8-Bit-KV-Cache, LAN-Kabel statt WLAN), stabil bis ~67k Token Kontext
- [x] Autostart (LaunchAgent), Selbstheilung nach Absturz, automatische Netzwahl (TB+LAN › TB › LAN › WLAN)
- [x] Hermes (beide Macs) und OpenCode nutzen den Verbund (`:8000/v1`)
- [x] SS-CCC zeigt den echten Verbund live an, Bereitschaftsprüfung mit echten Messwerten → „Bereit“ auf beiden Macs (PR #1)

---

## 1. Laufende Aufgaben

### 1.1 MTP / schnelleres Qwen3.8
- [x] Prüfen: `mlx-lm` unterstützt kein MTP (MTP-Gewichte werden beim Laden verworfen), kein Speculative Decoding im Verbundbetrieb
- [x] Prüfen: `mlx-vlm` 0.8 unterstützt MTP für Qwen3.8 (`mlx-community/Qwen3.8-27B-MTP-8bit` / `-4bit`), verteilt aber nur per Tensor-Parallelität (ungeeignet für LAN und 16-GB-Mini)
- [x] Qwen3.8-27B-4bit + MTP-Drafter heruntergeladen
- [x] Gemessen (gleicher Prompt, Zeichen/s, da MTP mehrere Token je Paket liefert):
  | Variante | Zeichen/s | Faktor |
  |---|---|---|
  | Verbund, 8 Bit (60/4) | 49 (≙ 11,6 tok/s) | 1,0× |
  | Mac Studio allein, 4 Bit, mlx-vlm | 105 | 2,1× |
  | Mac Studio allein, 4 Bit + MTP (4 oder 8 Bit) | 170 | **3,5×** |
- [x] Studio allein + MTP ist jetzt Standard (4 Bit, 170 Zeichen/s über das Gateway gemessen)
- [ ] Prüfen, ob eine 6-Bit-Variante (z. B. `Qwen3.8-27B-oQ6`, 23,3 GB) mit mlx-vlm + MTP lädt (Qualität nahe 8 Bit, passt allein auf den Studio)

### 1.2 Architektur-Entscheidung
- [x] Entschieden: **Multi-Model-Mode** – Sprache (Qwen3.8 + MTP) und Bild (HiDream-O1 auf Abruf) auf dem Mac Studio; Mac mini als Reserve
- [x] Neues Gateway `ssccc_gateway.py` auf `:8000` (Chat-Durchreichung mit Modellnamen-Pinning, Bild-Endpunkt, `/ssccc/cluster`, `/health`)
- [x] Autostart über `start_ssccc.sh`; Betriebsart in `/Users/Shared/ssccc/modus` (`multimodel` | `verbund`), bisheriger Verbund bleibt umschaltbar
- [ ] Mac mini sinnvoll nutzen (z. B. kleines Sprachmodell als Antwort-Reserve während Bildaufträgen, Embeddings oder zweiter Bilddienst in Q6)

### 1.3 Bildgenerierung
- [x] Lizenzen geprüft: Qwen-Image 2.1 (Qwen Research License) und Ideogram 4 sind **nicht kommerziell** nutzbar
- [x] Gewählt: **HiDream-O1-Image-Dev** (MIT-Lizenz, Platz 2 der offenen Modelle bei Artificial Analysis), MLX-Portierung `mlx-community/HiDream-O1-Image-Dev-mlx-bf16` in **BF16** (Q8/Q6 zeigen Raster bei nicht-quadratischen Formaten, Q4 zu dunkel)
- [x] Gemessen (M5 Max): **2048×2048 in ~48 s** (nativ, beste Qualität, Spitze 19,8 GB), 1024×1024 in ~12 s (Vorschau)
- [x] Bild „auf Abruf“: Sprachmodell wird für den Auftrag entladen und danach neu gestartet (~7 s); Chat-Anfragen warten statt abzubrechen – getestet
- [x] `POST /v1/images/generations` (OpenAI-kompatibel): Größe = Seitenverhältnis, Ausgabe nativ ~4 MP; `quality: low` = 1024²-Vorschau; Bilder zusätzlich in `/Users/Shared/ssccc/bilder`
- [x] Hermes (beide Macs) erzeugt Bilder über `image_gen.openai.provider: ssccc` – getestet (2048×2048)
- [ ] Bildbearbeitung und Mehrfach-Referenzen (`--ref-images`) als `POST /v1/images/edits` anbieten
- [ ] SS-CCC Multi-Model-Mode: Slot „Bild“ in der App anzeigen

### 1.4 Videogenerierung (Bewertung)
- [x] Recherche: `mlx-video` (Wan 2.2, LTX-2) existiert als Community-Projekt; kleinstes Modell Wan2.2-TI2V-5B (8 Bit) ist für 64-GB-Macs beschrieben
- [ ] Machbarkeit auf dem Studio testen (nur bei entladenem Sprachmodell), Laufzeit pro Sekunde Video messen; auf dem 16-GB-Mini nicht sinnvoll
- [ ] Bei Eignung: Video als Auftrags-Warteschlange (asynchron) statt synchroner API

### 1.5 Offene Infrastruktur
- [ ] **Thunderbolt-4/5-Kabel besorgen** (vorhandenes USB-C-Kabel überträgt nur USB 2.0, kein Thunderbolt) und hinten an beiden Macs anschließen
- [ ] `iogpu.wired_limit_mb` dauerhaft machen (LaunchDaemons liegen bereit, brauchen Admin-Freigabe)
- [ ] Mini: Hermes-Gateway neu starten (übernimmt die neue Konfiguration erst dann)

---

## 2. Danach: Erfahrungen in die automatische Ersteinrichtung von SS-CCC übernehmen

Ziel: Die Schaltfläche **„Automatische Einrichtung“** richtet einen Verbund wirklich ein (statt nur Flags zu setzen) und nutzt alle Erkenntnisse aus der manuellen Einrichtung.

### 2.1 Server-Teil ins Repository
- [ ] `ssccc_gateway.py`, `start_ssccc.sh`, `ssccc_server.py`, `start_verbund.sh`, `node_info.sh`, `make_rank_shard.py` aus `/Users/Shared/ssccc` nach `core/cluster/` übernehmen und versionieren
- [ ] Statusendpunkt `/ssccc/cluster` dokumentieren (Felder, Prüfwerte)

### 2.2 Voraussetzungen prüfen und herstellen
- [ ] Xcode-Lizenz / Command Line Tools prüfen (ohne Lizenz starten weder `python3` noch `swiftc`)
- [ ] SSH: Schlüssel erzeugen, `ssh-copy-id` mit Passworteingabe durch den Nutzer; **Entfernte Anmeldung** nur auf Worker-Macs nötig (Leitrechner läuft lokal über `127.0.0.1` in `mlx.launch`)
- [ ] Gemeinsamer Pfad `/Users/Shared/ssccc` auf allen Macs (Benutzernamen unterscheiden sich), uv + Python 3.12 + MLX einmal installieren und per rsync auf Worker verteilen
- [ ] Freien Speicherplatz je Mac prüfen und vor dem Download warnen
- [ ] macOS-Freigabe **„Lokales Netzwerk“** für `python3.12` anleiten (sonst „No route to host“ im Autostart)
- [ ] `iogpu.wired_limit_mb` setzen und per LaunchDaemon dauerhaft machen (Admin-Freigabe)

### 2.3 Netzwerk
- [ ] Adressen bei jedem Start live ermitteln, Bonjour-Namen (`*.local`) statt fester IPs für Clients
- [ ] Thunderbolt korrekt erkennen: CIO-Transport im IORegistry prüfen statt nur Ping; USB-C-Kabel ohne Thunderbolt erkennen und Hinweis „Thunderbolt-4/5-Kabel nötig, hintere Anschlüsse“ anzeigen
- [ ] Ethernet vs. WLAN erkennen und vor WLAN warnen (gemessen: 5,4 ms statt 0,6 ms pro Austausch, Spitzen bis 55 ms)
- [ ] Netzwahl TB+LAN › TB › LAN › WLAN; USB-Netz (NCM, link-local) nur als Notweg
- [ ] Mini im WLAN: Hinweis, dass LAN+WLAN im selben Subnetz keinen Gewinn bringt

### 2.4 Modell und Aufteilung
- [ ] Aufteilung nach **Speicherbandbreite und Speicher** statt nur Speicher (langsamer Rang bekommt nur so viele Schichten, wie nötig sind)
- [ ] Embedding nur auf dem letzten Rang, lm_head nach Vokabular teilen, 8-Bit-KV-Cache ab 4096 Token, `--prefill-step-size 512`, Prompt-Cache begrenzen
- [ ] Rang-Modellanteile auf dem Leitrechner erzeugen und per LAN verteilen (`make_rank_shard.py`) statt auf jedem Mac komplett herunterzuladen
- [ ] Kontext-Stresstest bei der Einrichtung; maximale Kontextlänge automatisch an Clients weitergeben
- [ ] Modellnamen-Pinning (jeder angefragte Name → geladenes Verbundmodell)

### 2.5 Betrieb
- [ ] LaunchAgent für Autostart einrichten, Selbstheilung (Prozessende bei Generierungsfehler → Neustart)
- [ ] Download-Abbrüche erkennen und mit Wiederholung fortsetzen (beobachtet: Hängen bei 18 GB)
- [ ] Benchmark-Schaltfläche (tok/s, TTFT, Netzkosten pro Token) im Forschungslabor

### 2.6 Clients automatisch verbinden
- [ ] Hermes: `providers.ssccc`, `model.provider/default/base_url`, `context_length`, Alias zum Zurückwechseln, Sicherung der Konfiguration
- [ ] OpenCode: Provider `@ai-sdk/openai-compatible` mit `limit.context`
- [ ] Antigravity: Hinweis, dass nur Gemini-Format unterstützt wird
- [ ] Agenten-Tests (Werkzeugaufruf) als Teil der Bereitschaftsprüfung

### 2.7 App-Verbesserungen
- [ ] „Automatische Einrichtung“ führt die Schritte 2.2–2.6 tatsächlich aus und zeigt Fortschritt je Mac
- [ ] Einrichtungsstatus dauerhaft speichern (bisher nach jedem Neustart verloren)
- [ ] Bereitschaftsprüfung um Persistenz (wired_limit), Kontextgrenze und Bilddienst erweitern
- [ ] Hinweis: per SSH gestartete Apps laufen außerhalb der Bildschirm-Sitzung (Zeitgeber pausieren) → App lokal starten
- [ ] Neue Meldungen in allen 17 Sprachen

### 2.8 Bekannte Stolpersteine (dokumentieren)
- [ ] exFAT-Laufwerke erzeugen `._*`-Dateien, die Git stören („non-monotonic index“)
- [ ] macOS-`rsync` überspringt Pfade mit Leerzeichen ohne Fehlermeldung, wenn sie nicht maskiert sind
- [ ] `mlx.launch` wertet Optionen wie `--host` selbst aus → Server-Argumente über Umgebungsvariable übergeben
- [ ] `mlx_lm.server` lädt bei unbekanntem Modellnamen ein neues Modell aus dem Internet
