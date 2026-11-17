import Foundation

/// Anbindung der App an die echte Ersteinrichtung `core/cluster/ssccc_setup.py`.
///
/// „Verbund automatisch einrichten“ startet `ssccc_setup.py apply --json`,
/// „Bereitschaft prüfen“ startet `ssccc_setup.py check --json`. Jede Ausgabezeile ist
/// ein JSON-Objekt (Prüfpunkt, Schritt, Fehler, Zusammenfassung) und wird live in die
/// Bereitschaftsliste und die Statuszeile übernommen. Was nur der Mensch tun kann
/// (Passwort, Admin-Rechte, macOS-Freigaben, Kabel), erscheint mit Anleitung.
extension ClusterViewModel {
    static let setupCompletedDefaultsKey = "ssccc_setup_completed"

    /// Pfad zum Einrichtungsskript: im Projekt (App wird aus dem Projektordner
    /// gestartet), über SSCCC_REPO oder im gemeinsamen Ordner.
    nonisolated static var setupToolPath: String? {
        let fm = FileManager.default
        var candidates = ["\(fm.currentDirectoryPath)/core/cluster/ssccc_setup.py"]
        if let repo = ProcessInfo.processInfo.environment["SSCCC_REPO"] {
            candidates.insert("\(repo)/core/cluster/ssccc_setup.py", at: 0)
        }
        candidates.append("/Users/Shared/ssccc/ssccc_setup.py")
        return candidates.first { fm.fileExists(atPath: $0) }
    }

    /// Beide Prüfungen: schnelle Live-Prüfung sofort, ausführliche Prüfung im Hintergrund.
    func runFullReadinessCheck() {
        verifyClusterReadiness()
        if Self.setupToolPath != nil, clusterSetupVariant != .internet {
            startSetupTool(apply: false)
        }
    }

    func startSetupTool(apply: Bool) {
        guard let script = Self.setupToolPath, !isRunningSetupTool else { return }
        isRunningSetupTool = true
        if apply { isRunningClusterSetup = true }
        setupToolChecks = []
        setupStatusMessage = apply ? "▶ Automatische Einrichtung läuft …" : "▶ Ausführliche Prüfung läuft …"

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        proc.arguments = [script, apply ? "apply" : "check", "--json"]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice

        let buffer = SetupLineBuffer()
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            for line in buffer.append(chunk) {
                guard let obj = try? JSONSerialization.jsonObject(with: line) as? [String: Any] else { continue }
                let event = SetupEvent(obj)
                Task { @MainActor in self?.handleSetupToolEvent(event.values, apply: apply) }
            }
        }
        proc.terminationHandler = { [weak self] _ in
            pipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                guard let self else { return }
                self.isRunningClusterSetup = false
                self.isRunningSetupTool = false
                self.verifyClusterReadiness()
            }
        }
        do {
            try proc.run()
        } catch {
            isRunningClusterSetup = false
            isRunningSetupTool = false
            setupStatusMessage = "Einrichtungswerkzeug konnte nicht gestartet werden: \(error.localizedDescription)"
        }
    }

    private func handleSetupToolEvent(_ obj: [String: Any], apply: Bool) {
        func s(_ k: String) -> String { (obj[k] as? String) ?? "" }
        switch s("type") {
        case "check":
            // Bei apply erst die Abschlussprüfung übernehmen (die erste Runde ist die Bestandsaufnahme)
            let status: ClusterReadinessCheckStatus = s("status") == "pass" ? .pass : (s("status") == "warn" ? .warn : .fail)
            var remediation = s("remediation")
            if status != .pass {
                remediation = s("fix") == "auto" ? GS.t("fix_auto", language)
                    : (s("fix") == "user" ? "\(GS.t("fix_user", language)) \(remediation)" : remediation)
            }
            let item = ClusterReadinessCheckItem(
                id: "tool-\(s("id"))-\(s("role"))",
                title: "\(s("mac")): \(GS.checkTitle(s("id"), fallback: s("title"), language))",
                detail: s("detail"),
                status: status,
                remediation: remediation
            )
            setupToolChecks.removeAll { $0.id == item.id }
            setupToolChecks.append(item)
        case "step":
            setupStatusMessage = "▶ \(GS.stepTitle(s("title"), language))" + (s("detail").isEmpty ? "" : ": \(s("detail"))")
            if s("title") == "Abschlussprüfung" { setupToolChecks = [] }
        case "error":
            setupStatusMessage = "⚠︎ \(s("mac")): \(s("detail"))"
        case "summary":
            let p = obj["pass"] as? Int ?? 0, w = obj["warn"] as? Int ?? 0, f = obj["fail"] as? Int ?? 0
            let state = s("state")
            if state == "ready" || (apply && f == 0) {
                hasCompletedClusterSetup = true
            }
            setupStatusMessage = "Ergebnis: \(state == "ready" ? "Bereit" : (state == "incomplete" ? "Unvollständig" : "Nicht bereit")) — \(p) ok, \(w) Hinweise, \(f) Fehler"
        default:
            break
        }
    }
}

/// Zeilenpuffer für die JSON-Ausgabe (wird nur vom Lese-Handler der Pipe genutzt).
final class SetupLineBuffer: @unchecked Sendable {
    private var data = Data()
    private let lock = NSLock()

    func append(_ chunk: Data) -> [Data] {
        lock.lock(); defer { lock.unlock() }
        data.append(chunk)
        var lines: [Data] = []
        while let nl = data.firstIndex(of: 0x0A) {
            lines.append(data.subdata(in: data.startIndex..<nl))
            data.removeSubrange(data.startIndex...nl)
        }
        return lines
    }
}

/// JSON-Objekt einer Ausgabezeile, sicher an den MainActor übergeben.
struct SetupEvent: @unchecked Sendable {
    let values: [String: Any]
    init(_ values: [String: Any]) { self.values = values }
}
