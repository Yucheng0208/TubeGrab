import SwiftUI
import AppKit

struct SettingsView: View {
    @Bindable private var s = AppSettings.shared
    @State private var updateLog = ""
    @State private var updating = false

    var body: some View {
        Form {
            Section {
                Picker(selection: $s.language) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                } label: { Label(t("set.language"), systemImage: "globe") }
            }

            Section {
                // 深色 / 淺色 / 跟隨系統
                LabeledContent {
                    Picker("", selection: $s.appearance) {
                        ForEach(AppearanceMode.allCases) { m in
                            Label(t(m.labelKey), systemImage: m.icon).tag(m)
                        }
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
                } label: { Label(t("look.mode"), systemImage: "circle.lefthalf.filled") }

                // 主題配色色票
                LabeledContent {
                    HStack(spacing: 10) {
                        ForEach(AccentTheme.allCases) { th in
                            Button { s.theme = th } label: {
                                Circle().fill(th.gradient)
                                    .frame(width: 26, height: 26)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: s.theme == th ? 3 : 0))
                                    .overlay(Circle().strokeBorder(th.color, lineWidth: s.theme == th ? 1.5 : 0).padding(-3))
                                    .shadow(color: th.color.opacity(0.4), radius: s.theme == th ? 4 : 0)
                            }
                            .buttonStyle(.plain)
                            .help(t(th.labelKey))
                        }
                    }
                } label: { Label(t("look.theme"), systemImage: "paintpalette") }

                Picker(selection: $s.fontChoice) {
                    ForEach(FontChoice.allCases) { f in
                        Text(t(f.labelKey)).font(.system(size: 13, design: f.design)).tag(f)
                    }
                } label: { Label(t("look.font"), systemImage: "textformat") }

                LabeledContent {
                    Picker("", selection: $s.textSize) {
                        ForEach(TextSize.allCases) { Text(t($0.labelKey)).tag($0) }
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
                } label: { Label(t("look.size"), systemImage: "textformat.size") }

                Toggle(isOn: $s.boldText) { Label(t("look.bold"), systemImage: "bold") }
                    .toggleStyle(.switch)

                // 即時預覽
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(s.theme.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TubeGrab").font(.app(.title3).weight(.bold))
                        Text(t("look.preview")).font(.app(.body)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    GradientProgressBar(value: 0.62, height: 8).frame(width: 120)
                }
                .padding(.vertical, 4)
            } header: { Text(t("look.section")) }

            Section {
                LabeledContent(t("set.output")) {
                    HStack {
                        Text(s.outputFolder.path).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                        Button(t("set.choose")) { chooseFolder() }
                    }
                }
                Stepper("\(t("set.concurrent")): \(s.maxConcurrent)", value: $s.maxConcurrent, in: 1...5)
            }

            Section(t("set.tools")) {
                toolRow(t("set.ytdlp"), path: $s.ytdlpPath, name: "yt-dlp")
                toolRow(t("set.ffmpeg"), path: $s.ffmpegPath, name: "ffmpeg")
                HStack {
                    Button {
                        Task { await ToolInstaller.shared.detectOrInstall() }
                    } label: {
                        Label(t("tools.detectInstall"), systemImage: "wand.and.stars")
                    }
                    .disabled(ToolInstaller.shared.isInstalling)
                    if ToolInstaller.shared.isInstalling {
                        GradientProgressBar(value: ToolInstaller.shared.progress, height: 8).frame(width: 160)
                    }
                }
                if !ToolInstaller.shared.log.isEmpty {
                    ScrollView {
                        Text(ToolInstaller.shared.log).font(.app(.caption2).monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                    }.frame(maxHeight: 120)
                }
                HStack {
                    Button(t("set.updateYtdlp")) {
                        updating = true
                        Task { updateLog = await YTDLP.selfUpdate(); updating = false }
                    }
                    .disabled(updating || s.ytdlpPath.isEmpty)
                    if updating { ProgressView().controlSize(.small) }
                }
                if !updateLog.isEmpty {
                    Text(updateLog).font(.caption.monospaced()).foregroundStyle(.secondary)
                        .lineLimit(6).textSelection(.enabled)
                }
            }

            Section(t("set.kkbox")) {
                TextField("Client ID", text: $s.kkboxClientID)
                SecureField("Client Secret", text: $s.kkboxClientSecret)
            }

            Section(t("set.spotify")) {
                TextField("Client ID", text: $s.spotifyClientID)
                SecureField("Client Secret", text: $s.spotifyClientSecret)
            }

            Section {
                Label(t("set.disclaimer"), systemImage: "info.circle").foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(t("nav.settings"))
    }

    private func toolRow(_ title: String, path: Binding<String>, name: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField(title, text: path)
                Button(t("set.autoDetect")) {
                    // 找得到就填入；找不到就自動下載安裝
                    if let p = ToolLocator.find(name) { path.wrappedValue = p }
                    else { Task { await ToolInstaller.shared.detectOrInstall() } }
                }
            }
            let ok = FileManager.default.isExecutableFile(atPath: path.wrappedValue)
            Label(ok ? t("set.found") : t("set.missing"),
                  systemImage: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .font(.caption).foregroundStyle(ok ? .green : .red)
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = s.outputFolder
        if panel.runModal() == .OK, let u = panel.url { s.outputFolder = u }
    }
}
