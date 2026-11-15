import AppKit
import SwiftUI

struct AgentIntegrationsView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.t("agents_title"))
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text(vm.t("agents_sub"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Text(vm.agentStatusMessage)
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.emerald)
                    }

                    HStack(spacing: 12) {
                        Text("Cluster Base-URL:")
                            .font(SolarisTheme.bodyBold)
                            .foregroundColor(SolarisTheme.textPrimary)
                        TextField("http://127.0.0.1:8000/v1", text: $vm.openCodeBaseURL)
                            .font(SolarisTheme.monoCode)
                            .textFieldStyle(.plain)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(SolarisTheme.cardElevated))
                            .foregroundColor(SolarisTheme.amberGlow)
                    }
                }

                // OpenCode Integration
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OpenCode (opencode.ai)")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Schreibt ~/.config/opencode/opencode.json + auth.json (inkl. small_model-Routing).")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.installOpenCodeConfig()
                        } label: {
                            Label("OpenCode 1-Klick-Setup", systemImage: "wand.and.stars")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.mint))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.openCodeConfigJSON, forType: .string)
                            vm.agentStatusMessage = "opencode.json in Zwischenablage kopiert."
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(vm.openCodeConfigJSON)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.textPrimary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.38)))
                        .textSelection(.enabled)
                }

                // Hermes Agent Integration
                SolarisCard(accent: SolarisTheme.amber) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hermes Agent (Nous Research)")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Schreibt ~/.hermes/config.yaml & .env (Wechsel im Chat jederzeit mit /model custom).")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.installHermesConfig()
                        } label: {
                            Label("Hermes 1-Klick-Setup", systemImage: "bolt.circle.fill")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.amber))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.hermesConfigYAML, forType: .string)
                            vm.agentStatusMessage = "Hermes config.yaml in Zwischenablage kopiert."
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(vm.hermesConfigYAML)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.textPrimary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.38)))
                        .textSelection(.enabled)
                }

                // Antigravity (AGY) Integration
                SolarisCard(accent: SolarisTheme.emerald) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Google Antigravity (AGY SDK & IDE)")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Schreibt ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py (LocalOpenAIAgentConfig).")
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.installAntigravityConfig()
                        } label: {
                            Label("Antigravity 1-Klick-Setup", systemImage: "sparkles")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.emerald))
                                .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.antigravityConfigPython, forType: .string)
                            vm.agentStatusMessage = "Antigravity Python-Snippet in Zwischenablage kopiert."
                        } label: {
                            Label("Kopieren", systemImage: "doc.on.doc")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(vm.antigravityConfigPython)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.textPrimary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.38)))
                        .textSelection(.enabled)
                }

                // Cursor Integration
                IDEIntegrationCard(
                    title: "Cursor IDE",
                    subtitle: "Schreibt ~/.cursor/ssccc_cluster.json für lokalen OpenAI-kompatiblen Verbund-Zugriff.",
                    buttonTitle: "Cursor 1-Klick-Setup",
                    accent: SolarisTheme.amber,
                    snippet: vm.cursorConfigJSON,
                    onInstall: { vm.installCursorConfig() },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.cursorConfigJSON, forType: .string)
                        vm.agentStatusMessage = "Cursor-Konfiguration in Zwischenablage kopiert."
                    }
                )

                // Visual Studio Code Integration
                IDEIntegrationCard(
                    title: "Visual Studio Code (VS Code)",
                    subtitle: "Schreibt ~/.vscode/ssccc_cluster.json (für Continue, Cline & lokale OpenAI-Erweiterungen).",
                    buttonTitle: "VS Code 1-Klick-Setup",
                    accent: SolarisTheme.mint,
                    snippet: vm.vscodeConfigJSON,
                    onInstall: { vm.installVSCodeConfig() },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.vscodeConfigJSON, forType: .string)
                        vm.agentStatusMessage = "VS-Code-Konfiguration in Zwischenablage kopiert."
                    }
                )

                // Xcode Integration
                IDEIntegrationCard(
                    title: "Apple Xcode",
                    subtitle: "Schreibt ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (OpenAI- & Ollama-Endpunkt).",
                    buttonTitle: "Xcode 1-Klick-Setup",
                    accent: SolarisTheme.emerald,
                    snippet: vm.xcodeConfigJSON,
                    onInstall: { vm.installXcodeConfig() },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.xcodeConfigJSON, forType: .string)
                        vm.agentStatusMessage = "Xcode-Konfiguration in Zwischenablage kopiert."
                    }
                )

                // Punkt 4: Moderne Agenten- & Gateway-Standards (/v1/responses, MCP Registry & A2A Agent Card)
                SolarisCard(accent: SolarisTheme.amberGlow) {
                    HStack {
                        Label("Moderne Gateway-Standards (/v1/responses · MCP · A2A)", systemImage: "network.badge.shield.half.filled")
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.amberGlow)
                        Spacer()
                    }

                    Picker("Protokoll-Vorschau", selection: $vm.selectedGatewayProtocol) {
                        ForEach(AgentGatewayProtocol.allCases) { proto in
                            Text(proto.rawValue).tag(proto)
                        }
                    }
                    .pickerStyle(.segmented)

                    let previewSnippet: String = {
                        switch vm.selectedGatewayProtocol {
                        case .chatCompletions: return vm.cursorConfigJSON
                        case .responsesWithMcp: return vm.generateOpenAIResponsesMcpPayload()
                        case .a2aAgentCard: return vm.generateA2AAgentCardJSON()
                        }
                    }()

                    Text(previewSnippet)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.38)))
                        .textSelection(.enabled)

                    HStack(spacing: 10) {
                        Button("MCP Registry kopieren") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.generateMcpRegistryJSON(), forType: .string)
                            vm.agentStatusMessage = "MCP-Server-Registry (JSON) in Zwischenablage kopiert."
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.mint)
                        .foregroundColor(.black)

                        Button("A2A /.well-known/agent.json kopieren") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.generateA2AAgentCardJSON(), forType: .string)
                            vm.agentStatusMessage = "A2A Agent Card JSON in Zwischenablage kopiert."
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct IDEIntegrationCard: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let accent: Color
    let snippet: String
    let onInstall: () -> Void
    let onCopy: () -> Void

    var body: some View {
        SolarisCard(accent: accent) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)
                    Text(subtitle)
                        .font(SolarisTheme.bodyLarge)
                        .foregroundColor(SolarisTheme.textSecondary)
                }
                Spacer()
                Button(action: onInstall) {
                    Label(buttonTitle, systemImage: "wand.and.stars")
                        .font(SolarisTheme.bodyBold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(accent))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)

                Button(action: onCopy) {
                    Label("Kopieren", systemImage: "doc.on.doc")
                        .font(SolarisTheme.bodyBold)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                        .foregroundColor(SolarisTheme.textPrimary)
                }
                .buttonStyle(.plain)
            }

            Text(snippet)
                .font(SolarisTheme.monoCode)
                .foregroundColor(SolarisTheme.textPrimary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.38)))
                .textSelection(.enabled)
        }
    }
}
