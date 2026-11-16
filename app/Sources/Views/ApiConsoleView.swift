import SwiftUI

struct ApiConsoleView: View {
    @ObservedObject var vm: ClusterViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 16) {
                    SolarisCard(accent: vm.daemonConnected ? SolarisTheme.emerald : SolarisTheme.amber) {
                        Text(vm.t("api_openai"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("http://127.0.0.1:8000/v1")
                            .font(SolarisTheme.monoCode)
                            .foregroundColor(SolarisTheme.amberGlow)
                        Text(L10n.tr(vm.language,
                            de: "Für Cursor, Continue, Open WebUI & Xcode",
                            en: "For Cursor, Continue, Open WebUI & Xcode",
                            fr: "Pour Cursor, Continue, Open WebUI & Xcode",
                            es: "Para Cursor, Continue, Open WebUI y Xcode",
                            pt: "Para Cursor, Continue, Open WebUI e Xcode",
                            ru: "Для Cursor, Continue, Open WebUI и Xcode",
                            ja: "Cursor / Continue / Open WebUI / Xcode 向け",
                            zh: "适用于 Cursor、Continue、Open WebUI 与 Xcode"))
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                    SolarisCard {
                        Text(vm.t("api_ollama"))
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.textPrimary)
                        Text("http://127.0.0.1:8000/api/tags")
                            .font(SolarisTheme.monoCode)
                            .foregroundColor(SolarisTheme.mint)
                        Text(vm.daemonConnected
                            ? L10n.tr(vm.language,
                                de: "Status: Daemon verbunden",
                                en: "Status: Daemon connected",
                                fr: "Statut : Démon connecté",
                                es: "Estado: Daemon conectado",
                                pt: "Estado: Daemon ligado",
                                ru: "Статус: Демон подключён",
                                ja: "状態: デーモン接続済み",
                                zh: "状态：守护进程已连接")
                            : L10n.tr(vm.language,
                                de: "Status: Lokale UI-Vorschau",
                                en: "Status: Local UI Preview",
                                fr: "Statut : Aperçu UI local",
                                es: "Estado: Vista previa local",
                                pt: "Estado: Pré-visualização local",
                                ru: "Статус: Локальный предпросмотр",
                                ja: "状態: ローカルUIプレビュー",
                                zh: "状态：本地界面预览"))
                            .font(SolarisTheme.bodyLarge)
                            .foregroundColor(SolarisTheme.textSecondary)
                    }
                }

                SolarisCard {
                    Text(vm.t("api_console"))
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
                                vm.isSendingPrompt ? vm.t("api_sending") : vm.t("api_send"),
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
                            Label(vm.t("api_health"), systemImage: "arrow.clockwise")
                                .font(SolarisTheme.bodyBold)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(SolarisTheme.cardElevated))
                                .foregroundColor(SolarisTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Text(vm.t("api_output"))
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

                // Punkt 4: /v1/responses + MCP + A2A Agent Card Gateway-Vorschau
                SolarisCard(accent: SolarisTheme.mint) {
                    HStack {
                        Label(L10n.tr(vm.language,
                            de: "Gateway-Protokolle (/v1/responses · MCP · A2A)",
                            en: "Gateway Protocols (/v1/responses · MCP · A2A)",
                            fr: "Protocoles passerelle (/v1/responses · MCP · A2A)",
                            es: "Protocolos de pasarela (/v1/responses · MCP · A2A)",
                            pt: "Protocolos gateway (/v1/responses · MCP · A2A)",
                            ru: "Протоколы шлюза (/v1/responses · MCP · A2A)",
                            ja: "ゲートウェイプロトコル (/v1/responses · MCP · A2A)",
                            zh: "网关协议 (/v1/responses · MCP · A2A)"), systemImage: "arrow.left.arrow.right.circle.fill")
                            .font(SolarisTheme.cardTitle)
                            .foregroundColor(SolarisTheme.mint)
                        Spacer()
                    }
                    Picker(L10n.tr(vm.language,
                        de: "Gateway-Protokoll",
                        en: "Gateway Protocol",
                        fr: "Protocole passerelle",
                        es: "Protocolo de pasarela",
                        pt: "Protocolo gateway",
                        ru: "Протокол шлюза",
                        ja: "ゲートウェイプロトコル",
                        zh: "网关协议"), selection: $vm.selectedGatewayProtocol) {
                        ForEach(AgentGatewayProtocol.allCases) { proto in
                            Text(proto.localizedTitle(vm.language)).tag(proto)
                        }
                    }
                    .pickerStyle(.segmented)

                    let gatewayPayload: String = {
                        switch vm.selectedGatewayProtocol {
                        case .chatCompletions: return "POST \(vm.openCodeBaseURL)/v1/chat/completions"
                        case .responsesWithMcp: return vm.generateOpenAIResponsesMcpPayload()
                        case .a2aAgentCard: return vm.generateA2AAgentCardJSON()
                        }
                    }()

                    Text(gatewayPayload)
                        .font(SolarisTheme.monoCode)
                        .foregroundColor(SolarisTheme.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.35)))
                        .textSelection(.enabled)
                }
            }
            .padding(24)
        }
        .solarisShorttip(vm.shorttip(.console), id: "view_console_root", vm: vm)
    }
}
