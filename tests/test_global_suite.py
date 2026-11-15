import os
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_SOURCES = ROOT / "app" / "Sources"


class GlobalProjectTests(unittest.TestCase):
    def test_01_swift_runtime_checks(self):
        """Compile and run real Swift assertions against ClusterModels.swift & Localization.swift."""
        cmd = [
            "swift",
            "-e",
            "",
        ]
        # Concatenate ClusterModels.swift, Localization.swift, and run_swift_checks.swift into /tmp
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        loc = (APP_SOURCES / "Models" / "Localization.swift").read_text(encoding="utf-8")
        checks = (ROOT / "tests" / "run_swift_checks.swift").read_text(encoding="utf-8")

        # Strip duplicate `import Foundation` in concatenated script
        combined = (
            "import Foundation\n"
            + models.replace("import Foundation", "")
            + "\n"
            + loc.replace("import Foundation", "")
            + "\n"
            + checks.replace("import Foundation", "")
        )
        tmp_swift = Path("/tmp/ssccc_runtime_test.swift")
        tmp_swift.write_text(combined, encoding="utf-8")
        env = os.environ.copy()
        env["CLANG_MODULE_CACHE_PATH"] = "/tmp/clang-module-cache"
        res = subprocess.run(
            ["swift", "-Xcc", "-fmodules-cache-path=/tmp/clang-module-cache", str(tmp_swift)],
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
        )
        self.assertEqual(res.returncode, 0, f"Swift runtime checks failed:\n{res.stdout}\n{res.stderr}")
        self.assertIn("PASS:", res.stdout)

    def test_02_full_app_swift_build(self):
        """Verify the full macOS SwiftUI application compiles cleanly."""
        env = os.environ.copy()
        env["CLANG_MODULE_CACHE_PATH"] = "/tmp/clang-module-cache"
        res = subprocess.run(
            ["swift", "build", "--scratch-path", "/tmp/ssccc-build", "--disable-sandbox"],
            cwd=str(ROOT / "app"),
            env=env,
            capture_output=True,
            text=True,
            timeout=120,
        )
        self.assertEqual(res.returncode, 0, f"swift build failed:\n{res.stdout}\n{res.stderr}")

    def test_03_open_ended_m_series_support(self):
        """Verify M1-M9+ and open-ended M-generation parsing exist in ClusterModels.swift."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        for gen in ["m7", "m8", "m9", "parseGenerationAndTier"]:
            self.assertIn(gen, models, f"Missing open-ended Apple Silicon support for {gen}")

    def test_04_neutrality_outside_sidebar_simulation(self):
        """Ensure no hardcoded 52 GB / 36 GB + 16 GB / 42 GB / Studio + Mini mock strings remain outside the sidebar simulation."""
        forbidden = [
            "52-GB-Verbund",
            "benötigt Studio + Mini",
            "überschreitet 42 GB effektiv",
            "sobald der Mac Studio M5 Max eintrifft",
            "once the Mac Studio M5 Max arrives",
            "à l'arrivée du Mac Studio M5 Max",
            "al llegar el Mac Studio M5 Max",
            "quando o Mac Studio M5 Max chegar",
        ]
        for swift_file in APP_SOURCES.rglob("*.swift"):
            if swift_file.name.startswith("._"):
                continue
            content = swift_file.read_text(encoding="utf-8")
            for needle in forbidden:
                self.assertNotIn(needle, content, f"Hardcoded use-case '{needle}' found in {swift_file}")

    def test_05_live_model_discovery_endpoints(self):
        """Verify real oMLX, Ollama, and llama.cpp discovery endpoints and local GGUF/HF scanners exist."""
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        for expected in [
            "127.0.0.1:8000/v1/models",
            "127.0.0.1:11434/api/tags",
            "127.0.0.1:8080/v1/models",
            "refreshLiveModels",
            "inferModelSpecs",
            "scanLocalDiskModels",
            "checkRuntimeReadiness",
            "probeRuntimeBinaries",
        ]:
            self.assertIn(expected, vm, f"Missing live model discovery component: {expected}")
        self.assertIn("@Published var modelPresets: [ModelPreset] = []", vm)

    def test_06_scientific_roofline_and_stats_present(self):
        """Verify scientific Roofline, GPipe, energetics, p50/p95/p99, and export methods exist."""
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        view = (APP_SOURCES / "Views" / "ScienceBenchmarksView.swift").read_text(encoding="utf-8")
        for symbol in [
            "pipelineBubbleFraction",
            "decodeArithmeticIntensity",
            "prefillArithmeticIntensity",
            "estimatedJoulesPerToken",
            "runScientificBenchmark",
            "exportScientificCSV",
            "exportScientificJSON",
            "exportBibTeX",
        ]:
            self.assertIn(symbol, vm, f"Missing scientific symbol in ViewModel: {symbol}")
        self.assertIn("RooflineCanvasView", view)

    def test_07_five_language_localization_completeness(self):
        """Verify key UI strings are localized across all 5 languages (de, en, fr, es, pt)."""
        loc = (APP_SOURCES / "Models" / "Localization.swift").read_text(encoding="utf-8")
        for key in ["sci_title", "sci_workload_title", "sci_bench_run", "sci_scope_label", "sci_tab_roofline", "sci_tab_wan", "sci_tab_memory", "sci_tab_energy", "sci_tab_trials", "ms_title", "ms_sub", "net_checklist", "pool_bar_title", "wan_title", "wan_sub", "wan_chat_title"]:
            for lang in [".de", ".en", ".fr", ".es", ".pt"]:
                pattern = rf'case\s*\(\s*"{key}"\s*,\s*{lang}\s*\)'
                self.assertRegex(loc, pattern, f"Missing localization for ({key}, {lang})")

    def test_08_internet_cluster_and_chat_present(self):
        """Verify Internet WAN Cluster, Mega-Cluster swarm builder, participant chat, and WebSocket relay exist."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        view = (APP_SOURCES / "Views" / "InternetClusterView.swift").read_text(encoding="utf-8")
        gateway = (ROOT / "core" / "api" / "gateway.py").read_text(encoding="utf-8")

        for item in ["case internetCluster", "enum WanOverlayTransport", "enum InternetClusterScale", "struct WanPeerNode", "struct ClusterChatMessage"]:
            self.assertIn(item, models)
        for fn in ["probeWanOverlayTools", "toggleWanConnection", "populateMegaClusterSwarm", "sendClusterChatMessage", "recomputeWanLayerAssignments"]:
            self.assertIn(fn, vm)
        self.assertIn("struct InternetClusterView", view)
        self.assertIn("/ws/wan/{room_id}", gateway)

    def test_09_science_lab_wan_and_multitab_present(self):
        """Verify 5-tab Science Lab supports Internet WAN, Scaling, DiLoCo, Memory/KV, Carbon/EDP, CI95, and LaTeX export."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        view = (APP_SOURCES / "Views" / "ScienceBenchmarksView.swift").read_text(encoding="utf-8")

        for item in ["enum ScienceScope", "enum ScienceLabTab", "enum ActivationCompressionMode", "enum CarbonRegionProfile", "struct ScientificNodeSnapshot"]:
            self.assertIn(item, models)
        for fn in ["activeScienceNodes", "criticalBatchSizeBStar", "trainingCommAnalysis", "scalingCurvePoints", "memoryBreakdownGB", "exportScientificLaTeX"]:
            self.assertIn(fn, vm)
        for ui in ["ScalingCurveCanvasView", "rooflineTabContent", "wanTopologyTabContent", "memoryKvTabContent", "energeticsTabContent", "trialsExportTabContent"]:
            self.assertIn(ui, view)

    def test_10_local_wan_cluster_coupling_present(self):
        """Verify Local TB/RDMA Cluster <-> Internet WAN Cluster hybrid coupling exists."""
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        view = (APP_SOURCES / "Views" / "InternetClusterView.swift").read_text(encoding="utf-8")
        for sym in ["isLocalClusterCoupledWithWan", "toggleLocalClusterWanCoupling", "syncLocalClusterIntoWan", "coupledLocalBridgeCount", "coupledRemoteWanCount"]:
            self.assertIn(sym, vm)
        self.assertIn("toggleLocalClusterWanCoupling()", view)

    def test_11_cluster_audio_party_present(self):
        """Verify Xbox/PlayStation-style Cluster Audio-Party (AVAudioEngine + /ws/wan-audio) exists next to chat."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        view = (APP_SOURCES / "Views" / "InternetClusterView.swift").read_text(encoding="utf-8")
        gateway = (ROOT / "core" / "api" / "gateway.py").read_text(encoding="utf-8")

        for item in ["enum AudioPartyCodec", "enum AudioPartyMicMode", "struct AudioPartyMember"]:
            self.assertIn(item, models)
        for sym in ["toggleAudioParty", "togglePartyMute", "togglePartyDeafen", "triggerPushToTalk", "sendPartyCallout", "AVAudioEngine"]:
            self.assertIn(sym, vm)
        self.assertIn("audioPartyCard", view)
        self.assertIn("/ws/wan-audio/{room_id}", gateway)

    def test_12_run_ssccc_script_includes_all_swift_sources(self):
        """Ensure scripts/run_ssccc.sh lists every .swift file in app/Sources."""
        script = (ROOT / "scripts" / "run_ssccc.sh").read_text(encoding="utf-8")
        for swift_file in (APP_SOURCES).rglob("*.swift"):
            if swift_file.name.startswith("._"):
                continue
            self.assertIn(swift_file.name, script, f"{swift_file.name} missing from scripts/run_ssccc.sh")

    def test_13_cluster_overview_three_scopes_and_localization(self):
        """Verify 3-tab Cluster Overview (local, internet, hybrid) and 8-language localization."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        overview = (APP_SOURCES / "Views" / "ClusterOverviewView.swift").read_text(encoding="utf-8")
        loc = (APP_SOURCES / "Models" / "Localization.swift").read_text(encoding="utf-8")

        self.assertIn("enum ClusterOverviewScope", models)
        for case_name in ["case local", "case internet", "case hybrid"]:
            self.assertIn(case_name, models)
        for sym in ["overviewScope", "wanRemotePeers", "wanLocalIslandPeers", "wanSubclustersByRegion", "hybridCombinedRamGB"]:
            self.assertIn(sym, vm)
        for view_sym in ["scopeSelectorCard", "localClusterContent", "internetClusterContent", "hybridClusterContent"]:
            self.assertIn(view_sym, overview)

        for lang in [".de", ".en", ".fr", ".es", ".pt", ".ru", ".ja", ".zh"]:
            self.assertIn(f'case ("ov_tab_local", {lang}):', loc)
            self.assertIn(f'case ("ov_tab_internet", {lang}):', loc)
            self.assertIn(f'case ("ov_tab_hybrid", {lang}):', loc)

    def test_14_industrial_hazard_stripes_across_views(self):
        """Verify yellow-black industrial hazard stripe components and their usage across views."""
        theme = (APP_SOURCES / "Views" / "Theme.swift").read_text(encoding="utf-8")
        self.assertIn("struct HazardStripesBar", theme)
        self.assertIn("struct IndustrialHazardBanner", theme)

        for rel in [
            "Views/ClusterOverviewView.swift",
            "Views/NetworkRdmaView.swift",
            "Views/ModelStudioView.swift",
            "Views/InternetClusterView.swift",
            "Views/ScienceBenchmarksView.swift",
            "SSCCCApp.swift",
        ]:
            src = (APP_SOURCES / rel).read_text(encoding="utf-8")
            self.assertTrue(
                "HazardStripesBar" in src or "IndustrialHazardBanner" in src,
                f"Expected industrial hazard stripes in {rel}",
            )

    def test_15_help_manual_parity_across_eight_languages(self):
        """Verify HelpDocsView.swift has all 12 chapters with identical IDs across all 8 languages."""
        import re
        src = (APP_SOURCES / "Views" / "HelpDocsView.swift").read_text(encoding="utf-8")
        expected_ids = [
            "universal-m",
            "overview-hazard",
            "memory-safety",
            "network-tb",
            "sharding-loading",
            "setup-hybrid",
            "audio-party",
            "science-history",
            "runtimes",
            "agents-api",
            "updater-ci",
            "launch-tests",
        ]
        blocks = re.split(r"case \.(de|en|fr|es|pt|ru|ja|zh):", src)
        self.assertEqual(len(blocks), 17, "Expected 8 language cases in HelpDocsView.swift")
        for i in range(1, len(blocks), 2):
            lang = blocks[i]
            body = blocks[i + 1]
            ids = re.findall(r'id:\s*"([^"]+)"', body)
            self.assertEqual(ids, expected_ids, f"Chapter IDs mismatch for language .{lang}")

    def test_16_github_updater_deadlock_and_sha_hygiene(self):
        """Verify updater avoids pipe deadlocks, separates stdout/stderr for SHA, and handles failed state."""
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        app = (APP_SOURCES / "SSCCCApp.swift").read_text(encoding="utf-8")

        for sym in [
            "stdoutPipe",
            "stderrPipe",
            "availableData",
            "GIT_TERMINAL_PROMPT",
            "FileHandle.nullDevice",
            "sanitizeGitNoise",
            "res.stdout",
            "if pullOut.exitCode != 0",
            "isRemoteCommitAheadOfLocal",
            "merge-base",
            "processIdentifier",
            "exit(0)",
        ]:
            self.assertIn(sym, vm, f"Expected updater safety symbol {sym} in ClusterViewModel.swift")

        run_script = (APP_SOURCES.parent.parent / "scripts" / "run_ssccc.sh").read_text(encoding="utf-8")
        self.assertIn("pkill -f", run_script)
        self.assertIn("case .failed(", app, "UpdatePromptSheet must render .failed error state")
        self.assertIn("upd_close_btn", app)
        self.assertIn("upd_uptodate_subtitle", app)

        loc = (APP_SOURCES / "Models" / "Localization.swift").read_text(encoding="utf-8")
        for key in ["upd_uptodate_subtitle", "upd_github_status_label", "upd_recent_changes_title", "upd_recheck_btn", "upd_close_btn"]:
            for lang in [".de", ".en", ".fr", ".es", ".pt", ".ru", ".ja", ".zh"]:
                self.assertIn(f'case ("{key}", {lang}):', loc)

    def test_17_science_real_data_and_realistic_simulation(self):
        """Verify Science & Roofline uses real SSE + ping in real mode and realistic labeled simulation."""
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        sci = (APP_SOURCES / "Views" / "ScienceBenchmarksView.swift").read_text(encoding="utf-8")

        for sym in [
            "runLiveChatCompletionTrial",
            "measureRealNetworkRttMs",
            '"stream": true',
            "firstTokenNs",
            "completion_tokens",
            "Echtbetrieb: Kein aktiver Inferenz-Endpunkt",
            "Simulation (Realistic Apple Silicon)",
            "isLiveEndpoint: !isSimulatedMode",
        ]:
            self.assertIn(sym, vm, f"Missing real-data/simulation symbol {sym} in ClusterViewModel.swift")

        # Ensure old mock modulo wave and hardcoded 18.0 ms Tailscale RTT are gone
        self.assertNotIn("(idx * 19) % 11", vm)
        self.assertNotIn("rttMs: 18.0", vm)

        for badge in [
            "SIMULATION · Realistische Apple-Silicon-Referenzwerte",
            "ECHTZEIT-DATEN · Gemessene System- & Endpunkt-Telemetrie",
            "LIVE SSE + PING",
        ]:
            self.assertIn(badge, sci, f"Missing mode badge {badge} in ScienceBenchmarksView.swift")

    def test_18_wan_bandwidth_and_throughput_monitor(self):
        """Verify Internet Cluster bandwidth & throughput monitor uses real netstat/ping/networkQuality and renders impact."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        wan_view = (APP_SOURCES / "Views" / "InternetClusterView.swift").read_text(encoding="utf-8")

        self.assertIn("struct WanBandwidthSample", models)
        for sym in [
            "probeWanBandwidthAndThroughput",
            "wanMeasuredDownloadMbps",
            "wanMeasuredUploadMbps",
            "wanMeasuredPingMs",
            "wanMeasuredJitterMs",
            "wanMeasuredPacketLossPct",
            "wanThroughputHistory",
            "wanBottleneckUplinkMbps",
            "wanEffectivePayloadMBs",
            "wanActivationSyncOverheadMs",
            "wanPipelineEfficiencyPct",
            "/usr/bin/networkQuality",
            "/usr/sbin/netstat",
        ]:
            self.assertIn(sym, vm, f"Missing WAN bandwidth symbol {sym} in ClusterViewModel.swift")

        for ui_sym in [
            "wanBandwidthMonitorCard",
            "Internetbandbreite & WAN-Datendurchsatz",
            "Leistungsauswirkung auf den Internet-Cluster",
            "Speedtest (networkQuality)",
        ]:
            self.assertIn(ui_sym, wan_view, f"Missing WAN monitor UI symbol {ui_sym} in InternetClusterView.swift")

    def test_19_multi_model_mode_and_docs(self):
        """Verify 10th sidebar menu item Multi-Model-Mode (MMM), localization, view, implementation plan & roadmap."""
        models = (APP_SOURCES / "Models" / "ClusterModels.swift").read_text(encoding="utf-8")
        loc = (APP_SOURCES / "Models" / "Localization.swift").read_text(encoding="utf-8")
        app = (APP_SOURCES / "SSCCCApp.swift").read_text(encoding="utf-8")
        vm = (APP_SOURCES / "ViewModels" / "ClusterViewModel.swift").read_text(encoding="utf-8")
        mmm_view = (APP_SOURCES / "Views" / "MultiModelModeView.swift").read_text(encoding="utf-8")
        impl_plan = (APP_SOURCES.parent.parent / "docs" / "IMPLEMENTATION_PLAN.md").read_text(encoding="utf-8")
        roadmap = (APP_SOURCES.parent.parent / "docs" / "ROADMAP.md").read_text(encoding="utf-8")

        self.assertIn("case multiModelMode", models)
        for sym in ["enum MultiModelScope", "enum MultiModelStrategy", "enum MultiModelAutoProfile", "struct MultiModelSlot", "struct MultiModelRunResult"]:
            self.assertIn(sym, models)

        for lang in [".de", ".en", ".fr", ".es", ".pt", ".ru", ".ja", ".zh"]:
            self.assertIn(f"case (.multiModelMode, {lang}):", loc)

        self.assertIn("case .multiModelMode:", app)
        self.assertIn("MultiModelModeView(vm: vm)", app)
        for vm_sym in [
            "mmmScope",
            "mmmStrategy",
            "mmmSlots",
            "syncMultiModelSlotsFromCluster",
            "executeMultiModelOrchestration",
            "mmmFitsInClusterPool",
            "mmmPerClientTokPerSec",
            "exportMultiIdeMmmGatewayConfig",
            "recordScienceHistoryFromMMM",
            "mmmMeanObservedTokPerSec",
            "mmmMeanSpeedupFactor",
            "autoConfigureMultiModelSetup",
            "moveMultiModelSlot",
            "duplicateMultiModelSlot",
            "optimizeMultiModelSlotsForVram",
            "saveMultiModelConfiguration",
            "exportMultiModelConfigurationJSON",
        ]:
            self.assertIn(vm_sym, vm)

        sci_view = (APP_SOURCES / "Views" / "ScienceBenchmarksView.swift").read_text(encoding="utf-8")
        self.assertIn("mmmScienceEvaluationCard", sci_view)
        self.assertIn("Multi-Model-Mode (MMM)", mmm_view)
        self.assertIn("autoSetupCard", mmm_view)
        self.assertIn("multiIdeHarnessConsumptionCard", mmm_view)
        self.assertIn("Multi-Model-Mode (MMM)", impl_plan)
        self.assertIn("Multi-Model-Mode (MMM)", roadmap)


if __name__ == "__main__":
    unittest.main(verbosity=2)
