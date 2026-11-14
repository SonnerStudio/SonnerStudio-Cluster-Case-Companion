import Foundation

// Runtime assertions against the real Swift sources (ClusterModels.swift & Localization.swift)
func check(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

// 1. Open-ended Apple Silicon M1..M12+ inference checks
let m1Bw = AppleSiliconChipFamily.inferBandwidth(from: "Apple M1")
check(m1Bw == 68.0, "M1 base bandwidth should be 68 GB/s, got \(m1Bw)")

let m4Bw = AppleSiliconChipFamily.inferBandwidth(from: "Apple M4")
check(m4Bw == 120.0, "M4 base bandwidth should be 120 GB/s, got \(m4Bw)")

let m7Bw = AppleSiliconChipFamily.inferBandwidth(from: "Apple M7")
let m8MaxBw = AppleSiliconChipFamily.inferBandwidth(from: "Apple M8 Max")
let m9UltraBw = AppleSiliconChipFamily.inferBandwidth(from: "Apple M9 Ultra")
let m12MaxBw = AppleSiliconChipFamily.inferBandwidth(from: "Apple M12 Max")
check(m7Bw > 180.0, "M7 base bandwidth should exceed M6 (180 GB/s), got \(m7Bw)")
check(m8MaxBw > 580.0, "M8 Max bandwidth should exceed M6 Max (580 GB/s), got \(m8MaxBw)")
check(m9UltraBw > 800.0, "M9 Ultra bandwidth should exceed 800 GB/s, got \(m9UltraBw)")
check(m12MaxBw > m8MaxBw, "M12 Max bandwidth should scale beyond M8 Max")

// 2. Thunderbolt generation scaling (M1-M9+)
check(AppleSiliconChipFamily.inferThunderboltGen(from: "Apple M1") == 3, "M1 base -> TB3")
check(AppleSiliconChipFamily.inferThunderboltGen(from: "Apple M4") == 4, "M4 base -> TB4")
check(AppleSiliconChipFamily.inferThunderboltGen(from: "Apple M5") == 5, "M5 base -> TB5")
check(AppleSiliconChipFamily.inferThunderboltGen(from: "Apple M7 Pro") == 5, "M7 Pro -> TB5")
check(AppleSiliconChipFamily.inferThunderboltGen(from: "Apple M9 Max") == 5, "M9 Max -> TB5")

// 3. FP16 TFLOPS & Ridge Point
let m4FP16 = AppleSiliconChipFamily.inferFP16TFLOPS(from: "Apple M4")
let m7MaxFP16 = AppleSiliconChipFamily.inferFP16TFLOPS(from: "Apple M7 Max")
check(m4FP16 == 8.6, "M4 FP16 should be 8.6 TFLOPS")
check(m7MaxFP16 > 46.0, "M7 Max FP16 should exceed M6 Max (46.0 TFLOPS), got \(m7MaxFP16)")

// 4. Usable VRAM OOM Reserve Guard
check(AppleSiliconChipFamily.usableVramGB(for: 16.0) == 12.0, "16 GB Mac keeps 4 GB OS reserve")
check(AppleSiliconChipFamily.usableVramGB(for: 36.0) == 30.0, "36 GB Mac keeps 6 GB OS reserve")
check(AppleSiliconChipFamily.usableVramGB(for: 128.0) == 120.0, "128 GB Mac keeps 8 GB OS reserve")

// 5. Link Transfer Stats across TB3/4/5 and RDMA
let tb5Rdma = AppleSiliconChipFamily.linkTransferStats(genA: 5, genB: 5, mode: .rdmaExperimental)
check(tb5Rdma.badge == "TB5 RDMA" && tb5Rdma.nominalGbps >= 80.0, "TB5 RDMA link stats")
let tb3Mix = AppleSiliconChipFamily.linkTransferStats(genA: 3, genB: 5, mode: .autoHybrid)
check(tb3Mix.badge == "TB3/4/5", "Mixed TB3+TB5 link badge")

// 6. All 5 languages return non-key strings
for lang in AppLanguage.allCases {
    let sci = L10n.text("sci_title", lang)
    check(sci != "sci_title" && !sci.isEmpty, "Missing sci_title for \(lang)")
    let ms = L10n.text("ms_sub", lang)
    check(!ms.contains("36 GB + 16 GB"), "ms_sub for \(lang) must be neutral, got: \(ms)")
    let ov = L10n.tabSubtitle(.overview, lang)
    check(!ov.contains("52 GB") && !ov.contains("52 Go"), "overview subtitle for \(lang) must be neutral, got: \(ov)")
    for sciKey in ["sci_scope_label", "sci_tab_roofline", "sci_tab_wan", "sci_tab_memory", "sci_tab_energy", "sci_tab_trials", "sci_tab_history", "upd_check_btn", "upd_prompt_title"] {
        let val = L10n.text(sciKey, lang)
        check(val != sciKey && !val.isEmpty, "Missing \(sciKey) for \(lang)")
    }
}

// 7. Science WAN / Compression / Carbon / History / Update enums
check(ActivationCompressionMode.fp8Quantized.bytesPerElement < ActivationCompressionMode.fp16Raw.bytesPerElement, "FP8 compression reduces payload")
check(CarbonRegionProfile.norway.gco2PerKwh < CarbonRegionProfile.germany.gco2PerKwh, "Norway hydro CO2 < Germany grid")
check(ScienceLabTab.allCases.count == 6, "Science Lab has 6 dedicated tabs")
check(ScienceHistoryPosition.allCases.count == 6, "Science History has 6 position filters")
check(!AppReleaseMetadata.currentVersion.isEmpty && AppReleaseMetadata.currentBuild > 0, "Release metadata must be populated")

print("PASS: All Swift runtime checks (M1-M12+, TB3/4/5, VRAM guard, Science Lab WAN, 5-language localization) passed!")
