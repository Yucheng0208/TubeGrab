import SwiftUI
import AppKit

/// App 基本資訊。開好 GitHub Repo 後，把 repoURL 換成你的網址即可。
enum AppInfo {
    static let name = "TubeGrab"
    static let repoURL = "https://github.com/YOUR-ACCOUNT/TubeGrab-macOS"
    static var hasRepo: Bool { !repoURL.contains("YOUR-ACCOUNT") }

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
                disclaimer
                credits
                links
            }
            .padding(28)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(t("nav.about"))
        .task { await loadVersions() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.system(size: 44, weight: .bold)).foregroundStyle(.white)
                .frame(width: 96, height: 96)
                .background(theme.gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: theme.color.opacity(0.4), radius: 16, y: 6)
            Text(AppInfo.name).font(.app(.largeTitle))
            Text("\(t("about.version")) \(AppInfo.version)").font(.app(.callout)).foregroundStyle(.secondary)
            Text(t("about.desc")).font(.app(.body)).multilineTextAlignment(.center)
                .foregroundStyle(.secondary).frame(maxWidth: 520)
        }
        .padding(.vertical, 10)
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
        HStack(spacing: 12) {
            Button {
                NSWorkspace.shared.open(URL(string: AppInfo.repoURL)!)
            } label: {
                Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .buttonStyle(GradientButtonStyle())
            .disabled(!AppInfo.hasRepo)
            .help(AppInfo.hasRepo ? AppInfo.repoURL : t("about.repoSoon"))

            Button {
                NSWorkspace.shared.open(URL(string: AppInfo.hasRepo ? AppInfo.repoURL + "/issues" : "https://github.com")!)
            } label: { Label(t("about.feedback"), systemImage: "bubble.left.and.exclamationmark.bubble.right") }
            .disabled(!AppInfo.hasRepo)
        }
        .padding(.top, 4)
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
