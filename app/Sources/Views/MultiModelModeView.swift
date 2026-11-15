import SwiftUI
import AppKit

struct MultiModelModeView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerAndScopeCard
                autoSetupCard
                vramAndThroughputCard
                modelSlotsCard
                executionAndResultsCard
                multiIdeHarnessConsumptionCard
            }
            .padding(24)
        }
        .onAppear {
            if vm.mmmSlots.isEmpty {
                if !vm.loadMultiModelConfiguration() {
                    vm.autoConfigureMultiModelSetup()
                }
            }
        }
    }

    // MARK: - 1. Header, Scope & Orchestration Strategy

    private var headerAndScopeCard: some View {
        SolarisCard(accent: SolarisTheme.amber) {
            HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.85)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Multi-Model-Mode (MMM)")
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.simulateMacStudio ? "SIMULATION" : "ECHTZEIT-ORCHESTRIERUNG")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald)
                            .cornerRadius(5)
                    }
                    Text("Führe mehrere Modelle innerhalb des lokalen Clusters, des Internet-Clusters oder eines gekoppelten Hybrid-Verbunds zu einer gemeinsamen Gesamtleistung zusammen.")
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button {
                    vm.syncMultiModelSlotsFromCluster()
                } label: {
                    Label("Aus Verbund synchronisieren", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
            }

            Divider().opacity(0.25)

            // Scope Selector (Lokal / Internet-Cluster / Hybrid)
            HStack(spacing: 12) {
                Text("Cluster-Bereich:")
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Picker("Cluster-Bereich", selection: $vm.mmmScope) {
                    ForEach(MultiModelScope.allCases) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .onChange(of: vm.mmmScope) { _, _ in
                    vm.syncMultiModelSlotsFromCluster()
                }
            }

            // Orchestration Strategy Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Orchestrierungs-Strategie:")
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Picker("Strategie", selection: $vm.mmmStrategy) {
                    ForEach(MultiModelStrategy.allCases) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                Text(vm.mmmStrategy.summary)
                    .font(Font.caption)
                    .foregroundColor(SolarisTheme.textSecondary)
            }
        }
    }

    // MARK: - 1b. Automatische Cluster-Einrichtung & Nachträgliche Konfiguration

    private var autoSetupCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Automatische MMM-Einrichtung (1-Klick-Assistent)")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Erkennt automatisch verfügbare Knoten, VRAM-Pools und geladene Modelle. Jede Einstellung lässt sich anschließend jederzeit im Slot-Editor anpassen, umsortieren oder duplizieren.")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button {
                    vm.autoConfigureMultiModelSetup()
                } label: {
                    Label("Automatisch einrichten", systemImage: "wand.and.stars")
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)
            }

            HStack(spacing: 10) {
                Text("Profil:")
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textSecondary)
                Picker("Auto-Profil", selection: $vm.mmmAutoProfile) {
                    ForEach(MultiModelAutoProfile.allCases) { profile in
                        Text(profile.rawValue).tag(profile)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Text(vm.mmmAutoProfile.summary)
                .font(Font.caption)
                .foregroundColor(SolarisTheme.textSecondary)

            HStack(spacing: 10) {
                Button {
                    vm.optimizeMultiModelSlotsForVram()
                } label: {
                    Label("VRAM-Fit optimieren", systemImage: "checkmark.shield")
                }
                .buttonStyle(.bordered)

                Button {
                    vm.saveMultiModelConfiguration()
                    vm.mmmStatusMessage = "MMM-Konfiguration dauerhaft gespeichert."
                } label: {
                    Label("Konfiguration speichern", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)

                Button {
                    let json = vm.exportMultiModelConfigurationJSON()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(json, forType: .string)
                    vm.mmmConfigCopiedBanner = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        vm.mmmConfigCopiedBanner = false
                    }
                } label: {
                    Label(vm.mmmConfigCopiedBanner ? "JSON kopiert!" : "Config-JSON kopieren", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            if !vm.mmmAutoSetupSummary.isEmpty {
                Text(vm.mmmAutoSetupSummary)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(SolarisTheme.emerald)
            }
        }
    }

    // MARK: - 2. VRAM Budget & Combined Throughput Overview

    private var vramAndThroughputCard: some View {
        SolarisCard(accent: vm.mmmFitsInClusterPool ? SolarisTheme.mint : SolarisTheme.coral) {
            HStack(spacing: 14) {
                mmmMetricTile(
                    title: "Aktive Modelle",
                    value: "\(vm.mmmActiveSlots.count) / \(vm.mmmSlots.count)",
                    sub: "\(vm.mmmAvailableTargets.count) Ziel-Knoten (\(vm.mmmScope.rawValue))",
                    accent: SolarisTheme.amberGlow
                )
                mmmMetricTile(
                    title: "VRAM-Bedarf vs. Pool",
                    value: String(format: "%.1f / %.1f GB", vm.mmmTotalRequiredVramGB, vm.mmmUsableVramPoolGB),
                    sub: vm.mmmFitsInClusterPool ? "Passt sicher in nutzbaren Pool" : "Pool überschritten — Slots reduzieren",
                    accent: vm.mmmFitsInClusterPool ? SolarisTheme.emerald : SolarisTheme.coral
                )
                mmmMetricTile(
                    title: "Kombinierte Leistung",
                    value: String(format: "%.1f tok/s", vm.mmmEstimatedCombinedTokPerSec),
                    sub: vm.mmmStrategy.rawValue,
                    accent: SolarisTheme.mint
                )
                mmmMetricTile(
                    title: "Letzte Ausführung",
                    value: vm.mmmLastResult.map { String(format: "%.2fx", $0.speedupFactor) } ?? "—",
                    sub: vm.mmmLastResult.map { $0.isLiveExecution ? "Live SSE" : "Simulation" } ?? "Noch nicht gestartet",
                    accent: SolarisTheme.amber
                )
            }

            // Memory Fill Bar
            let pool = max(1.0, vm.mmmUsableVramPoolGB)
            let ratio = min(1.0, vm.mmmTotalRequiredVramGB / pool)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Multi-Modell-Speicherauslastung (inkl. iogpu.wired_limit_mb Schutz)")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.0f%% belegt", (vm.mmmTotalRequiredVramGB / pool) * 100.0))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(vm.mmmFitsInClusterPool ? SolarisTheme.emerald : SolarisTheme.coral)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(SolarisTheme.cardElevated)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(vm.mmmFitsInClusterPool ? SolarisTheme.mint : SolarisTheme.coral)
                            .frame(width: max(8, geo.size.width * ratio))
                    }
                }
                .frame(height: 12)
            }
        }
    }

    // MARK: - 3. Multi-Model Slot Configuration

    private var modelSlotsCard: some View {
        SolarisCard {
            HStack {
                Text("Modell-Slots & Knoten-Zuweisung")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Text("Ziele: \(vm.mmmAvailableTargets.joined(separator: " · "))")
                    .font(Font.caption)
                    .foregroundColor(SolarisTheme.textSecondary)
                    .lineLimit(1)
            }

            VStack(spacing: 10) {
                ForEach($vm.mmmSlots) { $slot in
                    let isExpanded = vm.mmmExpandedSlotId == slot.id
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Toggle("", isOn: $slot.isEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(slot.displayName)
                                    .font(SolarisTheme.bodyBold)
                                    .foregroundColor(SolarisTheme.textPrimary)
                                Text(slot.modelId)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                            .frame(minWidth: 165, alignment: .leading)

                            Picker("Rolle", selection: $slot.role) {
                                ForEach(MultiModelRole.allCases) { r in
                                    Text(r.rawValue).tag(r)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 115)

                            Picker("Knoten", selection: $slot.assignedTarget) {
                                ForEach(vm.mmmAvailableTargets.isEmpty ? ["Lokal"] : vm.mmmAvailableTargets, id: \.self) { t in
                                    Text(t).tag(t)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 155)

                            Text(String(format: "%.1f GB", slot.estimatedRamGB))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(SolarisTheme.amberGlow)
                                .frame(width: 62, alignment: .trailing)

                            Text(slot.lastTokPerSec > 0 ? String(format: "%.1f tok/s", slot.lastTokPerSec) : "—")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(SolarisTheme.emerald)
                                .frame(width: 78, alignment: .trailing)

                            HStack(spacing: 4) {
                                Button {
                                    vm.moveMultiModelSlot(slot.id, direction: -1)
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .buttonStyle(.borderless)
                                .help("Nach oben verschieben")

                                Button {
                                    vm.moveMultiModelSlot(slot.id, direction: 1)
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .buttonStyle(.borderless)
                                .help("Nach unten verschieben")

                                Button {
                                    vm.duplicateMultiModelSlot(slot.id)
                                } label: {
                                    Image(systemName: "plus.square.on.square")
                                }
                                .buttonStyle(.borderless)
                                .help("Slot für weiteren Knoten duplizieren")

                                Button {
                                    vm.mmmExpandedSlotId = isExpanded ? nil : slot.id
                                } label: {
                                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "slider.horizontal.3")
                                        .foregroundColor(isExpanded ? SolarisTheme.amber : SolarisTheme.textSecondary)
                                }
                                .buttonStyle(.borderless)
                                .help("Slot-Details nachträglich anpassen")

                                Button(role: .destructive) {
                                    vm.removeMultiModelSlot(slot.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help("Slot entfernen")
                            }
                        }

                        if isExpanded {
                            Divider().opacity(0.2)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Anzeigename")
                                            .font(Font.caption)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                        TextField("Anzeigename", text: $slot.displayName)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Modell-ID")
                                            .font(Font.caption)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                        TextField("Modell-ID", text: $slot.modelId)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("VRAM-Limit")
                                            .font(Font.caption)
                                            .foregroundColor(SolarisTheme.textSecondary)
                                        Stepper(String(format: "%.0f GB", slot.estimatedRamGB), value: $slot.estimatedRamGB, in: 1...256, step: 2)
                                            .frame(width: 120)
                                    }
                                }
                                HStack(spacing: 10) {
                                    Text("Endpunkt-URL:")
                                        .font(Font.caption)
                                        .foregroundColor(SolarisTheme.textSecondary)
                                    TextField("http://127.0.0.1:8000/v1", text: $slot.endpointURL)
                                        .textFieldStyle(.roundedBorder)
                                    Button(":8000/v1") {
                                        slot.endpointURL = "http://127.0.0.1:8000/v1"
                                    }
                                    .buttonStyle(.bordered)
                                    Button(":11434/v1") {
                                        slot.endpointURL = "http://127.0.0.1:11434/v1"
                                    }
                                    .buttonStyle(.bordered)
                                    Button("Übernehmen & Speichern") {
                                        vm.saveMultiModelConfiguration()
                                        vm.mmmExpandedSlotId = nil
                                        vm.mmmStatusMessage = "Slot '\(slot.displayName)' aktualisiert und gespeichert."
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(SolarisTheme.emerald)
                                    .foregroundColor(.black)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(10)
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(10)
                    .solarisHighlightGlow(
                        accent: slot.isEnabled ? SolarisTheme.mint : SolarisTheme.amber,
                        isActive: isExpanded,
                        isHovered: vm.hoveredGlowId == "mmm_slot_\(slot.id.uuidString)",
                        cornerRadius: 10
                    )
                    .onHover { hovering in
                        let key = "mmm_slot_\(slot.id.uuidString)"
                        vm.hoveredGlowId = hovering ? key : (vm.hoveredGlowId == key ? nil : vm.hoveredGlowId)
                    }
                }
            }

            Divider().opacity(0.2)

            // Add custom model slot
            HStack(spacing: 10) {
                TextField("Modell-ID (z. B. qwen2.5-coder:7b)", text: $vm.mmmNewModelId)
                    .textFieldStyle(.roundedBorder)
                TextField("Anzeigename", text: $vm.mmmNewModelName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
                Picker("Rolle", selection: $vm.mmmNewModelRole) {
                    ForEach(MultiModelRole.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
                Stepper(String(format: "%.0f GB", vm.mmmNewModelRamGB), value: $vm.mmmNewModelRamGB, in: 1...256, step: 2)
                    .frame(width: 120)
                Button("Slot hinzufügen") {
                    vm.addMultiModelSlot(
                        modelId: vm.mmmNewModelId,
                        displayName: vm.mmmNewModelName,
                        role: vm.mmmNewModelRole,
                        estimatedRamGB: vm.mmmNewModelRamGB
                    )
                    vm.mmmNewModelId = ""
                    vm.mmmNewModelName = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.amber)
                .foregroundColor(.black)
                .disabled(vm.mmmNewModelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - 4. Prompt Execution & Combined Results

    private var executionAndResultsCard: some View {
        SolarisCard(accent: SolarisTheme.emerald) {
            HStack {
                Text("Multi-Modell-Ausführung & Leistungszusammenführung")
                    .font(SolarisTheme.cardTitle)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Button {
                    vm.executeMultiModelOrchestration()
                } label: {
                    Label(
                        vm.isRunningMultiModel ? "Orchestrierung läuft..." : "MMM-Lauf starten",
                        systemImage: vm.isRunningMultiModel ? "hourglass" : "play.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.emerald)
                .foregroundColor(.black)
                .disabled(vm.isRunningMultiModel || vm.mmmActiveSlots.isEmpty)
            }

            TextField("Gemeinsamer Prompt für das Multi-Modell-Ensemble...", text: $vm.mmmPromptInput)
                .textFieldStyle(.roundedBorder)

            if !vm.mmmStatusMessage.isEmpty {
                Text(vm.mmmStatusMessage)
                    .font(Font.caption)
                    .foregroundColor(vm.mmmLastResult == nil && !vm.simulateMacStudio ? SolarisTheme.amberGlow : SolarisTheme.emerald)
            }

            if let res = vm.mmmLastResult {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(res.isLiveExecution ? "LIVE SSE ERGEBNIS" : "SIMULATION")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(res.isLiveExecution ? SolarisTheme.emerald : SolarisTheme.amber)
                            .cornerRadius(4)
                        Text("\(res.strategy.rawValue) · \(res.scope.rawValue)")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        Text(String(format: "%.1f tok/s · TTFT %.1f ms · %.2fx", res.combinedTokPerSec, res.aggregateTtftMs, res.speedupFactor))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(SolarisTheme.mint)
                    }
                    Text(res.responsePreview)
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                .padding(10)
                .background(SolarisTheme.cardElevated)
                .cornerRadius(10)
            }
        }
    }

    // MARK: - 5. Multi-IDE & Agent Harness Cluster Consumption

    private var multiIdeHarnessConsumptionCard: some View {
        SolarisCard(accent: SolarisTheme.mint) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Multi-IDE & Agent-Harness Leistungsentnahme")
                        .font(SolarisTheme.cardTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Mehrere IDEs (Cursor, VS Code, Xcode) und Agent-Harnesses (OpenCode, Hermes, Antigravity) beziehen gleichzeitig über \(vm.openCodeBaseURL) Leistung aus dem zusammengeführten Verbund.")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button("Multi-IDE-Config kopieren") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(vm.exportMultiIdeMmmGatewayConfig(), forType: .string)
                    vm.mmmStatusMessage = "Multi-IDE / MMM Gateway-Konfiguration in die Zwischenablage kopiert."
                }
                .buttonStyle(.borderedProminent)
                .tint(SolarisTheme.mint)
                .foregroundColor(.black)
            }

            HStack(spacing: 16) {
                Stepper("Gleichzeitige IDEs / Harnesses: \(vm.mmmActiveClientCount)", value: $vm.mmmActiveClientCount, in: 1...8)
                    .font(SolarisTheme.bodyBold)
                    .foregroundColor(SolarisTheme.textPrimary)
                Spacer()
                Text(String(format: "≈ %.1f tok/s pro aktivem Client", vm.mmmPerClientTokPerSec))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(SolarisTheme.amberGlow)
            }
            .padding(10)
            .background(SolarisTheme.cardElevated)
            .cornerRadius(10)
        }
    }

    private func mmmMetricTile(title: String, value: String, sub: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Font.caption)
                .foregroundColor(SolarisTheme.textSecondary)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(accent)
            Text(sub)
                .font(Font.caption2)
                .foregroundColor(SolarisTheme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(SolarisTheme.cardElevated)
        .cornerRadius(10)
    }
}
