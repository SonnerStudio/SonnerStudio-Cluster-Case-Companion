# Pressemitteilung: SonnerStudio Cluster-Case-Companion (SS-CCC) wächst zum weltweiten Apple-Silicon-Verbund mit 5-Reiter-Forschungslabor

**14. November 2026 — SonnerStudio** gibt einen umfassenden Entwicklungssprung für den **SonnerStudio Cluster-Case-Companion (SS-CCC)** bekannt. Die quelloffene macOS-Anwendung in nativem SwiftUI verbindet ab sofort nicht mehr nur örtliche Apple-Silicon-Macs über Thunderbolt 3, 4 und 5, sondern erschließt mit dem neuen **Internet-WAN-Verbund samt Echtzeit-Teilnehmergespräch** sowie einem **fünfteiligen wissenschaftlichen Forschungslabor** weltweite verteilte KI-Rechnerverbünde auf Mac-Basis.

![SonnerStudio Cluster-Case-Companion Ökosystem](images/ssccc_ecosystem_banner.jpg)

---

### Die wichtigsten Entwicklungsschritte im Überblick

1. **Beliebige Apple-Silicon-Macs von M1 bis M9+ im universellen Verbund**
   SS-CCC löst starre Gerätepaare vollständig ab und unterstützt sämtliche **Mac mini, MacBook Air, MacBook Pro, iMac, Mac Studio und Mac Pro** über die Generationen **M1 bis M6** sowie nach oben offen künftige **M7-, M8- und M9+-Rechner**. Der Rechner mit der höchsten Speicherbandbreite übernimmt selbsttätig **Rang 0 (Leitrechner)**; die macOS-Schutzgrenze `iogpu.wired_limit_mb` verhindert Speicherüberläufe zuverlässig.

2. **Weltweiter Internet-WAN-Verbund & Teilnehmer-Gespräch (`/ws/wan/{room_id}`)**
   Über das neue Seitenmenü **Weltweiter Verbund & Gespräch** lassen sich Apple-Silicon-Macs über verschlüsselte Netzbrücken (**Tailscale / WireGuard**, dezentrale **libp2p/DERP-Weiterleitung** oder manuelle Endpunkte) über das Internet zu kleinen Teams, Forschungs-Schwärmen oder **großen Verbünden mit 32 bis 256+ Macs** zusammenschalten. Ein integriertes **Echtzeit-Gespräch über WebSocket** erlaubt den direkten Austausch von Raum-Kennungen, Hardware-Status und Schichten-Anteilen zwischen allen Teilnehmern.

   ![Weltweiter Internet-WAN-Verbund und Teilnehmergespräch](images/ssccc_internet_wan_mesh.jpg)

3. **Wissenschaftliches 5-Reiter-Forschungslabor für Lokal & Internet-WAN**
   Für IT-Systemforscher und Leistungsanalysten wurde der Bereich **Forschung & Grenzkurve** zu einer fünfteiligen Arbeitsumgebung mit umschaltbarem Untersuchungs-Bereich (**Lokal TB/RDMA**, **Internet-WAN** und **Direktvergleich**) ausgebaut:
   - **Grenzkurve & Engpass:** Log-Log-Leistungsgrenzkurve $P(I) = \min(\beta \cdot I, \pi_{\text{eff}})$ samt effektiver WAN-Decke, automatischer Engpass-Erkennung und kritischer Batch-Größe $B^*$.
   - **WAN-Netz & Skalierung:** Gestapelte Schritt-Zeitaufteilung, Aktivierungs-Kompression nach *Petals / SWARM* (`FP16`, `FP8/INT8`, `INT4`, `Top-K`), Nachzügler- und Schwankungs-Simulation, Skalierungskurven von $N = 1$ bis $128$ Macs sowie **DiLoCo vs. naives DDP** für verteiltes Training über das Internet.
   - **Speicher & KV-Analyse:** Exakte Transformer-Speichergleichung inklusive maximal möglicher Kontextlänge $S_{\max}$ bei `FP16`, `8-Bit` und `4-Bit` KV-Speicher.
   - **Energie, CO₂ & Kosten:** *TokenPowerBench*-Auswertung (`J/Token`, Energy-Delay Product `EDP`), wählbare Strommix-Regionen (`gCO₂eq/kWh`), Stromkosten je 1 Million Token sowie Vergleich mit Rechenzentrums-Cloud-Diensten.
   - **Messreihen & Ausgabe:** Reproduzierbare Messläufe (`T = 0,0`, $N \in \{5, 10, 20\}$) mit `p50/p95/p99`, **95-%-Konfidenzintervall (`CI₉₅`)**, `CV%`, **Goodput (`SLO-Treffer %`)** sowie direkter Ausgabe als **CSV**, **JSON-Manifest**, **LaTeX-Tabelle (`booktabs`)** und **8-Quellen-BibTeX**.

   ![Wissenschaftliche Grenzkurven- und Energieanalyse](images/ssccc_science_roofline_hero.jpg)

4. **Echte Modellerkennung, vollständige Sensor-Auslesung & 5-Sprachen-Qualitätssicherung**
   Die Modell-Werkstatt liest ausschließlich reale Modelle aus **oMLX**, **Ollama**, **llama.cpp**, örtlichen `.gguf`-Dateien sowie `~/.cache/huggingface/hub` ein und prüft die Dienstbereitschaft unmittelbar am System. Gleichzeitig erfasst SS-CCC neben CPU-, GPU- und Neural-Engine-Kernen auch SSD-Kapazität, Thermik und Leistungsaufnahme. Die globale Prüfsammlung (`tests/`) sichert alle Funktionen inklusive vollständiger SwiftUI-Kompilierung und fünfsprachiger Oberfläche (**Deutsch, Englisch, Französisch, Spanisch, Portugiesisch**) ab.

---

### Verfügbarkeit & Quellcode-Repository

Der vollständige Quelltext, die mehrsprachigen Handbücher, das Forschungslabor sowie die globale Prüfsammlung stehen ab sofort öffentlich auf GitHub zur Verfügung:

- **GitHub-Repository:** https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion
- **Schnellstart auf Apple Silicon (macOS 14.0+):**
  ```bash
  git clone https://github.com/SonnerStudio/SonnerStudio-Cluster-Case-Companion.git
  cd SonnerStudio-Cluster-Case-Companion
  chmod +x scripts/run_ssccc.sh && ./scripts/run_ssccc.sh
  ```

*(Hinweis: Das Repository liefert den Swift-Quelltext aus; `./scripts/run_ssccc.sh` übersetzt die native macOS-Anwendung lokal auf dem eigenen Mac.)*
