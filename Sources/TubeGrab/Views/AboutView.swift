import SwiftUI
import AppKit

/// App 基本資訊。開好 GitHub Repo 後，把 repoURL 換成你的網址即可。
enum AppInfo {
    static let name = "TubeGrab"
    static let repoURL = "https://github.com/Yucheng0208/Tube-Grab"
    static var hasRepo: Bool { !repoURL.contains("YOUR-ACCOUNT") }

    /// 版本號（不含 build），例如 "1.0"
    static var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var version: String {
        let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let b = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(v) (\(b))"
    }
}

struct AboutView: View {
    private var theme: AccentTheme { AppSettings.shared.theme }
    @State private var versions: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                updateCard
                disclaimer
                credits
                links
            }
            .padding(ui(36))
            .frame(maxWidth: ui(1000))
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task { await loadVersions() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            AppLogo(size: 110)
            Text(AppInfo.name).font(.app(.largeTitle))
            Text("\(t("about.version")) \(AppInfo.version)").font(.app(.callout)).foregroundStyle(.secondary)
            Button { NSWorkspace.shared.open(URL(string: AppInfo.repoURL + "/blob/main/LICENSE")!) } label: {
                Text("Copyright (c) 2026 Yu-Cheng Chang  ·  \(t("about.license"))")
                    .font(.app(.caption)).foregroundStyle(.secondary).underline()
            }
            .buttonStyle(.plain)
            .help(AppInfo.repoURL + "/blob/main/LICENSE")
            Text(t("about.desc")).font(.app(.body)).multilineTextAlignment(.center)
                .foregroundStyle(.secondary).frame(maxWidth: 520)
        }
        .padding(.vertical, 10)
    }

    // MARK: 檢查更新

    private var updateCard: some View {
        let checker = UpdateChecker.shared
        return Card(title: t("up2.title"), icon: "arrow.triangle.2.circlepath") {
            HStack(spacing: 12) {
                Group {
                    switch checker.state {
                    case .idle:
                        if let last = UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date {
                            Label("\(t("up2.lastChecked")) \(last.formatted(.relative(presentation: .named)))", systemImage: "clock")
                                .foregroundStyle(.secondary)
                        } else {
                            Label(t("up2.idle"), systemImage: "clock").foregroundStyle(.secondary)
                        }
                    case .checking:
                        HStack(spacing: 8) { ProgressView().controlSize(.small); Text(t("up2.checking")) }
                    case .upToDate:
                        Label(t("up2.latest"), systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    case .noReleases:
                        Label(t("up2.noReleases"), systemImage: "shippingbox").foregroundStyle(.secondary)
                    case .available(let r):
                        Label(String(format: t("up2.newVersion"), r.version), systemImage: "sparkles")
                            .foregroundStyle(theme.color)
                    case .failed(let msg):
                        Label("\(t("up2.failed")) \(msg)", systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                    }
                }
                .font(.app(.body))
                Spacer()
                if checker.availableRelease != nil {
                    Button { checker.showSheet = true } label: { Label(t("up2.view"), systemImage: "arrow.down.circle.fill") }
                        .buttonStyle(GradientButtonStyle())
                }
                Button { Task { await checker.check(manual: true) } } label: {
                    Label(t("up2.checkNow"), systemImage: "arrow.clockwise")
                }
                .disabled(checker.state == .checking || !AppInfo.hasRepo)
            }
            Toggle(t("up2.auto"), isOn: Bindable(AppSettings.shared).autoCheckUpdates)
                .toggleStyle(.checkbox).font(.app(.callout))
        }
    }

    private var disclaimer: some View {
        Card(title: t("about.notice"), icon: "exclamationmark.shield.fill") {
            Text(t("set.disclaimer")).font(.app(.body)).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var credits: some View {
        Card(title: t("about.credits"), icon: "heart.fill") {
            VStack(spacing: 8) {
                creditRow("yt-dlp", "Unlicense", "https://github.com/yt-dlp/yt-dlp", versions["yt-dlp"])
                creditRow("FFmpeg", "LGPL / GPL", "https://ffmpeg.org", versions["ffmpeg"])
                creditRow("Deno", "MIT", "https://deno.com", versions["deno"])
                creditRow("SwiftUI · AVKit", "Apple", "https://developer.apple.com/swiftui/", nil)
            }
        }
    }

    private func creditRow(_ name: String, _ license: String, _ url: String, _ version: String?) -> some View {
        HStack(spacing: 10) {
            Text(name).font(.app(.body).weight(.semibold))
            if let version { Pill(text: version) }
            Spacer()
            Text(license).font(.app(.caption)).foregroundStyle(.secondary)
            Button { NSWorkspace.shared.open(URL(string: url)!) } label: { Image(systemName: "arrow.up.right.square") }
                .buttonStyle(.borderless)
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(Color.primary.opacity(0.03), in: RoundedRectangle(cornerRadius: 8))
    }

    private var links: some View {
        Card(title: t("fb.title"), icon: "bubble.left.and.exclamationmark.bubble.right.fill") {
            Text(t("fb.desc")).font(.app(.callout)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                Button { Feedback.open(.bug) } label: {
                    Label(t("fb.bug"), systemImage: "ladybug.fill")
                }
                .buttonStyle(GradientButtonStyle())
                Button { Feedback.open(.idea) } label: {
                    Label(t("fb.idea"), systemImage: "lightbulb.fill")
                }
                Button { NSWorkspace.shared.open(URL(string: AppInfo.repoURL + "/issues")!) } label: {
                    Label(t("fb.existing"), systemImage: "list.bullet.rectangle")
                }
                Spacer()
                Button { NSWorkspace.shared.open(URL(string: AppInfo.repoURL)!) } label: {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .help(AppInfo.repoURL)
            }
            .disabled(!AppInfo.hasRepo)
        }
    }

    /// 顯示目前安裝的外部工具版本
    private func loadVersions() async {
        let s = AppSettings.shared
        func first(_ out: String) -> String {
            let line = out.split(separator: "\n").first.map(String.init) ?? ""
            // 「ffmpeg version 8.0 Copyright…」→「8.0」；「deno 2.5.0 (…)」→「2.5.0」
            let parts = line.split(separator: " ").map(String.init)
            if parts.count >= 3, parts[1] == "version" { return parts[2] }
            if parts.count >= 2, !parts[0].first!.isNumber { return parts[1] }
            return line
        }
        if let r = try? await ProcessRunner.run(s.ytdlpPath, ["--version"]), r.status == 0 { versions["yt-dlp"] = first(r.stdout) }
        if let r = try? await ProcessRunner.run(s.ffmpegPath, ["-version"]), r.status == 0 { versions["ffmpeg"] = first(r.stdout) }
        if let d = ToolLocator.find("deno"), let r = try? await ProcessRunner.run(d, ["--version"]), r.status == 0 {
            versions["deno"] = first(r.stdout)
        }
    }
}
