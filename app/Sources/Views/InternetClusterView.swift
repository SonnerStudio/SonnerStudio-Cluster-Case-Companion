import SwiftUI
import AppKit

struct InternetClusterView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Header & Room / Overlay Connection Controls
                SolarisCard(accent: vm.wanConnected ? SolarisTheme.emerald : SolarisTheme.amber) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("wan_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("wan_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.toggleWanConnection()
                        } label: {
                            Label(
                                vm.wanConnected ? "Verbund trennen" : "Internet-Verbund verbinden",
                                systemImage: vm.wanConnected ? "wifi.slash" : "globe.americas.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(vm.wanConnected ? SolarisTheme.coral : SolarisTheme.amber)
                        .foregroundColor(.black)
                    }

                    HazardStripesBar(height: 5, stripeWidth: 10, cornerRadius: 3, opacity: 0.88)

                    // Room Code, Relay URL & Scale Mode
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Raum-Kennung / Einladungs-Code")
                                .font(.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            HStack {
                                TextField("SSCCC-WAN-...", text: $vm.wanRoomCode)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 13, design: .monospaced))
                                Button("Kopieren") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(vm.wanRoomCode, forType: .string)
                                    vm.wanStatusNote = "Raum-Code \(vm.wanRoomCode) kopiert."
                                }
                                .buttonStyle(.bordered)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Overlay-Protokoll & NAT-Durchquerung")
                                .font(.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker("Transport", selection: $vm.wanTransport) {
                                ForEach(WanOverlayTransport.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .labelsHidden()
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Verbund-Größe")
                                .font(.caption)
                                .foregroundColor(SolarisTheme.textSecondary)
                            Picker("Größe", selection: $vm.wanScaleMode) {
                                ForEach(InternetClusterScale.allCases) { scale in
                                    Text(scale.rawValue).tag(scale)
                                }
                            }
                            .labelsHidden()
                        }
                    }

                    Text(vm.wanTransport.natNote)
                        .font(.caption)
                        .foregroundColor(SolarisTheme.mint)

                    HStack(spacing: 14) {
                        Label(
                            vm.wanTailscaleInstalled ? "Tailscale: Bereit (\(vm.wanTailscaleIP.isEmpty ? "CLI" : vm.wanTailscaleIP))" : "Tailscale: Nicht installiert",
                            systemImage: vm.wanTailscaleInstalled ? "checkmark.shield.fill" : "exclamationmark.circle"
                        )
                        .font(.caption)
                        .foregroundColor(vm.wanTailscaleInstalled ? SolarisTheme.emerald : SolarisTheme.textSecondary)

                        Label(
                            vm.wanWireGuardInstalled ? "WireGuard: Bereit" : "WireGuard: Optional (brew install wireguard-tools)",
                            systemImage: vm.wanWireGuardInstalled ? "lock.shield.fill" : "network"
                        )
                        .font(.caption)
                        .foregroundColor(vm.wanWireGuardInstalled ? SolarisTheme.emerald : SolarisTheme.textSecondary)

                        Spacer()

                        Button("Tailscale/Peers neu einlesen") {
                            vm.probeWanOverlayTools()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // 1b. Hybrid Bridge: Couple Local Thunderbolt/RDMA Cluster with Internet WAN Cluster
                SolarisCard(accent: vm.isLocalClusterCoupledWithWan ? SolarisTheme.mint : SolarisTheme.amber) {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: vm.isLocalClusterCoupledWithWan ? "link.circle.fill" : "link.badge.plus")
                                    .foregroundColor(vm.isLocalClusterCoupledWithWan ? SolarisTheme.mint : SolarisTheme.amberGlow)
                                Text("Hybrid-Brücke: Lokalen TB/RDMA-Verbund mit Internet-Cluster koppeln")
                                    .font(SolarisTheme.cardTitle)
                                    .foregroundColor(SolarisTheme.textPrimary)
                            }
                            Text(
                                vm.isLocalClusterCoupledWithWan
                                    ? "Aktiv: \(vm.coupledLocalBridgeCount) lokale Thunderbolt/RDMA-Macs (\(Int(vm.totalPhysicalRamGB)) GB) bilden eine schnelle Tier-0-Insel und teilen Schichten mit \(vm.coupledRemoteWanCount) WAN-Partnern."
                                    : "Fügt alle \(vm.nodes.count) lokalen Thunderbolt/RDMA-Macs (\(Int(vm.totalPhysicalRamGB)) GB RAM) über deinen Rang-0-Leitrechner als gemeinsame Speicher- und Rechen-Insel in den Internet-Cluster ein."
                            )
                            .font(Font.caption)
                            .foregroundColor(SolarisTheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            vm.toggleLocalClusterWanCoupling()
                        } label: {
                            Label(
                                vm.isLocalClusterCoupledWithWan ? "Kopplung lösen" : "Lokal + Internet koppeln",
                                systemImage: vm.isLocalClusterCoupledWithWan ? "xmark.circle" : "bolt.horizontal.fill"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(vm.isLocalClusterCoupledWithWan ? SolarisTheme.coral : SolarisTheme.mint)
                        .foregroundColor(.black)

                        Button {
                            vm.sciScope = .internetWan
                            vm.selectedTab = .science
                        } label: {
                            Label("Im Forschungslabor analysieren", systemImage: "waveform.path.ecg")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                // 2. WAN Pool Summary Tiles
                HStack(spacing: 14) {
                    WanMetricTile(
                        title: "WAN-Teilnehmer",
                        value: "\(vm.wanPeers.count) Macs",
                        sub: vm.wanScaleMode.rawValue,
                        accent: SolarisTheme.amberGlow
                    )
                    WanMetricTile(
                        title: "Verbund-RAM (WAN)",
                        value: "\(Int(vm.wanTotalRamGB)) GB",
                        sub: "\(Int(vm.wanTotalUsableVramGB)) GB nutzbar",
                        accent: SolarisTheme.mint
                    )
                    WanMetricTile(
                        title: "Pipeline-RTT (Summe)",
                        value: String(format: "%.1f ms", vm.wanTotalRttMs),
                        sub: "MTU \(vm.wanTransport.mtuBytes) B · PP-Modus",
                        accent: SolarisTheme.amber
                    )
                    WanMetricTile(
                        title: "Geschätzte WAN-Rate",
                        value: String(format: "%.2f tok/s", vm.wanEstimatedTokPerSec),
                        sub: "Pipeline Parallelism (kein All-Reduce)",
                        accent: SolarisTheme.emerald
                    )
                }

                // 2b. Internet Bandwidth, Throughput & Cluster Performance Impact Monitor
                wanBandwidthMonitorCard

                // 3. Connected Internet Macs & Mega-Cluster Builder
                SolarisCard {
                        HStack {
                            Text("Verbundene Internet-Macs")
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Spacer()
                            Button("32-Mac Schwarm") {
                                vm.populateMegaClusterSwarm(count: 32)
                            }
                            .buttonStyle(.bordered)
                            Button("64-Mac Mega-Verbund") {
                                vm.populateMegaClusterSwarm(count: 64)
                            }
                            .buttonStyle(.bordered)
                        }

                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(vm.wanPeers) { peer in
                                    HStack {
                                        Circle()
                                            .fill(peer.isOnline ? SolarisTheme.emerald : SolarisTheme.coral)
                                            .frame(width: 8, height: 8)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(peer.displayName) · \(peer.region)")
                                                .font(SolarisTheme.bodyBold)
                                                .foregroundColor(peer.isLocalHost ? SolarisTheme.amberGlow : SolarisTheme.textPrimary)
                                            Text("\(peer.chip) · \(Int(peer.ramGB)) GB · \(peer.overlayIP) · RTT \(Int(peer.rttMs)) ms")
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(SolarisTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text(peer.assignedLayers)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(SolarisTheme.mint.opacity(0.18)))
                                            .foregroundColor(SolarisTheme.mint)
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(SolarisTheme.cardElevated)
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 280)

                        Divider().background(SolarisTheme.borderSubtle)

                        // Add Remote Mac via Tailscale / WireGuard IP
                        Text("Entfernten Mac (M1–M9+) per IP hinzufügen")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)

                        HStack(spacing: 8) {
                            TextField("Name (z. B. Studio-Berlin)", text: $vm.wanPeerNameInput)
                                .textFieldStyle(.roundedBorder)
                            TextField("Region", text: $vm.wanPeerRegionInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 95)
                            TextField("Overlay-IP", text: $vm.wanPeerIpInput)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 110)
                        }
                        HStack(spacing: 8) {
                            Picker("Chip", selection: $vm.wanPeerChip) {
                                ForEach(AppleSiliconChipFamily.allCases) { chip in
                                    Text(chip.rawValue.replacingOccurrences(of: "Apple ", with: "")).tag(chip)
                                }
                            }
                            .labelsHidden()
                            Stepper("RAM: \(Int(vm.wanPeerRamGB)) GB", value: $vm.wanPeerRamGB, in: 8...512, step: 8)
                                .font(.caption)
                            Stepper("RTT: \(Int(vm.wanPeerRttMs)) ms", value: $vm.wanPeerRttMs, in: 2...250, step: 5)
                                .font(.caption)
                            Button("Hinzufügen") {
                                vm.addManualWanPeer()
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SolarisTheme.mint)
                            .foregroundColor(.black)
                        }
                }

                // 4. Side-by-Side: Cluster Audio-Party (Left) & Live Participant Chat (Right)
                HStack(alignment: .top, spacing: 18) {
                    audioPartyCard
                        .frame(maxWidth: .infinity)

                    // Right: Live Participant Chat
                    SolarisCard(accent: SolarisTheme.mint) {
                        HStack {
                            Text(vm.t("wan_chat_title"))
                                .font(SolarisTheme.cardTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Spacer()
                            Button("/status") { vm.sendClusterChatMessage("/status") }
                                .buttonStyle(.bordered)
                            Button("/layers") { vm.sendClusterChatMessage("/layers") }
                                .buttonStyle(.bordered)
                            Button("/ping") { vm.sendClusterChatMessage("/ping") }
                                .buttonStyle(.bordered)
                        }

                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(vm.chatMessages) { msg in
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(msg.senderName)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(msg.isSystemEvent ? SolarisTheme.amberGlow : (msg.isSelf ? SolarisTheme.mint : SolarisTheme.emerald))
                                            if !msg.senderRegion.isEmpty {
                                                Text("(\(msg.senderRegion))")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(SolarisTheme.textSecondary)
                                            }
                                            Spacer()
                                            Text(msg.timestamp)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(SolarisTheme.textSecondary)
                                        }
                                        Text(msg.text)
                                            .font(SolarisTheme.bodyLarge)
                                            .foregroundColor(SolarisTheme.textPrimary)
                                            .textSelection(.enabled)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(msg.isSelf ? SolarisTheme.mint.opacity(0.12) : SolarisTheme.cardElevated)
                                    )
                                }
                            }
                        }
                        .frame(height: 330)

                        HStack(spacing: 10) {
                            TextField("Nachricht an Internet-Verbund (oder /status, /layers, /ping)...", text: $vm.chatInput)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    vm.sendClusterChatMessage()
                                }
                            Button {
                                vm.sendClusterChatMessage()
                            } label: {
                                Label("Senden", systemImage: "paperplane.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SolarisTheme.amber)
                            .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
        }
        .onAppear {
            if vm.audioPartyMembers.isEmpty {
                vm.syncAudioPartyMembers()
            }
        }
    }

    // MARK: - Internet Bandwidth & Throughput Performance Monitor

    private var wanBandwidthMonitorCard: some View {
        SolarisCard(accent: vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .foregroundColor(vm.simulateMacStudio ? SolarisTheme.amberGlow : SolarisTheme.emerald)
                        Text("Internetbandbreite & WAN-Datendurchsatz")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text(vm.simulateMacStudio ? "SIMULATION" : "ECHTZEIT-MESSUNG")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(vm.simulateMacStudio ? SolarisTheme.amber : SolarisTheme.emerald)
                            .cornerRadius(5)
                    }
                    Text("\(vm.wanBandwidthSourceLabel) · Interface: \(vm.wanActiveInterfaceName) · Letztes Update: \(vm.wanBandwidthLastUpdated)")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        vm.probeWanBandwidthAndThroughput(runActiveSpeedTest: false)
                    } label: {
                        Label(
                            vm.isProbingWanBandwidth ? "Messe..." : "Live-Check (Ping + Net)",
                            systemImage: "waveform.path.ecg"
                        )
                    }
                    .buttonStyle(.bordered)
                    .disabled(vm.isProbingWanBandwidth)

                    Button {
                        vm.probeWanBandwidthAndThroughput(runActiveSpeedTest: true)
                    } label: {
                        Label("Speedtest (networkQuality)", systemImage: "gauge.with.dots.needle.67percent")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(SolarisTheme.mint)
                    .foregroundColor(.black)
                    .disabled(vm.isProbingWanBandwidth)
                }
            }

            // 4 Network & Throughput KPIs
            HStack(spacing: 12) {
                WanMetricTile(
                    title: "Download-Bandbreite",
                    value: String(format: "%.1f Mbps", vm.wanMeasuredDownloadMbps),
                    sub: String(format: "≈ %.1f MB/s RX", vm.wanMeasuredDownloadMbps / 8.0),
                    accent: SolarisTheme.mint
                )
                WanMetricTile(
                    title: "Upload / Cluster-Uplink",
                    value: String(format: "%.1f Mbps", vm.wanMeasuredUploadMbps),
                    sub: String(format: "Engpass: %.1f Mbps (%.1f MB/s)", vm.wanBottleneckUplinkMbps, vm.wanEffectivePayloadMBs),
                    accent: SolarisTheme.amberGlow
                )
                WanMetricTile(
                    title: "WAN-Ping & Jitter",
                    value: String(format: "%.1f ms", vm.wanMeasuredPingMs),
                    sub: String(format: "Jitter ±%.2f ms · Hop-Sync %.1f ms", vm.wanMeasuredJitterMs, vm.wanActivationSyncOverheadMs),
                    accent: SolarisTheme.amber
                )
                WanMetricTile(
                    title: "Paketverlust & Effizienz",
                    value: String(format: "%.1f%% / %.1f%%", vm.wanMeasuredPacketLossPct, vm.wanPipelineEfficiencyPct),
                    sub: "Loss % / GPU-Compute-Anteil",
                    accent: vm.wanMeasuredPacketLossPct > 1.0 ? SolarisTheme.coral : SolarisTheme.emerald
                )
            }

            // Cluster Performance Impact Summary Banner
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Leistungsauswirkung auf den Internet-Cluster")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text("Bewertung: \(vm.wanConnectionQualityGrade)")
                        .font(Font.caption)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "Netto-Nutzdaten: %.2f MB/s", vm.wanEffectivePayloadMBs))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(SolarisTheme.emerald)
                    Text(String(format: "Resultierender Durchsatz: %.2f tok/s", vm.wanEstimatedTokPerSec))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(SolarisTheme.amberGlow)
                }
            }
            .padding(10)
            .background(SolarisTheme.cardElevated)
            .cornerRadius(10)

            // Throughput History Bar Chart (Download vs Upload)
            if !vm.wanThroughputHistory.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Durchsatz-Verlauf (letzte \(vm.wanThroughputHistory.count) Messungen)")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Spacer()
                        HStack(spacing: 12) {
                            Label("Download (Mbps)", systemImage: "square.fill")
                                .font(Font.caption2)
                                .foregroundColor(SolarisTheme.mint)
                            Label("Upload (Mbps)", systemImage: "square.fill")
                                .font(Font.caption2)
                                .foregroundColor(SolarisTheme.amber)
                        }
                    }
                    let maxMbps = max(10.0, vm.wanThroughputHistory.map { max($0.downloadMbps, $0.uploadMbps) }.max() ?? 100.0)
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(vm.wanThroughputHistory) { sample in
                            VStack(spacing: 2) {
                                HStack(alignment: .bottom, spacing: 2) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(SolarisTheme.mint)
                                        .frame(width: 8, height: max(4, CGFloat(sample.downloadMbps / maxMbps) * 56.0))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(SolarisTheme.amber)
                                        .frame(width: 8, height: max(4, CGFloat(sample.uploadMbps / maxMbps) * 56.0))
                                }
                                Text(String(format: "%.0fms", sample.pingRttMs))
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(SolarisTheme.cardElevated)
                    .cornerRadius(10)
                }
            }

            // Punkt 1: QUIC / Iroh P2P WAN-Transport (0-RTT Multiplex ohne TCP HoL-Blocking)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("WAN-Transport-Protokoll (QUIC / Iroh P2P)", systemImage: "bolt.horizontal.circle.fill")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.mint)
                    Spacer()
                    Text(String(format: "Latenz-Faktor %.2f× · 0-RTT %@", vm.wanTransportLatencyFactor, vm.wanTransportProtocol.zeroRttEnabled ? "AKTIV" : "AUS"))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(vm.wanTransportProtocol.zeroRttEnabled ? SolarisTheme.emerald : SolarisTheme.amber)
                        .cornerRadius(5)
                }

                Picker("WAN-Transport", selection: $vm.wanTransportProtocol) {
                    ForEach(WanTransportProtocol.allCases) { proto in
                        Text(proto.rawValue).tag(proto)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(10)
            .background(SolarisTheme.cardElevated)
            .cornerRadius(10)
        }
    }

    // MARK: - Cluster Audio-Party Card (Xbox / PlayStation-Style for Distributed AI)

    private var audioPartyCard: some View {
        SolarisCard(accent: vm.audioPartyJoined ? SolarisTheme.emerald : SolarisTheme.amber) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: vm.audioPartyJoined ? "headphones.circle.fill" : "mic.circle.fill")
                            .foregroundColor(vm.audioPartyJoined ? SolarisTheme.emerald : SolarisTheme.amberGlow)
                        Text("Cluster Audio-Party")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                    }
                    Text(vm.audioPartyStatusText)
                        .font(.caption)
                        .foregroundColor(vm.audioPartyJoined ? SolarisTheme.emerald : SolarisTheme.textSecondary)
                }
                Spacer()
                Button {
                    vm.toggleAudioParty()
                } label: {
                    Label(
                        vm.audioPartyJoined ? "Party verlassen" : "Party beitreten",
                        systemImage: vm.audioPartyJoined ? "phone.down.fill" : "phone.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.audioPartyJoined ? SolarisTheme.coral : SolarisTheme.emerald)
                .foregroundColor(.black)
            }

            // Party Controls: Mute, Deafen, Push-to-Talk, Noise Gate
            HStack(spacing: 10) {
                Button {
                    vm.togglePartyMute()
                } label: {
                    Label(vm.audioPartyMuted ? "Stumm" : "Mikro an",
                          systemImage: vm.audioPartyMuted ? "mic.slash.fill" : "mic.fill")
                }
                .buttonStyle(.bordered)
                .tint(vm.audioPartyMuted ? SolarisTheme.coral : SolarisTheme.mint)

                Button {
                    vm.togglePartyDeafen()
                } label: {
                    Label(vm.audioPartyDeafened ? "Ton aus" : "Ton an",
                          systemImage: vm.audioPartyDeafened ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(.bordered)
                .tint(vm.audioPartyDeafened ? SolarisTheme.coral : SolarisTheme.amber)

                if vm.audioPartyMicMode == .pushToTalk {
                    Button {
                        vm.triggerPushToTalk(active: !vm.audioPartyPushToTalkActive)
                    } label: {
                        Label(vm.audioPartyPushToTalkActive ? "Funk aktiv" : "Funk-Taste",
                              systemImage: "waveform.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(vm.audioPartyPushToTalkActive ? SolarisTheme.amber : SolarisTheme.cardElevated)
                }

                Spacer()

                // Live Mic Level Bar
                HStack(spacing: 6) {
                    Text("Pegel")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(SolarisTheme.textSecondary)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(SolarisTheme.cardElevated)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(vm.audioPartyMicLevel > 0.14 ? SolarisTheme.emerald : SolarisTheme.mint)
                                .frame(width: max(2, geo.size.width * CGFloat(vm.audioPartyMicLevel)))
                        }
                    }
                    .frame(width: 72, height: 8)
                }
            }

            // Codec, Mic Mode & Bandwidth Footprint
            HStack(spacing: 12) {
                Picker("Mikro-Modus", selection: $vm.audioPartyMicMode) {
                    ForEach(AudioPartyMicMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .labelsHidden()

                Picker("Codec", selection: $vm.audioPartyCodec) {
                    ForEach(AudioPartyCodec.allCases) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
                .labelsHidden()

                Toggle("Rausch-Sperre", isOn: $vm.audioPartyNoiseGate)
                    .toggleStyle(.switch)
                    .font(.caption)
            }

            Text(String(format: "Sprach-Anteil am WAN-Uplink: %.3f %% (Rest bleibt frei für Tensor-Aktivierungen)", vm.audioPartyBandwidthSharePercent))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SolarisTheme.mint)

            // Party Member Roster (Xbox/PS-style cards with speaking rings & per-peer volume)
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(vm.audioPartyMembers) { member in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(member.isSelf ? SolarisTheme.amber.opacity(0.22) : SolarisTheme.mint.opacity(0.18))
                                    .frame(width: 34, height: 34)
                                Circle()
                                    .stroke(member.isSpeaking ? SolarisTheme.emerald : (member.isMuted ? SolarisTheme.coral.opacity(0.5) : Color.white.opacity(0.14)),
                                            lineWidth: member.isSpeaking ? 2.5 : 1.0)
                                    .frame(width: 34, height: 34)
                                Image(systemName: member.isMuted ? "mic.slash" : (member.isSpeaking ? "waveform" : "desktopcomputer"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(member.isSpeaking ? SolarisTheme.emerald : SolarisTheme.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(member.displayName)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(SolarisTheme.textPrimary)
                                    Text(member.roleBadge)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(member.isSelf ? SolarisTheme.amberGlow : SolarisTheme.mint)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(SolarisTheme.cardElevated)
                                        .cornerRadius(4)
                                }
                                Text("\(member.chip) · \(member.assignedLayers) · \(Int(member.voicePingMs)) ms")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(SolarisTheme.textSecondary)
                            }

                            Spacer()

                            if !member.isSelf {
                                Slider(
                                    value: Binding(
                                        get: { member.volumePercent },
                                        set: { vm.setMemberVolume(id: member.id, volume: $0) }
                                    ),
                                    in: 0...150,
                                    step: 10
                                )
                                .frame(width: 70)
                                .tint(SolarisTheme.mint)
                            }

                            Button {
                                vm.toggleMemberMute(id: member.id)
                            } label: {
                                Image(systemName: member.isMuted ? "speaker.slash.fill" : "speaker.wave.2")
                                    .foregroundColor(member.isMuted ? SolarisTheme.coral : SolarisTheme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(member.isSpeaking ? SolarisTheme.emerald.opacity(0.10) : SolarisTheme.cardElevated)
                        )
                    }
                }
            }
            .frame(height: 175)

            // Cluster-Specific Quick Callouts
            HStack(spacing: 8) {
                Button("✓ Bereit") {
                    vm.sendPartyCallout("Knoten bereit für verteilte Inferenz.")
                }
                .buttonStyle(.bordered)
                Button("⚠ KV knapp") {
                    vm.sendPartyCallout("Speicher/KV-Cache knapp — bitte auf 4-Bit KV wechseln!")
                }
                .buttonStyle(.bordered)
                Button("↻ Schichten") {
                    vm.recomputeWanLayerAssignments()
                    vm.syncAudioPartyMembers()
                    vm.sendPartyCallout("Schichtenverteilung im Verbund neu berechnet.")
                }
                .buttonStyle(.bordered)
                Button("▶ T=0,0 Start") {
                    vm.sendPartyCallout("Wissenschaftliche Messreihe (T=0,0) startet jetzt.")
                }
                .buttonStyle(.bordered)
            }
            .font(.caption)
        }
    }
}

private struct WanMetricTile: View {
    let title: String
    let value: String
    let sub: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(SolarisTheme.textSecondary)
            Text(value)
                .font(SolarisTheme.metricMedium)
                .foregroundColor(accent)
            Text(sub)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(SolarisTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SolarisTheme.cardElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.30), lineWidth: 1)
                )
        )
    }
}
