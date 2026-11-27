import SwiftUI
import UniformTypeIdentifiers
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
                LabeledContent(t("set.output")) {
                    HStack {
                        Text(s.outputFolder.path).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                        Button(t("set.choose")) { chooseFolder() }
                    }
                }
                Picker(selection: $s.maxConcurrent) {
                    Text(t("set.unlimited")).tag(0)
                    ForEach([1, 2, 3, 5, 10], id: \.self) { Text("\($0)").tag($0) }
                } label: { Label(t("set.concurrent"), systemImage: "square.stack.3d.down.right") }
                if s.maxConcurrent == 0 || s.maxConcurrent > 5 {
                    Label(t("set.concurrentWarn"), systemImage: "info.circle")
                        .font(.app(.caption)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
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
                        GradientProgressBar(value: ToolInstaller.shared.progress, height: 8, showsPercent: true).frame(width: 220)
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

            Section(t("ck.title")) {
                Toggle(isOn: $s.useBrowserCookies) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(t("ck.toggle")).font(.app(.body).weight(.semibold))
                        Text(t("ck.desc")).font(.app(.caption)).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                Picker(t("ck.browser"), selection: $s.cookieBrowser) {
                    ForEach(CookieBrowser.all, id: \.id) { b in
                        let ok = NSWorkspace.shared.urlForApplication(withBundleIdentifier: b.bundle) != nil
                        Text(ok ? b.name : "\(b.name) (\(t("ck.notInstalled")))").tag(b.id)
                    }
                    Divider()
                    Text(t("ck.fileOption")).tag("file")
                }
                .disabled(!s.useBrowserCookies)
                if s.useBrowserCookies {
                    cookieStatus
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
    }

    // MARK: YouTube 登入狀態

    @State private var accessTick = 0

    @ViewBuilder private var cookieStatus: some View {
        let _ = accessTick
        let access = CookieBrowser.access(s.cookieBrowser)
        if s.cookieBrowser == "file" {
            HStack {
                Text(s.cookiesFile.isEmpty ? t("ck.noFile") : s.cookiesFile)
                    .lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                Spacer()
                Button(t("set.choose")) { chooseCookiesFile() }
            }
            Label(t("ck.fileHint"), systemImage: "info.circle")
                .font(.app(.caption)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        } else {
            switch access {
            case .ok:
                Label(t("ck.statusOK"), systemImage: "checkmark.circle.fill")
                    .font(.app(.callout)).foregroundStyle(.green)
                Label(s.cookieBrowser == "safari" ? t("ck.safariNote") : t("ck.keychainNote"), systemImage: "info.circle")
                    .font(.app(.caption)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            case .denied:
                VStack(alignment: .leading, spacing: 8) {
                    Label(t("ck.statusDenied"), systemImage: "lock.fill")
                        .font(.app(.callout).weight(.semibold)).foregroundStyle(.orange)
                    Text(t("ck.fdaSteps")).font(.app(.caption)).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button { CookieBrowser.openFullDiskAccessSettings() } label: {
                            Label(t("ck.openFDA"), systemImage: "gearshape")
                        }
                        .buttonStyle(GradientButtonStyle())
                        Button { NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL]) } label: {
                            Label(t("ck.showApp"), systemImage: "folder")
                        }
                        Button(t("ck.recheck")) { accessTick += 1 }
                    }
                }
            case .missing:
                Label(t("ck.statusMissing"), systemImage: "questionmark.circle")
                    .font(.app(.callout)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func chooseCookiesFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText, .data]
        if panel.runModal() == .OK, let u = panel.url { s.cookiesFile = u.path }
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
