import AppKit
import Foundation

// MARK: - Datenmodelle der Gateway-Schnittstellen

struct GatewayMetrics {
    var lastTokS: Double?
    var avgTokS: Double?
    var avgTTFT: Double?
    var requests: Int
    var rejected: Int
    var images: Int
    var crashRestarts: Int
    var queueWaiting: Int
    var activeChats: Int
    var memoryAvailableGB: Double?
    var memoryTotalGB: Double?
    var swapUsedGB: Double?
    var llmReady: Bool
    var imageBusy: Bool
    var model: String
    var recentTokS: [Double]
}

struct GatewayModelEntry: Identifiable, Hashable {
    var id: String { repo }
    let repo: String
    let label: String
    let note: String
    let sizeGB: Double
    let installed: Bool
    let active: Bool
    let fits: Bool
    let needGB: Double
    let limitGB: Double
}

struct GatewayDownloadState {
    let repo: String
    let state: String       // idle | download | switch | done | error
    let percent: Double?
    let error: String?
}

struct GeneratedImage: Identifiable, Hashable {
    let id = UUID()
    let fileURL: URL
    let prompt: String
    let seconds: Double
}

// MARK: - Gateway-Aufrufe

extension ClusterViewModel {
    /// API-Schlüssel aus /Users/Shared/ssccc/ssccc_app.json (leer = Gateway ohne Schlüssel).
    nonisolated static var clusterGatewayKey: String {
        guard let data = FileManager.default.contents(atPath: "/Users/Shared/ssccc/ssccc_app.json"),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return "" }
        return (json["api_key"] as? String) ?? ""
    }

    /// Fügt den API-Schlüssel (falls gesetzt) an eine Gateway-Anfrage an.
    nonisolated static func authorize(_ req: inout URLRequest) {
        let key = clusterGatewayKey
        if !key.isEmpty { req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }
    }

    func gatewayRequest(_ path: String, method: String = "GET", json: [String: Any]? = nil,
                        timeout: TimeInterval = 10) -> URLRequest? {
        guard let url = URL(string: "\(Self.clusterGatewayBase)\(path)") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeout
        Self.authorize(&req)
        if let json {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: json)
        }
        return req
    }

    private func fetchJSON(_ req: URLRequest) async -> [String: Any]? {
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode ?? 0 < 300 else { return nil }
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: Telemetrie

    func refreshGatewayMetrics() async {
        guard let req = gatewayRequest("/ssccc/metrics"), let j = await fetchJSON(req) else {
            gwMetrics = nil
            return
        }
        let c = j["counters"] as? [String: Any] ?? [:]
        let q = j["queue"] as? [String: Any] ?? [:]
        let m = j["memory"] as? [String: Any] ?? [:]
        let s = j["stats"] as? [String: Any] ?? [:]
        let recent = (j["recent"] as? [[String: Any]] ?? []).compactMap { $0["tok_s"] as? Double }
        gwMetrics = GatewayMetrics(
            lastTokS: j["last_tok_s"] as? Double, avgTokS: j["avg_tok_s"] as? Double, avgTTFT: j["avg_ttft_s"] as? Double,
            requests: c["requests"] as? Int ?? 0, rejected: c["rejected"] as? Int ?? 0, images: c["images"] as? Int ?? 0,
            crashRestarts: s["llm_crash_restarts"] as? Int ?? 0, queueWaiting: q["waiting"] as? Int ?? 0,
            activeChats: q["active_chats"] as? Int ?? 0, memoryAvailableGB: m["available_gb"] as? Double,
            memoryTotalGB: m["total_gb"] as? Double, swapUsedGB: m["swap_used_gb"] as? Double,
            llmReady: j["llm_ready"] as? Bool ?? false, imageBusy: j["image_busy"] as? Bool ?? false,
            model: j["model"] as? String ?? "", recentTokS: recent)
    }

    // MARK: Betriebsart

    func refreshGatewayMode() async {
        guard let req = gatewayRequest("/ssccc/cluster"), let j = await fetchJSON(req) else { return }
        if let mode = j["mode"] as? String {
            gwMode = mode
        } else if let backend = j["backend"] as? String, backend.contains("ring") {
            gwMode = "verbund"
        }
    }

    func switchGatewayMode(_ mode: String) {
        guard let req = gatewayRequest("/ssccc/mode", method: "POST", json: ["mode": mode], timeout: 15) else { return }
        modeSwitching = true
        Task {
            _ = await fetchJSON(req)
            // Dienst startet neu – warten, bis er wieder antwortet
            for _ in 0..<90 {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await refreshGatewayMode()
                if gwMode == mode, let h = gatewayRequest("/health"), await fetchJSON(h) != nil { break }
            }
            modeSwitching = false
            await refreshLiveCluster()
        }
    }

    // MARK: Modelle

    func refreshGatewayModels() async {
        guard let req = gatewayRequest("/ssccc/models", timeout: 30), let j = await fetchJSON(req) else { return }
        gwModels = (j["models"] as? [[String: Any]] ?? []).map { m in
            GatewayModelEntry(repo: m["repo"] as? String ?? "", label: m["label"] as? String ?? "",
                              note: m["note"] as? String ?? "", sizeGB: m["size_gb"] as? Double ?? 0,
                              installed: m["installed"] as? Bool ?? false, active: m["active"] as? Bool ?? false,
                              fits: m["fits"] as? Bool ?? false, needGB: m["need_gb"] as? Double ?? 0,
                              limitGB: m["limit_gb"] as? Double ?? 0)
        }
        if let d = j["download"] as? [String: Any] { gwDownload = Self.parseDownload(d) }
    }

    private static func parseDownload(_ d: [String: Any]) -> GatewayDownloadState {
        var pct = d["percent"] as? Double
        if pct == nil, let done = d["done_bytes"] as? Double, let total = d["total_bytes"] as? Double, total > 0 {
            pct = 100 * done / total
        }
        return GatewayDownloadState(repo: d["repo"] as? String ?? "", state: d["state"] as? String ?? "idle",
                                    percent: pct, error: d["error"] as? String)
    }

    func selectGatewayModel(_ repo: String) {
        guard let req = gatewayRequest("/ssccc/models/select", method: "POST", json: ["repo": repo], timeout: 60) else { return }
        Task {
            _ = await fetchJSON(req)
            for _ in 0..<2400 {          // bis zu 2 h (Download großer Modelle)
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard let p = gatewayRequest("/ssccc/models/progress"), let j = await fetchJSON(p) else { continue }
                gwDownload = Self.parseDownload(j)
                if let s = gwDownload?.state, s == "done" || s == "error" || s == "idle" { break }
            }
            await refreshGatewayModels()
        }
    }

    // MARK: Bilder

    func generateImage(prompt: String, fast: Bool, aspect: String, now: Bool) {
        let refs = imageRefs
        imageBusy = true
        imageStatus = GS.t("img_running", language)
        let started = Date()
        Task {
            defer { imageBusy = false }
            let req: URLRequest?
            if refs.isEmpty {
                var body: [String: Any] = ["prompt": prompt, "size": aspect, "response_format": "url"]
                if fast { body["quality"] = "low" }
                if now { body["priority"] = "now" }
                req = gatewayRequest("/v1/images/generations", method: "POST", json: body, timeout: 1200)
            } else {
                var images: [String] = []
                for u in refs { if let d = try? Data(contentsOf: u) { images.append(d.base64EncodedString()) } }
                var body: [String: Any] = ["prompt": prompt, "images": images, "response_format": "url"]
                if now { body["priority"] = "now" }
                req = gatewayRequest("/v1/images/edits", method: "POST", json: body, timeout: 1200)
            }
            guard let req, let j = await fetchJSON(req),
                  let first = (j["data"] as? [[String: Any]])?.first else {
                imageStatus = GS.t("img_no_gateway", language)
                return
            }
            // Bild über das Gateway laden (funktioniert auch auf dem Worker-Mac)
            let path = (first["url_path"] as? String) ?? (first["url"] as? String) ?? ""
            let local = first["ssccc_file"] as? String ?? ""
            var fileURL = URL(fileURLWithPath: local)
            if !FileManager.default.fileExists(atPath: local), let r = gatewayRequest(path, timeout: 60),
               let (data, _) = try? await URLSession.shared.data(for: r) {
                let dir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("SS-CCC", isDirectory: true)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                fileURL = dir.appendingPathComponent(URL(fileURLWithPath: path).lastPathComponent)
                try? data.write(to: fileURL)
            }
            let secs = Date().timeIntervalSince(started)
            imageResults.insert(GeneratedImage(fileURL: fileURL, prompt: prompt, seconds: secs), at: 0)
            let wait = j["queue_wait_s"] as? Double ?? 0
            imageStatus = String(format: "✓ %.0f s", secs) + (wait > 1 ? String(format: " (%@ %.0f s)", GS.t("tel_queue", language), wait) : "")
        }
    }

    func addImageReferences() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = true
        if panel.runModal() == .OK {
            imageRefs = Array((imageRefs + panel.urls).prefix(3))
        }
    }
}
