import Foundation
import Observation

/// 找不到 yt-dlp / ffmpeg 時自動安裝。
/// 1. 有 Homebrew → brew install yt-dlp ffmpeg deno
/// 2. 沒有 Homebrew → 從官方發佈頁下載單一執行檔到 ~/Library/Application Support/TubeGrab/bin
@MainActor
@Observable
final class ToolInstaller {
    static let shared = ToolInstaller()

    var isInstalling = false
    var log = ""
    var progress: Double = 0
    var lastError: String?

    nonisolated static var binDir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TubeGrab/bin", isDirectory: true)
    }

    var toolsReady: Bool {
        let s = AppSettings.shared
        return FileManager.default.isExecutableFile(atPath: s.ytdlpPath)
            && FileManager.default.isExecutableFile(atPath: s.ffmpegPath)
    }

    /// 重新偵測；找不到就自動安裝
    func detectOrInstall() async {
        redetect()
        if !toolsReady { await install() }
    }

    func redetect() {
        let s = AppSettings.shared
        s.ytdlpPath = ToolLocator.find("yt-dlp") ?? ""
        s.ffmpegPath = ToolLocator.find("ffmpeg") ?? ""
    }

    func install() async {
        guard !isInstalling else { return }
        isInstalling = true; lastError = nil; log = ""; progress = 0
        defer { isInstalling = false }
        do {
            if let brew = ToolLocator.find("brew") {
                try await installWithBrew(brew)
            } else {
                try await installStandalone()
            }
            redetect()
            progress = 1
            if !toolsReady { throw ToolError(message: t("set.missing")) }
            append(t("set.found"))
        } catch {
            lastError = error.localizedDescription
            append(t("status.failed") + ": " + error.localizedDescription)
        }
    }

    private func append(_ s: String) {
        log += (log.isEmpty ? "" : "\n") + s
        // 只保留最後 200 行
        let lines = log.split(separator: "\n", omittingEmptySubsequences: false)
        if lines.count > 200 { log = lines.suffix(200).joined(separator: "\n") }
    }

    // MARK: Homebrew

    private func installWithBrew(_ brew: String) async throws {
        var missing: [String] = []
        if ToolLocator.find("yt-dlp") == nil { missing.append("yt-dlp") }
        if ToolLocator.find("ffmpeg") == nil { missing.append("ffmpeg") }
        // 新版 yt-dlp 需要 JavaScript 執行環境才能完整支援 YouTube
        if ToolLocator.find("deno") == nil { missing.append("deno") }
        guard !missing.isEmpty else { return }
        append("$ brew install " + missing.joined(separator: " "))
        progress = 0.1
        let r = try await ProcessRunner.stream(brew, ["install"] + missing, handle: RunningProcess()) { line, _ in
            Task { @MainActor in
                ToolInstaller.shared.append(line)
                ToolInstaller.shared.progress = min(0.95, ToolInstaller.shared.progress + 0.01)
            }
        }
        if r.status != 0 { throw ToolError(message: "brew install failed (\(r.status))") }
    }

    // MARK: 沒有 Homebrew：下載官方執行檔

    private func installStandalone() async throws {
        let fm = FileManager.default
        try fm.createDirectory(at: Self.binDir, withIntermediateDirectories: true)
        #if arch(arm64)
        let ffArch = "arm64", denoArch = "aarch64"
        #else
        let ffArch = "amd64", denoArch = "x86_64"
        #endif

        if ToolLocator.find("yt-dlp") == nil {
            // yt-dlp 官方 GitHub 發佈的 macOS 單一執行檔
            append("↓ yt-dlp (github.com/yt-dlp/yt-dlp)")
            let f = try await download("https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos", weight: 0.3)
            try place(f.file, as: "yt-dlp")
        }
        progress = 0.3
        if ToolLocator.find("ffmpeg") == nil {
            // ffmpeg.org 下載頁所列的 macOS 建置（已簽章）
            append("↓ ffmpeg (ffmpeg.martin-riedl.de)")
            let f = try await download("https://ffmpeg.martin-riedl.de/redirect/latest/macos/\(ffArch)/release/ffmpeg.zip", weight: 0.35)
            try unzip(f.file, binary: "ffmpeg")
            if let final = f.finalURL?.absoluteString.replacingOccurrences(of: "ffmpeg.zip", with: "ffprobe.zip") {
                append("↓ ffprobe")
                let p = try await download(final, weight: 0.15)
                try unzip(p.file, binary: "ffprobe")
            }
        }
        progress = 0.8
        if ToolLocator.find("deno") == nil {
            append("↓ deno (github.com/denoland/deno)")
            let f = try await download("https://github.com/denoland/deno/releases/latest/download/deno-\(denoArch)-apple-darwin.zip", weight: 0.15)
            try unzip(f.file, binary: "deno")
        }
    }

    private func download(_ url: String, weight: Double) async throws -> (file: URL, finalURL: URL?) {
        let start = progress
        let (tmp, resp) = try await URLSession.shared.download(from: URL(string: url)!)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw ToolError(message: "Download failed: \(url)")
        }
        progress = start + weight
        return (tmp, http.url)
    }

    private func place(_ file: URL, as name: String) throws {
        let dest = Self.binDir.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: file, to: dest)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
        append("  → \(dest.path)")
    }

    private func unzip(_ zip: URL, binary: String) throws {
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("tubegrab-unzip-\(UUID().uuidString)")
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = ["-x", "-k", zip.path, out.path]
        try p.run(); p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw ToolError(message: "unzip failed: \(binary)") }
        let found = FileManager.default.enumerator(at: out, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }.first { $0.lastPathComponent == binary }
        guard let bin = found else { throw ToolError(message: "\(binary) not found in archive") }
        try place(bin, as: binary)
        try? FileManager.default.removeItem(at: out)
    }
}
