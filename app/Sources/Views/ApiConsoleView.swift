import SwiftUI

struct ApiConsoleView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 16) {
                    SolarisCard(accent: vm.daemonConnected ? SolarisTheme.emerald : SolarisTheme.amber) {
                        Text("OpenAI-Kompatibler Endpunkt")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("http://127.0.0.1:8000/v1")
                            .font(SolarisTheme.monoCode)
                            .foregroundColor(SolarisTheme.amberGlow)
                        Text("Für Cursor, Continue, Open WebUI & Xcode")
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                    SolarisCard {
                        Text("Ollama-Kompatibler Endpunkt")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("http://127.0.0.1:8000/api/tags")
                            .font(SolarisTheme.monoCode)
                            .foregroundColor(SolarisTheme.mint)
                        Text("Status: \(vm.daemonConnected ? "Daemon verbunden" : "Lokale UI-Vorschau")")
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }

                SolarisCard {
                    Text("Cluster-Test-Konsole")
                        .font(SolarisTheme.sectionTitle)
                        .foregroundColor(SolarisTheme.textPrimary)

                    TextEditor(text: $vm.promptInput)
                        .font(SolarisTheme.bodyLarge)
                        .frame(height: 90)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                        .foregroundColor(SolarisTheme.textPrimary)

                    HStack {
                        Button {
                            Task { await vm.sendTestPrompt() }
                        } label: {
                            Label(
                                vm.isSendingPrompt ? "Sende..." : "Test-Anfrage ausführen",
                                systemImage: "paperplane.fill"
                            )
                            .font(SolarisTheme.bodyBold)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.amber))
                            .foregroundColor(.black)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.isSendingPrompt)

                        Button {
                            Task { await vm.checkDaemonHealth() }
                        } label: {
                            Label("Daemon prüfen", systemImage: "arrow.clockwise")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Antwort / Telemetrie:")
                        .font(SolarisTheme.bodyBold)
                        .foregroundColor(SolarisTheme.textSecondary)

                    Text(vm.consoleOutput)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.textPrimary)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                        .textSelection(.enabled)
                }
            }
            .padding(24)
        }
    }
}
