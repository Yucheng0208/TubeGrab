import AppKit
import AVFoundation

/// 打開下載好的檔案，盡量保證「點了就開」：
/// 1. 檔案不在原位置（被改名或換了副檔名）→ 在同資料夾找同名檔案
/// 2. macOS 內建（QuickTime / 音樂）能播放 → 用預設 App 打開
/// 3. 內建不能播（MKV、WEBM、OPUS、OGG、VP9 編碼的 4K MP4…）→ 改用 IINA 或 VLC
/// 4. 都沒有 → 在 Finder 中選取該檔案，不跳出「無法打開」的錯誤
enum FileOpener {
    /// 能播放大多數格式的播放器（依序嘗試）
    static let universalPlayers = ["com.colliderli.iina", "org.videolan.vlc", "io.mpv"]

    static func open(_ file: URL?) {
        guard let file else { return }
        guard let real = locate(file) else {
            // 檔案不見了：至少打開原本的資料夾
            NSWorkspace.shared.open(file.deletingLastPathComponent())
            return
        }
        Task {
            if await systemCanPlay(real), NSWorkspace.shared.urlForApplication(toOpen: real) != nil {
                await openWith(nil, real)
            } else if let player = installedUniversalPlayer() {
                await openWith(player, real)
            } else if let app = NSWorkspace.shared.urlForApplication(toOpen: real) {
                await openWith(app, real)
            } else {
                await MainActor.run { NSWorkspace.shared.activateFileViewerSelecting([real]) }
            }
        }
    }

    static func reveal(_ file: URL?) {
        guard let file else { return }
        if let real = locate(file) {
            NSWorkspace.shared.activateFileViewerSelecting([real])
        } else {
            NSWorkspace.shared.open(file.deletingLastPathComponent())
        }
    }

    /// 找到實際的檔案（原路徑，或同資料夾內同檔名、不同副檔名的檔案）
    static func locate(_ file: URL) -> URL? {
        let fm = FileManager.default
        if fm.fileExists(atPath: file.path) { return file }
        let dir = file.deletingLastPathComponent()
        let base = file.deletingPathExtension().lastPathComponent
        let items = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return items.first { $0.deletingPathExtension().lastPathComponent == base && !$0.lastPathComponent.hasPrefix(".") }
    }

    /// macOS 內建的 AVFoundation 能不能播放（QuickTime 與「音樂」都用它）
    static func systemCanPlay(_ file: URL) async -> Bool {
        let unsupported: Set<String> = ["mkv", "webm", "opus", "ogg", "oga", "flv"]
        if unsupported.contains(file.pathExtension.lowercased()) { return false }
        let asset = AVURLAsset(url: file)
        return (try? await asset.load(.isPlayable)) ?? false
    }

    static func installedUniversalPlayer() -> URL? {
        for id in universalPlayers {
            if let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) { return u }
        }
        return nil
    }

    @MainActor
    private static func openWith(_ app: URL?, _ file: URL) async {
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        do {
            if let app {
                _ = try await NSWorkspace.shared.open([file], withApplicationAt: app, configuration: config)
            } else {
                _ = try await NSWorkspace.shared.open(file, configuration: config)
            }
        } catch {
            // 預設 App 打不開 → 換萬用播放器；再不行就在 Finder 中顯示
            if app == nil, let player = installedUniversalPlayer() {
                _ = try? await NSWorkspace.shared.open([file], withApplicationAt: player, configuration: config)
            } else {
                NSWorkspace.shared.activateFileViewerSelecting([file])
            }
        }
    }
}
