import Foundation

/// Live-Anbindung an den laufenden SS-CCC-MLX-Verbund.
///
/// Der Leitrechner (Rang 0) liefert unter `GET /ssccc/cluster` die echten
/// Hardware-Daten aller Ränge, die Schichten-Aufteilung und die aktive
/// Verbindung. Ist der Verbund erreichbar, ersetzen diese Knoten die
/// Simulations- und Platzhalter-Knoten in allen Ansichten.
///
/// Die Gateway-Adresse kommt aus `/Users/Shared/ssccc/ssccc_app.json`
/// (`{"gateway": "http://<Leitrechner>:8000"}`), sonst `http://127.0.0.1:8000`.
/// Echte Bereitschaftsdaten eines Verbund-Knotens, gemessen vom Leitrechner.
struct LiveNodeHealth: Hashable {
    let rank: Int
    let sshOK: Bool        // Leitrechner erreicht den Knoten per SSH ohne Passwort
    let ringOK: Bool       // Ring-Adresse(n) des Knotens erreichbar
    let modelOK: Bool      // Modellanteil liegt auf dem Knoten
    let mlxOK: Bool        // MLX-Laufzeit installiert
    let wiredOK: Bool      // iogpu.wired_limit_mb gesetzt
    let wiredPersistent: Bool
    let link: String

    var transportOK: Bool { ringOK && modelOK && mlxOK }
}

extension ClusterViewModel {
    nonisolated(unsafe) static var liveClusterActivity: NSObjectProtocol?

    /// Ersetzt bei laufendem Verbund die Platzhalter-Flags der Einrichtungsziele
    /// durch die echten Messwerte des Leitrechners.
    func applyLiveHealth(to targets: [NodeProvisioningTarget]) -> [NodeProvisioningTarget] {
        guard !liveNodeHealth.isEmpty else { return targets }
        return targets.map { t in
            guard t.id.hasPrefix("local-live-rank-"),
                  let r = Int(t.id.replacingOccurrences(of: "local-live-rank-", with: "")),
                  let h = liveNodeHealth.first(where: { $0.rank == r })
            else { return t }
            var n = NodeProvisioningTarget(
                id: t.id,
                hostname: t.hostname,
                address: t.address,
                transport: h.link.isEmpty ? t.transport : "\(h.link) · mlx ring",
                chipLabel: t.chipLabel,
                usableVramGB: t.usableVramGB,
                sshTrusted: h.sshOK,
                wiredLimitConfigured: h.wiredOK,
                rdmaOrWanReady: h.transportOK,
                isSelected: t.isSelected
            )
            n.isSelected = true
            return n
        }
    }

    nonisolated static var clusterGatewayBase: String {
        let path = "/Users/Shared/ssccc/ssccc_app.json"
        if let data = FileManager.default.contents(atPath: path),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let gw = json["gateway"] as? String, !gw.isEmpty {
            return gw.hasSuffix("/") ? String(gw.dropLast()) : gw
        }
        return "http://127.0.0.1:8000"
    }

    func startLiveClusterMonitor() {
        // Verhindert, dass macOS (App Nap) die Statusabfrage im Hintergrund
        // anhält – sonst veraltet die Verbundanzeige bei verdecktem Fenster.
        let activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
            reason: "SS-CCC Live-Verbundstatus"
        )
        Self.liveClusterActivity = activity
        Task { [weak self] in
            while let self {
                await self.refreshLiveCluster()
                try? await Task.sleep(nanoseconds: 15_000_000_000)
            }
        }
    }

    func refreshLiveCluster() async {
        guard let url = URL(string: "\(Self.clusterGatewayBase)/ssccc/cluster") else { return }
        var req = URLRequest(url: url)
        req.timeoutInterval = 4
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rawNodes = json["nodes"] as? [[String: Any]], !rawNodes.isEmpty
        else {
            if !liveClusterNodes.isEmpty {
                liveClusterNodes = []
                liveClusterLink = ""
            }
            return
        }

        let mapped: [ClusterNodeModel] = rawNodes.map { n in
            func s(_ k: String) -> String { (n[k] as? String) ?? "" }
            func i(_ k: String) -> Int { (n[k] as? Int) ?? Int((n[k] as? Double) ?? 0) }
            let chip = s("chip").isEmpty ? "Apple Silicon" : s("chip")
            let ramGB = Double(i("ram_bytes")) / 1_073_741_824.0
            let wired = i("wired_limit_mb")
            let usable = wired > 0 ? Double(wired) / 1024.0 : AppleSiliconChipFamily.usableVramGB(for: ramGB)
            let p = i("p_cores"), e = i("e_cores")
            let speed = Int(s("cpu_speed_limit")) ?? 100
            let online = (n["online"] as? Bool) ?? false
            let layers = i("layers")
            let name = s("name").replacingOccurrences(of: "\u{00a0}", with: " ")
            return ClusterNodeModel(
                id: "live-rank-\(i("rank"))",
                name: name.isEmpty ? "Rang \(i("rank"))" : name,
                role: "\(s("role")) · \(layers) Schichten" + (online ? "" : " · offline"),
                modelIdentifier: s("model"),
                chip: chip,
                cpuCores: p + e,
                cpuTopology: "\(p)P + \(e)E",
                gpuCores: i("gpu_cores"),
                neuralEngineCores: 16,
                osVersion: "macOS \(s("os"))",
                totalRamGB: ramGB.rounded(),
                usableVramGB: usable,
                wiredLimitMB: wired,
                bandwidthGBs: AppleSiliconChipFamily.inferBandwidth(from: chip),
                thunderboltGen: AppleSiliconChipFamily.inferThunderboltGen(from: chip),
                rdmaEnabled: false,
                tbIP: s("tb_ip"),
                lanIP: s("lan_ip").isEmpty ? s("wlan_ip") : s("lan_ip"),
                ssdTotalGB: i("ssd_total_kb") / 1_048_576,
                ssdFreeGB: i("ssd_free_kb") / 1_048_576,
                thermalLabel: speed >= 100 ? "Nominal" : "Gedrosselt (\(speed) %)",
                powerLabel: online ? "Live (Verbund)" : "offline",
                isSimulated: false
            )
        }

        let link = (json["link"] as? String) ?? ""
        let health: [LiveNodeHealth] = rawNodes.map { n in
            func b(_ k: String) -> Bool { (n[k] as? Bool) ?? false }
            return LiveNodeHealth(
                rank: (n["rank"] as? Int) ?? 0,
                sshOK: b("ssh_ok"), ringOK: b("ring_ok"), modelOK: b("model_ok"),
                mlxOK: b("mlx_ok"), wiredOK: b("wired_ok"),
                wiredPersistent: b("wired_persistent"), link: link
            )
        }

        liveClusterLink = link
        liveClusterModel = (json["model"] as? String) ?? ""
        liveClusterNodes = mapped
        liveNodeHealth = health
        if simulateMacStudio {
            simulateMacStudio = false
        }
        daemonConnected = true

        // Der Verbund wurde außerhalb der App eingerichtet (start_verbund.sh).
        // Sind alle Knoten nachweislich vollständig, gilt die Einrichtung als
        // abgeschlossen – statt nur nach einem Klick auf „Automatische Einrichtung“.
        let allHealthy = health.allSatisfy { $0.sshOK && $0.transportOK && $0.wiredOK }
        if allHealthy && !hasCompletedClusterSetup {
            hasCompletedClusterSetup = true
        }
        verifyClusterReadiness()
    }
}
