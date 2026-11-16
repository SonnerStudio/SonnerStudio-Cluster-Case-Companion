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
                        Text(L10n.tr(vm.language,
                            de: "Cluster Base-URL:",
                            en: "Cluster Base URL:",
                            fr: "URL de base du cluster :",
                            es: "URL base del clúster:",
                            pt: "URL base do cluster:",
                            ru: "Базовый URL кластера:",
                            ja: "クラスタベース URL:",
                            zh: "集群基础 URL："))
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
                            Text(L10n.tr(vm.language,
                                de: "Schreibt ~/.config/opencode/opencode.json + auth.json (inkl. small_model-Routing).",
                                en: "Writes ~/.config/opencode/opencode.json + auth.json (incl. small_model routing).",
                                fr: "Écrit ~/.config/opencode/opencode.json + auth.json (routage small_model incl.).",
                                es: "Escribe ~/.config/opencode/opencode.json + auth.json (incl. enrutamiento small_model).",
                                pt: "Escreve ~/.config/opencode/opencode.json + auth.json (incl. roteamento small_model).",
                                ru: "Записывает ~/.config/opencode/opencode.json + auth.json (с маршрутизацией small_model).",
                                ja: "~/.config/opencode/opencode.json と auth.json を出力（small_model ルーティング含む）。",
                                zh: "写入 ~/.config/opencode/opencode.json 与 auth.json（含 small_model 路由）。"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.installOpenCodeConfig()
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "OpenCode 1-Klick-Setup",
                                en: "OpenCode 1-Click Setup",
                                fr: "Configuration OpenCode en 1 clic",
                                es: "Configurar OpenCode (1 clic)",
                                pt: "Configurar OpenCode (1 clique)",
                                ru: "Настроить OpenCode в 1 клик",
                                ja: "OpenCode ワンクリック設定",
                                zh: "OpenCode 一键配置"), systemImage: "wand.and.stars")
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
                            vm.agentStatusMessage = L10n.tr(vm.language,
                                de: "opencode.json in Zwischenablage kopiert.",
                                en: "opencode.json copied to clipboard.",
                                fr: "opencode.json copié dans le presse-papiers.",
                                es: "opencode.json copiado al portapapeles.",
                                pt: "opencode.json copiado para a área de transferência.",
                                ru: "opencode.json скопирован в буфер обмена.",
                                ja: "opencode.json をクリップボードにコピーしました。",
                                zh: "已将 opencode.json 复制到剪贴板。")
                        } label: {
                            Label(L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"), systemImage: "doc.on.doc")
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
                            Text(L10n.tr(vm.language,
                                de: "Schreibt ~/.hermes/config.yaml & .env (Wechsel im Chat jederzeit mit /model custom).",
                                en: "Writes ~/.hermes/config.yaml & .env (switch anytime in chat via /model custom).",
                                fr: "Écrit ~/.hermes/config.yaml & .env (changement à tout moment via /model custom).",
                                es: "Escribe ~/.hermes/config.yaml y .env (cambia en el chat con /model custom).",
                                pt: "Escreve ~/.hermes/config.yaml e .env (mude no chat com /model custom).",
                                ru: "Записывает ~/.hermes/config.yaml и .env (смена в чате через /model custom).",
                                ja: "~/.hermes/config.yaml と .env を出力（チャット中に /model custom で切替可能）。",
                                zh: "写入 ~/.hermes/config.yaml 与 .env（聊天中可随时用 /model custom 切换）。"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.installHermesConfig()
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "Hermes 1-Klick-Setup",
                                en: "Hermes 1-Click Setup",
                                fr: "Configuration Hermes en 1 clic",
                                es: "Configurar Hermes (1 clic)",
                                pt: "Configurar Hermes (1 clique)",
                                ru: "Настроить Hermes в 1 клик",
                                ja: "Hermes ワンクリック設定",
                                zh: "Hermes 一键配置"), systemImage: "bolt.circle.fill")
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
                            vm.agentStatusMessage = L10n.tr(vm.language,
                                de: "Hermes config.yaml in Zwischenablage kopiert.",
                                en: "Hermes config.yaml copied to clipboard.",
                                fr: "Hermes config.yaml copié dans le presse-papiers.",
                                es: "Hermes config.yaml copiado al portapapeles.",
                                pt: "Hermes config.yaml copiado para a área de transferência.",
                                ru: "Hermes config.yaml скопирован в буфер обмена.",
                                ja: "Hermes config.yaml をクリップボードにコピーしました。",
                                zh: "已将 Hermes config.yaml 复制到剪贴板。")
                        } label: {
                            Label(L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"), systemImage: "doc.on.doc")
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
                            Text(L10n.tr(vm.language,
                                de: "Schreibt ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py (LocalOpenAIAgentConfig).",
                                en: "Writes ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py (LocalOpenAIAgentConfig).",
                                fr: "Écrit ~/.gemini/antigravity/ssccc_local_provider.json & ssccc_local_agent.py (LocalOpenAIAgentConfig).",
                                es: "Escribe ~/.gemini/antigravity/ssccc_local_provider.json y ssccc_local_agent.py (LocalOpenAIAgentConfig).",
                                pt: "Escreve ~/.gemini/antigravity/ssccc_local_provider.json e ssccc_local_agent.py (LocalOpenAIAgentConfig).",
                                ru: "Записывает ~/.gemini/antigravity/ssccc_local_provider.json и ssccc_local_agent.py (LocalOpenAIAgentConfig).",
                                ja: "~/.gemini/antigravity/ssccc_local_provider.json と ssccc_local_agent.py を出力（LocalOpenAIAgentConfig）。",
                                zh: "写入 ~/.gemini/antigravity/ssccc_local_provider.json 与 ssccc_local_agent.py (LocalOpenAIAgentConfig)。"))
                                .font(SolarisTheme.bodyLarge)
                                .foregroundColor(SolarisTheme.textSecondary)
                        }
                        Spacer()
                        Button {
                            vm.installAntigravityConfig()
                        } label: {
                            Label(L10n.tr(vm.language,
                                de: "Antigravity 1-Klick-Setup",
                                en: "Antigravity 1-Click Setup",
                                fr: "Configuration Antigravity en 1 clic",
                                es: "Configurar Antigravity (1 clic)",
                                pt: "Configurar Antigravity (1 clique)",
                                ru: "Настроить Antigravity в 1 клик",
                                ja: "Antigravity ワンクリック設定",
                                zh: "Antigravity 一键配置"), systemImage: "sparkles")
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
                            vm.agentStatusMessage = L10n.tr(vm.language,
                                de: "Antigravity Python-Snippet in Zwischenablage kopiert.",
                                en: "Antigravity Python snippet copied to clipboard.",
                                fr: "Extrait Python Antigravity copié dans le presse-papiers.",
                                es: "Fragmento Python de Antigravity copiado al portapapeles.",
                                pt: "Snippet Python Antigravity copiado para a área de transferência.",
                                ru: "Python-сниппет Antigravity скопирован в буфер обмена.",
                                ja: "Antigravity Python スニペットをクリップボードにコピーしました。",
                                zh: "已将 Antigravity Python 代码片段复制到剪贴板。")
                        } label: {
                            Label(L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"), systemImage: "doc.on.doc")
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
                    subtitle: L10n.tr(vm.language,
                        de: "Schreibt ~/.cursor/ssccc_cluster.json für lokalen OpenAI-kompatiblen Verbund-Zugriff.",
                        en: "Writes ~/.cursor/ssccc_cluster.json for local OpenAI-compatible cluster access.",
                        fr: "Écrit ~/.cursor/ssccc_cluster.json pour l'accès local compatible OpenAI.",
                        es: "Escribe ~/.cursor/ssccc_cluster.json para acceso local compatible con OpenAI.",
                        pt: "Escreve ~/.cursor/ssccc_cluster.json para acesso local compatível com OpenAI.",
                        ru: "Записывает ~/.cursor/ssccc_cluster.json для локального доступа OpenAI API.",
                        ja: "ローカル OpenAI 互換クラスタ接続用に ~/.cursor/ssccc_cluster.json を出力します。",
                        zh: "写入 ~/.cursor/ssccc_cluster.json 以提供本地 OpenAI 兼容集群接入。"),
                    buttonTitle: L10n.tr(vm.language,
                        de: "Cursor 1-Klick-Setup",
                        en: "Cursor 1-Click Setup",
                        fr: "Configuration Cursor en 1 clic",
                        es: "Configurar Cursor (1 clic)",
                        pt: "Configurar Cursor (1 clique)",
                        ru: "Настроить Cursor в 1 клик",
                        ja: "Cursor ワンクリック設定",
                        zh: "Cursor 一键配置"),
                    copyLabel: L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"),
                    accent: SolarisTheme.amber,
                    snippet: vm.cursorConfigJSON,
                    onInstall: { vm.installCursorConfig() },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.cursorConfigJSON, forType: .string)
                        vm.agentStatusMessage = L10n.tr(vm.language,
                            de: "Cursor-Konfiguration in Zwischenablage kopiert.",
                            en: "Cursor configuration copied to clipboard.",
                            fr: "Configuration Cursor copiée dans le presse-papiers.",
                            es: "Configuración de Cursor copiada al portapapeles.",
                            pt: "Configuração do Cursor copiada para a área de transferência.",
                            ru: "Конфигурация Cursor скопирована в буфер обмена.",
                            ja: "Cursor 設定をクリップボードにコピーしました。",
                            zh: "已将 Cursor 配置复制到剪贴板。")
                    }
                )

                // Visual Studio Code Integration
                IDEIntegrationCard(
                    title: "Visual Studio Code (VS Code)",
                    subtitle: L10n.tr(vm.language,
                        de: "Schreibt ~/.vscode/ssccc_cluster.json (für Continue, Cline & lokale OpenAI-Erweiterungen).",
                        en: "Writes ~/.vscode/ssccc_cluster.json (for Continue, Cline & local OpenAI extensions).",
                        fr: "Écrit ~/.vscode/ssccc_cluster.json (pour Continue, Cline & extensions OpenAI locales).",
                        es: "Escribe ~/.vscode/ssccc_cluster.json (para Continue, Cline y extensiones OpenAI locales).",
                        pt: "Escreve ~/.vscode/ssccc_cluster.json (para Continue, Cline e extensões OpenAI locais).",
                        ru: "Записывает ~/.vscode/ssccc_cluster.json (для Continue, Cline и локальных расширений OpenAI).",
                        ja: "Continue・Cline・ローカル OpenAI 拡張向けに ~/.vscode/ssccc_cluster.json を出力します。",
                        zh: "写入 ~/.vscode/ssccc_cluster.json（适用于 Continue、Cline 及本地 OpenAI 扩展）。"),
                    buttonTitle: L10n.tr(vm.language,
                        de: "VS Code 1-Klick-Setup",
                        en: "VS Code 1-Click Setup",
                        fr: "Configuration VS Code en 1 clic",
                        es: "Configurar VS Code (1 clic)",
                        pt: "Configurar VS Code (1 clique)",
                        ru: "Настроить VS Code в 1 клик",
                        ja: "VS Code ワンクリック設定",
                        zh: "VS Code 一键配置"),
                    copyLabel: L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"),
                    accent: SolarisTheme.mint,
                    snippet: vm.vscodeConfigJSON,
                    onInstall: { vm.installVSCodeConfig() },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.vscodeConfigJSON, forType: .string)
                        vm.agentStatusMessage = L10n.tr(vm.language,
                            de: "VS-Code-Konfiguration in Zwischenablage kopiert.",
                            en: "VS Code configuration copied to clipboard.",
                            fr: "Configuration VS Code copiée dans le presse-papiers.",
                            es: "Configuración de VS Code copiada al portapapeles.",
                            pt: "Configuração do VS Code copiada para a área de transferência.",
                            ru: "Конфигурация VS Code скопирована в буфер обмена.",
                            ja: "VS Code 設定をクリップボードにコピーしました。",
                            zh: "已将 VS Code 配置复制到剪贴板。")
                    }
                )

                // Xcode Integration
                IDEIntegrationCard(
                    title: "Apple Xcode",
                    subtitle: L10n.tr(vm.language,
                        de: "Schreibt ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (OpenAI- & Ollama-Endpunkt).",
                        en: "Writes ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (OpenAI & Ollama endpoint).",
                        fr: "Écrit ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (point d'accès OpenAI & Ollama).",
                        es: "Escribe ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (endpoint OpenAI y Ollama).",
                        pt: "Escreve ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (endpoint OpenAI e Ollama).",
                        ru: "Записывает ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json (OpenAI и Ollama).",
                        ja: "OpenAI & Ollama エンドポイント用に SSCCCClusterProvider.json を出力します。",
                        zh: "写入 ~/Library/Developer/Xcode/UserData/SSCCCClusterProvider.json（OpenAI 与 Ollama 端点）。"),
                    buttonTitle: L10n.tr(vm.language,
                        de: "Xcode 1-Klick-Setup",
                        en: "Xcode 1-Click Setup",
                        fr: "Configuration Xcode en 1 clic",
                        es: "Configurar Xcode (1 clic)",
                        pt: "Configurar Xcode (1 clique)",
                        ru: "Настроить Xcode в 1 клик",
                        ja: "Xcode ワンクリック設定",
                        zh: "Xcode 一键配置"),
                    copyLabel: L10n.tr(vm.language, de: "Kopieren", en: "Copy", fr: "Copier", es: "Copiar", pt: "Copiar", ru: "Копировать", ja: "コピー", zh: "复制"),
                    accent: SolarisTheme.emerald,
                    snippet: vm.xcodeConfigJSON,
                    onInstall: { vm.installXcodeConfig() },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.xcodeConfigJSON, forType: .string)
                        vm.agentStatusMessage = L10n.tr(vm.language,
                            de: "Xcode-Konfiguration in Zwischenablage kopiert.",
                            en: "Xcode configuration copied to clipboard.",
                            fr: "Configuration Xcode copiée dans le presse-papiers.",
                            es: "Configuración de Xcode copiada al portapapeles.",
                            pt: "Configuração do Xcode copiada para a área de transferência.",
                            ru: "Конфигурация Xcode скопирована в буфер обмена.",
                            ja: "Xcode 設定をクリップボードにコピーしました。",
                            zh: "已将 Xcode 配置复制到剪贴板。")
                    }
                )

                // Punkt 4: Moderne Agenten- & Gateway-Standards (/v1/responses, MCP Registry & A2A Agent Card)
                SolarisCard(accent: SolarisTheme.amberGlow) {
                    HStack {
                        Label(L10n.tr(vm.language,
                            de: "Moderne Gateway-Standards (/v1/responses · MCP · A2A)",
                            en: "Modern Gateway Standards (/v1/responses · MCP · A2A)",
                            fr: "Standards passerelle modernes (/v1/responses · MCP · A2A)",
                            es: "Estándares de pasarela modernos (/v1/responses · MCP · A2A)",
                            pt: "Padrões modernos de gateway (/v1/responses · MCP · A2A)",
                            ru: "Современные стандарты шлюза (/v1/responses · MCP · A2A)",
                            ja: "最新ゲートウェイ標準 (/v1/responses · MCP · A2A)",
                            zh: "现代网关标准 (/v1/responses · MCP · A2A)"), systemImage: "network.badge.shield.half.filled")
                            .font(SolarisTheme.sectionTitle)
                            .foregroundColor(SolarisTheme.amberGlow)
                        Spacer()
                    }

                    Picker(L10n.tr(vm.language,
                        de: "Protokoll-Vorschau",
                        en: "Protocol Preview",
                        fr: "Aperçu du protocole",
                        es: "Vista previa del protocolo",
                        pt: "Pré-visualização de protocolo",
                        ru: "Предпросмотр протокола",
                        ja: "プロトコルプレビュー",
                        zh: "协议预览"), selection: $vm.selectedGatewayProtocol) {
                        ForEach(AgentGatewayProtocol.allCases) { proto in
                            Text(proto.localizedTitle(vm.language)).tag(proto)
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
                        Button(L10n.tr(vm.language,
                            de: "MCP Registry kopieren",
                            en: "Copy MCP Registry",
                            fr: "Copier le registre MCP",
                            es: "Copiar registro MCP",
                            pt: "Copiar registo MCP",
                            ru: "Копировать реестр MCP",
                            ja: "MCP レジストリをコピー",
                            zh: "复制 MCP 注册表")) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.generateMcpRegistryJSON(), forType: .string)
                            vm.agentStatusMessage = L10n.tr(vm.language,
                                de: "MCP-Server-Registry (JSON) in Zwischenablage kopiert.",
                                en: "MCP Server Registry (JSON) copied to clipboard.",
                                fr: "Registre serveur MCP (JSON) copié dans le presse-papiers.",
                                es: "Registro de servidor MCP (JSON) copiado al portapapeles.",
                                pt: "Registo de servidor MCP (JSON) copiado para a área de transferência.",
                                ru: "Реестр MCP-серверов (JSON) скопирован в буфер обмена.",
                                ja: "MCP サーバーレジストリ (JSON) をクリップボードにコピーしました。",
                                zh: "已将 MCP 服务器注册表 (JSON) 复制到剪贴板。")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SolarisTheme.mint)
                        .foregroundColor(.black)

                        Button(L10n.tr(vm.language,
                            de: "A2A /.well-known/agent.json kopieren",
                            en: "Copy A2A /.well-known/agent.json",
                            fr: "Copier A2A /.well-known/agent.json",
                            es: "Copiar A2A /.well-known/agent.json",
                            pt: "Copiar A2A /.well-known/agent.json",
                            ru: "Копировать A2A /.well-known/agent.json",
                            ja: "A2A /.well-known/agent.json をコピー",
                            zh: "复制 A2A /.well-known/agent.json")) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(vm.generateA2AAgentCardJSON(), forType: .string)
                            vm.agentStatusMessage = L10n.tr(vm.language,
                                de: "A2A Agent Card JSON in Zwischenablage kopiert.",
                                en: "A2A Agent Card JSON copied to clipboard.",
                                fr: "JSON carte d'agent A2A copié dans le presse-papiers.",
                                es: "JSON de tarjeta de agente A2A copiado al portapapeles.",
                                pt: "JSON do cartão de agente A2A copiado para a área de transferência.",
                                ru: "JSON визитки агента A2A скопирован в буфер обмена.",
                                ja: "A2A エージェントカード JSON をクリップボードにコピーしました。",
                                zh: "已将 A2A 智能体名片 JSON 复制到剪贴板。")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .solarisShorttip(vm.shorttip(.agents), id: "view_agents_gateway", vm: vm)
            }
            .padding(24)
        }
    }
}

private struct IDEIntegrationCard: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let copyLabel: String
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
                    Label(copyLabel, systemImage: "doc.on.doc")
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
