import AppKit
import SwiftUI

/// Bildstudio: lokale Bilderzeugung und -bearbeitung über das SS-CCC-Gateway (HiDream-O1).
struct ImageStudioView: View {
    @ObservedObject var vm: ClusterViewModel
    @State private var prompt: String = ""
    @State private var fast = false
    @State private var now = false
    @State private var aspect = "2048x2048"

    private let aspects: [(String, String)] = [("2048x2048", "1:1"), ("2560x1440", "16:9"), ("1440x2560", "9:16"),
                                                ("2304x1728", "4:3"), ("1728x2304", "3:4"), ("3104x1312", "21:9")]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SolarisCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled").foregroundColor(SolarisTheme.amber)
                            Text(GS.t("tab_image", vm.language)).font(SolarisTheme.sectionTitle)
                                .foregroundColor(SolarisTheme.textPrimary)
                            Spacer()
                            Text(GS.t("img_license", vm.language)).font(.caption).foregroundColor(SolarisTheme.textSecondary)
                        }
                        Text(GS.t("img_prompt", vm.language)).font(SolarisTheme.bodyBold).foregroundColor(SolarisTheme.textSecondary)
                        TextEditor(text: $prompt)
                            .font(SolarisTheme.bodyLarge)
                            .frame(minHeight: 90)
                            .padding(6)
                            .background(SolarisTheme.cardElevated)
                            .cornerRadius(8)

                        HStack(spacing: 16) {
                            Picker(GS.t("img_format", vm.language), selection: $aspect) {
                                ForEach(aspects, id: \.0) { a in Text(a.1).tag(a.0) }
                            }
                            .frame(maxWidth: 220)
                            .disabled(fast || !vm.imageRefs.isEmpty)
                            Picker("", selection: $fast) {
                                Text(GS.t("img_quality_best", vm.language)).tag(false)
                                Text(GS.t("img_quality_fast", vm.language)).tag(true)
                            }
                            .pickerStyle(.segmented)
                            .disabled(!vm.imageRefs.isEmpty)
                        }
                        Toggle(GS.t("img_now", vm.language), isOn: $now).foregroundColor(SolarisTheme.textSecondary)

                        // Referenzbilder für Bearbeitung / Mehrfach-Referenz
                        HStack(spacing: 10) {
                            Button { vm.addImageReferences() } label: {
                                Label(GS.t("img_add_ref", vm.language), systemImage: "plus.rectangle.on.rectangle")
                            }
                            .disabled(vm.imageRefs.count >= 3)
                            ForEach(vm.imageRefs, id: \.self) { u in
                                if let img = NSImage(contentsOf: u) {
                                    Image(nsImage: img).resizable().scaledToFill().frame(width: 48, height: 48).clipped().cornerRadius(6)
                                }
                            }
                            if !vm.imageRefs.isEmpty {
                                Button(GS.t("img_clear_refs", vm.language)) { vm.imageRefs = [] }
                            }
                        }

                        HStack {
                            Button {
                                vm.generateImage(prompt: prompt, fast: fast, aspect: aspect, now: now)
                            } label: {
                                Label(vm.imageRefs.isEmpty ? GS.t("img_generate", vm.language) : GS.t("img_edit", vm.language),
                                      systemImage: vm.imageRefs.isEmpty ? "wand.and.stars" : "paintbrush.pointed")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SolarisTheme.amber)
                            .foregroundColor(.black)
                            .disabled(vm.imageBusy || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            if vm.imageBusy { ProgressView().controlSize(.small) }
                            Text(vm.imageStatus).font(.callout).foregroundColor(SolarisTheme.textSecondary)
                        }
                        Text(GS.t("img_queue_hint", vm.language)).font(.caption).foregroundColor(SolarisTheme.textSecondary)
                    }
                }

                ForEach(vm.imageResults) { r in
                    SolarisCard {
                        VStack(alignment: .leading, spacing: 10) {
                            if let img = NSImage(contentsOf: r.fileURL) {
                                Image(nsImage: img).resizable().scaledToFit().frame(maxHeight: 520).cornerRadius(10)
                            }
                            Text(r.prompt).font(.callout).foregroundColor(SolarisTheme.textPrimary).lineLimit(3)
                            HStack {
                                Text(String(format: "%.0f s · %@", r.seconds, r.fileURL.lastPathComponent))
                                    .font(.caption).foregroundColor(SolarisTheme.textSecondary)
                                Spacer()
                                Button(GS.t("img_use_as_ref", vm.language)) {
                                    vm.imageRefs = Array((vm.imageRefs + [r.fileURL]).prefix(3))
                                }
                                Button(GS.t("img_open", vm.language)) {
                                    NSWorkspace.shared.activateFileViewerSelecting([r.fileURL])
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
