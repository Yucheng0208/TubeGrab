import AppKit

/// 回報問題 / 功能建議：開啟 GitHub 新 issue，並自動帶入版本與環境資訊。
/// 不會自動送出，使用者在 GitHub 上看過、修改後才會送出。
/// 家目錄路徑會換成 ~，避免把使用者名稱帶出去。
enum Feedback {
    enum Kind { case bug, idea }

    static func open(_ kind: Kind, error: String? = nil, context: String? = nil) {
        Task {
            let env = await environment()
            var c = URLComponents(string: AppInfo.repoURL + "/issues/new")!
            let title: String
            var body: String
            switch kind {
            case .bug:
                title = "[Bug] " + (error.map { String(sanitize($0).prefix(80)) } ?? "")
                body = """
                ### 問題描述 / What happened
                <!-- 請描述發生了什麼、你預期會怎樣 -->

                ### 重現步驟 / Steps to reproduce
                1.
                2.

                """
                if let context, !context.isEmpty {
                    body += "### 下載設定 / Settings\n\(sanitize(context))\n\n"
                }
                if let error, !error.isEmpty {
                    body += "### 錯誤訊息 / Error\n```\n\(String(sanitize(error).prefix(1500)))\n```\n\n"
                }
            case .idea:
                title = "[建議] "
                body = """
                ### 想要的功能 / Feature request
                <!-- 請描述你希望 TubeGrab 能做什麼 -->

                ### 使用情境 / Why it helps
                <!-- 什麼時候會用到？ -->

                """
            }
            body += "### 環境 / Environment\n\(env)\n"
            c.queryItems = [
                .init(name: "title", value: title),
                .init(name: "body", value: body),
                .init(name: "labels", value: kind == .bug ? "bug" : "enhancement"),
            ]
            if let u = c.url { await MainActor.run { _ = NSWorkspace.shared.open(u) } }
        }
    }

    /// 把家目錄換成 ~（不帶出使用者名稱）
    static func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    static func environment() async -> String {
        let os = ProcessInfo.processInfo.operatingSystemVersion
        #if arch(arm64)
        let arch = "Apple Silicon"
        #else
        let arch = "Intel"
        #endif
        func firstLine(_ exe: String, _ args: [String]) async -> String {
            guard FileManager.default.isExecutableFile(atPath: exe),
                  let r = try? await ProcessRunner.run(exe, args), r.status == 0 else { return "—" }
            let line = r.stdout.split(separator: "\n").first.map(String.init) ?? "—"
            // 「ffmpeg version 8.0 Copyright…」只留版本
            let parts = line.split(separator: " ")
            if parts.count >= 3, parts[1] == "version" { return String(parts[2]) }
            return line
        }
        let s = AppSettings.shared
        let ytdlp = await firstLine(s.ytdlpPath, ["--version"])
        let ffmpeg = await firstLine(s.ffmpegPath, ["-version"])
        return """
        - TubeGrab: \(AppInfo.version)
        - macOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion) (\(arch))
        - yt-dlp: \(ytdlp)
        - ffmpeg: \(ffmpeg)
        - 介面語言 / Language: \(s.language.resolved.rawValue)
        - 瀏覽器登入 / Browser sign-in: \(s.useBrowserCookies ? s.cookieBrowser : "off")
        """
    }
}
