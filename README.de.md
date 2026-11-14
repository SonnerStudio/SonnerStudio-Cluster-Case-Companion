<div align="center">

# ☀️ SonnerStudio Verbund-Begleiter (SS-CCC)

**🇺🇸 🇬🇧 🇨🇦 [English](README.md)** · **🇩🇪 🇦🇹 🇨🇭 [Deutsch](README.de.md)** · **🇫🇷 🇧🇪 🇨🇭 [Français](README.fr.md)** · **🇪🇸 🇲🇽 🇦🇷 [Español](README.es.md)** · **🇵🇹 🇧🇷 [Português](README.pt.md)**

*Eigenständige macOS-Verbundverwaltung und verteilte MLX-Rechenoberfläche für Apple Silicon*

<table>
  <tr>
    <td align="center">
      <img src="docs/images/ssccc_cluster_52gb.png" alt="SS-CCC 52-GB-Verbundbetrieb" width="100%"/><br/>
      <sub><b>Verbundbetrieb (52 GB Gesamtspeicher · 2 Rechner)</b></sub>
    </td>
    <td align="center">
      <img src="docs/images/ssccc_single_16gb.png" alt="SS-CCC 16-GB-Einzelbetrieb" width="100%"/><br/>
      <sub><b>Einzelbetrieb (16 GB örtlich · 1 Rechner)</b></sub>
    </td>
  </tr>
</table>

</div>

---

## 🧭 Überblick

Der **SonnerStudio Verbund-Begleiter (SS-CCC)** koppelt den gemeinsamen Arbeitsspeicher beliebiger **Apple-Silicon-Macs (M1–M9+)** — vom einzelnen Mac mini oder MacBook Pro über örtliche **Thunderbolt-3/4/5- & RDMA-Verbünde** bis hin zu **weltweiten Internet-Verbünden (2–256+ Macs)** — mit unmittelbarer Anbindung an **MLX**, **oMLX**, **Ollama** und **llama.cpp**.

<div align="center">
  <img src="docs/images/ssccc_ecosystem_banner.jpg" alt="SS-CCC Universeller Apple-Silicon-Verbund M1–M9+ und 1-Klick-Werkzeuge" width="94%"/>
</div>

---

## 🌐 Weltweiter Internet-Verbund, Teilnehmer-Chat & Forschung

<table>
  <tr>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_internet_wan_mesh.jpg" alt="SS-CCC Weltweiter Internet-Mac-Verbund & Teilnehmer-Chat" width="100%"/><br/>
      <sub><b>Internet-Verbund & Teilnehmer-Chat</b><br/>Tailscale · WireGuard · libp2p QUIC · DERP · <code>/status</code> · <code>/layers</code> · <code>/ping</code></sub>
    </td>
    <td align="center" width="50%">
      <img src="docs/images/ssccc_science_roofline_hero.jpg" alt="SS-CCC Forschung, Grenzkurve & Energiebilanz" width="100%"/><br/>
      <sub><b>Forschung, Grenzkurve & Energiebilanz</b><br/>Log-Log-Grenzkurve · GPipe-Blase · <code>J/Token</code> · <code>p50/p95/p99</code> · CSV/JSON/BibTeX</sub>
    </td>
  </tr>
</table>

---

## 🏗️ Aufbau (Steuerungsebene, Thunderbolt & Internet-Verbund)

```mermaid
flowchart LR
  Clients["Cursor · VS Code · Xcode · OpenCode · Hermes · Antigravity"] -->|"Schnittstelle (:8000 / :11434)"| Rank0
  subgraph Control["Steuerungsebene (Kabelnetz / Funknetz / Tailscale)"]
    Discovery["Bonjour-Erkennung & WebSocket-Chat (/ws/wan/{room})"]
  end
  subgraph Data["Datenebene (TB3/4/5 · RDMA · WAN-Pipeline-Parallelität)"]
    Rank0["Rang 0 Leitrechner (höchste Bandbreite M1–M9+)"] <-->|"MLX ring / jaccl + FAST_SYNCH=1 (~4 µs)"| Workers["Arbeitsrechner (Rang 1..N · gewichtete Schichten)"]
  end
```

---

## ✨ Hauptfunktionen

- **Alle Apple-Silicon-Macs (M1–M9+) im Verbund:** Kopple beliebige **Mac mini, MacBook Air/Pro, iMac, Mac Studio oder Mac Pro** von **M1 bis M6** sowie künftige **M7-, M8-, M9+-Generationen** (Basis, Pro, Max, Ultra). Der schnellste Rechner übernimmt selbsttätig **Rang 0 (Leitrechner)**; die Schutzgrenze `iogpu.wired_limit_mb` hält macOS jederzeit flüssig.
- **Vollständige Hardware- & Sensor-Auslesung:** Liest `sysctl`, `sw_vers`, `system_profiler`, `ibv_devices`, `ipconfig`, `ioreg` und `ProcessInfo.thermalState` aus — inklusive **CPU-Leistungs-/Effizienzkernen, GPU-Kernen, Neural Engine (16/32 ANE-Kerne), NVMe-SSD-Gesamt- und Freispeicher, Temperatur/Thermik sowie Leistungsaufnahme**.
- **Alle Thunderbolt-Klassen (TB3 / TB4 / TB5) & Direktspeicherzugriff:** Berechnet paarweise Übertragungsraten dynamisch (`TB3/USB4: 26–32 Gbps`, `TB4: 30–37 Gbps`, `TB5: 65–80 Gbps`, `TB5 RDMA: 75–110 Gbps`) samt `MLX_METAL_FAST_SYNCH=1` (45× schnellere GPU/CPU-Abstimmung).
- **Echte Modell-Erkennung & Dienstprüfung:** Liest vorhandene und laufende Modelle unmittelbar aus **oMLX**, **Ollama**, **llama.cpp**, örtlichen `.gguf`-Dateien sowie `~/.cache/huggingface/hub` ein (keine Platzhalter-Profile bei leerem Stand, sondern direkte Laufzeitprüfung & kopierbare Einrichtungsbefehle), samt gewichteter Schichtenverteilung und KV-Verdichtung (`FP16 / 8-Bit / 4-Bit`).
- **6× Ein-Klick-Einrichtung für Agenten & Werkzeuge:** Sofortige Einrichtung für **OpenCode**, **Hermes Agent**, **Google Antigravity**, **Cursor**, **Visual Studio Code** und **Apple Xcode**.
- **Weltweiter Netzverbund (Internet-WAN) & Teilnehmer-Gespräch (`/ws/wan/{room_id}`):** Verbinde beliebige Apple-Silicon-Macs über verschlüsselte Tunnel (Tailscale/WireGuard, P2P-Weiterleitung über libp2p/DERP oder manuellen Endpunkt) zu großen weltweiten Rechnerverbünden samt Echtzeit-Teilnehmergespräch.
- **Fünf-Reiter-Forschungslabor (Lokal & Internet-WAN):** Wechsel nahtlos zwischen **Lokal (TB/RDMA)**, **Internet-WAN** und **Direktvergleich** in fünf Fachbereichen: **Grenzkurve & Engpass** (effektive Netz-Decke, kritische Batch-Größe $B^*$), **WAN-Netz & Skalierung** ($N=1\dots128$ Kurven, *Petals/SWARM*-Aktivierungs-Kompression, Nachzügler- & Schwankungs-Simulation, *DiLoCo* vs. DDP), **Speicher & KV-Analyse**, **Energie, CO₂ & Kosten** (`J/Token`, `EDP`, Strommix `gCO₂eq/kWh`) sowie **Messreihen & Ausgabe** (`CI₉₅`, `CV%`, `Goodput%`, `CSV / JSON / LaTeX / 8-Quellen-BibTeX`).
- **SonnerStudio-Gelb (`#FFD400`), fünfsprachiges Handbuch & Prüfsammlung (`tests/`):** Vollständige Oberfläche samt durchsuchbarer Hilfe (`⌘?`) auf **Deutsch, Englisch, Französisch, Spanisch und Portugiesisch**, abgesichert durch `tests/test_global_suite.py` (`python3 -m unittest discover -s tests -v`).

### 🖥️ Die neun Programmbereiche im Überblick

| Menüpunkt | Aufgabe & Inhalt |
| :--- | :--- |
| **1. Verbund-Übersicht** | Gesamtspeicher-Balken, aktive M1–M9+-Topologie und paarweise Thunderbolt-/RDMA-Übertragungsraten |
| **2. Geräte & Vergleich** | Beliebige M1–M9+-Macs hinzufügen/entfernen, CPU/GPU/ANE/SSD/Thermik/Strom auslesen und vergleichen |
| **3. Modell-Werkstatt** | Echte Modelle aus oMLX / Ollama / llama.cpp einlesen, Dienstbereitschaft prüfen, anteilige Schichtenverteilung & KV-Speicher regeln |
| **4. Netzwerk & Direktspeicher** | Mischbetrieb / TB / LAN / RDMA umschalten, `FAST_SYNCH=1` setzen und TB3/TB4/TB5-Klassen einsehen |
| **5. Weltweiter Verbund & Gespräch** | Macs weltweit per Tailscale/WireGuard/libp2p koppeln, Raum-Kennung teilen und im Echtzeit-Gespräch (`/ws/wan/{room_id}`) abstimmen |
| **6. Agenten & Werkzeuge** | Ein-Klick-Einrichtung für OpenCode, Hermes Agent, Antigravity, Cursor, VS Code und Xcode |
| **7. Forschung & Grenzkurve** | 5-Reiter-Forschungslabor (Lokal & Internet-WAN): Log-Log-Grenzkurve (`P = min(β·I, π_eff)`), Skalierung `N=1..128`, *Petals/SWARM* & *DiLoCo*, KV-Speichergleichung, `J/Token` / `EDP` / `CO₂`, `CI₉₅` & `Goodput%` sowie `CSV / JSON / LaTeX / BibTeX` |
| **8. Schnittstelle & Konsole** | OpenAI- (`/v1`) & Ollama-Endpunkte (`/api/tags`) prüfen und Verbund-Anfragen direkt testen |
| **9. Hilfe & Handbuch** | Durchsuchbares Handbuch in fünf Sprachen (`⌘?`) zu Verbund, Speicherschutz, Netzwerk und Agenten |

---

## 🛠️ Aus dem Quelltext übersetzen (Wichtig vor dem ersten Start)

> [!NOTE]
> Dieses Verzeichnis enthält den **Quelltext** von SS-CCC (es liegt keine fertig gebaute Programmdatei bei). Um eine startfähige Anwendung zu erhalten, muss das Programm zuerst auf deinem Apple-Silicon-Mac **örtlich übersetzt (kompiliert)** werden.

### Voraussetzungen
- Ein Apple-Silicon-Mac (**M1–M6**) mit **macOS 14.0 oder neuer**
- **Xcode-Befehlszeilenwerkzeuge** (enthalten `swiftc` und das macOS-Entwicklungspaket):
  ```bash
  xcode-select --install
  ```

### Schritt für Schritt zur startfähigen App
```bash
# 1. Repository herunterladen und in den Ordner wechseln
git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
cd SonnerStudio-Cluster-Case-Companion

# 2. Start- und Übersetzungsskript einmalig ausführbar machen
chmod +x scripts/run_ssccc.sh

# 3. Alle Swift-Quelltexte nach /tmp/SSCCCApp übersetzen und Programm sofort starten
./scripts/run_ssccc.sh
```
*(Wahlweise lässt sich das Programm auch über Swift Package Manager bauen: `cd app && swift build -c release`.)*

---

## 🚀 Schnellstart

```bash
# 1. Native macOS-Oberfläche starten
"./scripts/run_ssccc.sh"

# 2. (Optional) Python/FastAPI-Dienst starten
cd core && uv sync --extra dev
PYTHONPATH=".." uv run uvicorn core.api.gateway:app --host 0.0.0.0 --port 8000

# 3. Feste Punkt-zu-Punkt-Thunderbolt-Adressen einrichten
./scripts/setup_tb_network.sh studio   # 10.99.1.1
./scripts/setup_tb_network.sh mini     # 10.99.1.2
```

---

## 📚 Ausgewählte Dokumentation (vollständig im Hilfe-Bereich der App)

### 1. Alle Apple Mac mit M-Prozessor im Verbund (M1–M6)
SS-CCC unterstützt **jeden Mac mit Apple-Silicon-Chip** (**M1, M2, M3, M4, M5, M6** — Basis, Pro, Max und Ultra) über alle Bauformen hinweg (**Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio und Mac Pro**). Unter **Geräte & Vergleich** lassen sich beliebig viele M-Macs zum Verbund hinzufügen; der Rechner mit dem höchsten Speicherdurchsatz übernimmt selbsttätig **Rang 0 (Leitrechner)**.

| Chip-Familie | Speicherdurchsatz | Thunderbolt | Empfohlene macOS-Schutzreserve |
| :--- | :--- | :--- | :--- |
| **M1 / M2** (Basis) | 68 – 100 GB/s | TB 3 / USB4 (26–32 Gbps) | **4 GB** (bis 24 GB RAM) |
| **M3 / M4** (Basis) | 100 – 120 GB/s | TB 4 (30–37 Gbps) | **4 GB** (bis 24 GB RAM) |
| **M5 / M6** (Basis) | 153 – 180 GB/s | TB 5 (65–80 Gbps) | **4 GB** (bis 24 GB RAM) |
| **M1–M3 Pro** | 150 – 200 GB/s | TB 4 (30–37 Gbps) | **4 – 6 GB** |
| **M4–M6 Pro** | 273 – 310 GB/s | TB 5 (65–80 Gbps) | **4 – 6 GB** |
| **M1–M3 Max** | 400 GB/s | TB 4 (30–37 Gbps) | **6 GB** (32–64 GB RAM) |
| **M4–M6 Max** | 460 – 580 GB/s | TB 5 (65–80 Gbps) | **6 GB** (32–64 GB RAM) |
| **M1–M2 Ultra** / **M3 Ultra** | 800 GB/s | TB 4 / TB 5 | **8 GB** (ab 96 GB RAM) |

### 2. Speicherschutz & Gewichtetes Schichten-Aufteilen
- **Niemals 100 % des RAM freigeben:** SS-CCC schützt den Betriebssystem-Anteil über `iogpu.wired_limit_mb`, damit macOS und WindowServer jederzeit flüssig bleiben.
- **Anteilige Schichtenverteilung:** Jeder Mac erhält genau den Anteil an Modellschichten, der seinem nutzbaren Speicher entspricht (`Schichten_i = Gesamtschichten × Nutzbar_i / GesamtNutzbar`).
- **KV-Verdichtung & schnelle GPU-Abstimmung:** `--kv-bits 4` + `--prefill-step-size 512` ermöglichen über 64k Zeichenblöcke, während `MLX_METAL_FAST_SYNCH=1` die Abstimmungszeit um Faktor **45×** (~180 µs → ~4 µs) senkt.

---

## 🚧 Entwicklungsstand & Mitmachen

> [!IMPORTANT]
> **SS-CCC ist bereits startfähig, befindet sich jedoch noch in der laufenden Entwicklung und Erprobung.**
> Die Programmoberfläche, die Hardware-Auslesung, die gewichtete Schichtenplanung sowie die Anbindung von Agenten und Laufzeiten funktionieren bereits; praxisnahe Langzeiterprobungen über verschiedene M1–M6-Gerätekombinationen, Thunderbolt-4/5-Brücken und RDMA/JACCL werden fortlaufend geprüft und verfeinert.

Wir laden Entwickler, Forschende und Apple-Silicon-Begeisterte herzlich dazu ein, **mitzuentwickeln und SS-CCC weiterzubringen**:
- **Auf eigener Hardware erproben:** Teste SS-CCC mit deinen M1–M6-Macs und teile Messwerte zu Durchsatz, Speicherverbrauch und Zuverlässigkeit.
- **Rückmeldungen & Vorschläge einbringen:** Eröffne auf GitHub einen Hinweis zu Fehlern, Besonderheiten oder neuen Ideen.
- **Änderungsvorschläge einreichen:** Verbesserungen an der SwiftUI-Oberfläche, der Python-/MLX-Aufteilung, den Thunderbolt-Skripten oder den Übersetzungen sind jederzeit willkommen!

---

## 📄 Lizenz

Veröffentlicht unter der [MIT-Lizenz](LICENSE.md).
