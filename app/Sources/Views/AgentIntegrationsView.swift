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
                            Text("KI-Agenten & Coding-IDEs anbinden")
                                .font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Text("Verbinde OpenCode und Hermes Agent per 1-Klick direkt mit der vollen 52-GB-Cluster-Leistung.")
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
            }
            .padding(24)
        }
    }
}
