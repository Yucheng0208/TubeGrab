import Foundation
import Observation

// MARK: - App 設定

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let d = UserDefaults.standard

    var language: AppLanguage { didSet { d.set(language.rawValue, forKey: "language") } }
    var outputFolder: URL { didSet { d.set(outputFolder.path, forKey: "outputFolder") } }
    var ytdlpPath: String { didSet { d.set(ytdlpPath, forKey: "ytdlpPath") } }
    var ffmpegPath: String { didSet { d.set(ffmpegPath, forKey: "ffmpegPath") } }
    var maxConcurrent: Int { didSet { d.set(maxConcurrent, forKey: "maxConcurrent") } }
    var spotifyClientID: String { didSet { d.set(spotifyClientID, forKey: "spotifyClientID") } }
    var spotifyClientSecret: String { didSet { d.set(spotifyClientSecret, forKey: "spotifyClientSecret") } }

    var kkboxClientID: String { didSet { d.set(kkboxClientID, forKey: "kkboxClientID") } }
    var kkboxClientSecret: String { didSet { d.set(kkboxClientSecret, forKey: "kkboxClientSecret") } }

    // 外觀
    var appearance: AppearanceMode { didSet { d.set(appearance.rawValue, forKey: "appearance") } }
    var theme: AccentTheme { didSet { d.set(theme.rawValue, forKey: "theme") } }
    var fontChoice: FontChoice { didSet { d.set(fontChoice.rawValue, forKey: "fontChoice") } }
    var textSize: TextSize { didSet { d.set(textSize.rawValue, forKey: "textSize") } }
    var boldText: Bool { didSet { d.set(boldText, forKey: "boldText") } }

    private init() {
        language = AppLanguage(rawValue: d.string(forKey: "language") ?? "") ?? .system
        if let p = d.string(forKey: "outputFolder") {
            outputFolder = URL(fileURLWithPath: p)
        } else {
            outputFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Downloads")
        }
        // 存的路徑失效（例如工具被移除）時重新尋找
        let fm = FileManager.default
        if let p = d.string(forKey: "ytdlpPath"), fm.isExecutableFile(atPath: p) { ytdlpPath = p }
        else { ytdlpPath = ToolLocator.find("yt-dlp") ?? "" }
        if let p = d.string(forKey: "ffmpegPath"), fm.isExecutableFile(atPath: p) { ffmpegPath = p }
        else { ffmpegPath = ToolLocator.find("ffmpeg") ?? "" }
        let mc = d.integer(forKey: "maxConcurrent")
        maxConcurrent = mc == 0 ? 2 : mc
        spotifyClientID = d.string(forKey: "spotifyClientID") ?? ""
        spotifyClientSecret = d.string(forKey: "spotifyClientSecret") ?? ""
        kkboxClientID = d.string(forKey: "kkboxClientID") ?? ""
        kkboxClientSecret = d.string(forKey: "kkboxClientSecret") ?? ""
        appearance = AppearanceMode(rawValue: d.string(forKey: "appearance") ?? "") ?? .system
        theme = AccentTheme(rawValue: d.string(forKey: "theme") ?? "") ?? .ruby
        fontChoice = FontChoice(rawValue: d.string(forKey: "fontChoice") ?? "") ?? .rounded
        textSize = TextSize(rawValue: d.string(forKey: "textSize") ?? "") ?? .medium
        boldText = d.bool(forKey: "boldText")
    }

    /// 取得目前語言的字串
    func t(_ key: String) -> String { L10n.string(key, language) }
}

/// 全域翻譯捷徑（在 SwiftUI view 內使用時會自動追蹤語言變更）
func t(_ key: String) -> String { AppSettings.shared.t(key) }

// MARK: - 格式與品質

enum MediaKind: String, CaseIterable, Identifiable, Codable {
    case video, audio
    var id: String { rawValue }
}

enum VideoContainer: String, CaseIterable, Identifiable, Codable {
    case mp4, mov, mkv, webm
    var id: String { rawValue }
}

enum AudioFormat: String, CaseIterable, Identifiable, Codable {
    case mp3, m4a, aac, flac, alac, wav, opus, vorbis
    var id: String { rawValue }
    var label: String {
        switch self {
        case .alac: return "ALAC (.m4a, Apple Lossless)"
        case .vorbis: return "OGG (Vorbis)"
        case .flac: return "FLAC (lossless)"
        case .wav: return "WAV (lossless)"
        default: return rawValue.uppercased()
        }
    }
    var isLossless: Bool { [.flac, .alac, .wav].contains(self) }
    var supportsCover: Bool { ![.wav, .aac].contains(self) }
}

/// 影片畫面比例
enum AspectRatio: String, CaseIterable, Identifiable, Codable {
    case original, r16x9 = "16:9", r9x16 = "9:16", r1x1 = "1:1", r4x3 = "4:3", r4x5 = "4:5", r21x9 = "21:9"
    var id: String { rawValue }
    var label: String { self == .original ? t("ar.original") : rawValue }
    /// (寬, 高)
    var ratio: (Int, Int)? {
        switch self {
        case .original: return nil
        case .r16x9: return (16, 9)
        case .r9x16: return (9, 16)
        case .r1x1: return (1, 1)
        case .r4x3: return (4, 3)
        case .r4x5: return (4, 5)
        case .r21x9: return (21, 9)
        }
    }
}

/// 比例不同時，空出來的地方怎麼補
enum PadStyle: String, CaseIterable, Identifiable, Codable {
    case black, white, blur, coverBlur, crop
    var id: String { rawValue }
    var labelKey: String { "ar.fill.\(rawValue)" }
}

/// 影片解析度（0 = 最佳）
let videoHeights: [Int] = [0, 2160, 1440, 1080, 720, 480, 360]
/// 音訊位元率 kbps（0 = 最佳）
let audioBitrates: [Int] = [0, 320, 256, 192, 128]

struct DownloadOptions: Codable, Equatable {
    var kind: MediaKind = .video
    var container: VideoContainer = .mp4
    var maxHeight: Int = 1080
    var audioFormat: AudioFormat = .mp3
    var audioBitrate: Int = 320
    var embedThumbnail = true
    var subtitles = false
    var trimEnabled = false
    var trimStart: Double = 0
    var trimEnd: Double = 0
    /// 聲道、去人聲、音量、變速、升降 Key、淡入淡出
    var effects = AudioEffects()
    /// 畫質提升：0 = 關閉；1080 / 1440 / 2160（降噪 + Lanczos 放大 + 銳化，非 AI 還原）
    var upscaleHeight: Int = 0
    /// 輸出畫面比例與補邊方式
    var aspect: AspectRatio = .original
    var padStyle: PadStyle = .black

    /// 需要下載後再用 ffmpeg 處理一次
    var needsPostProcess: Bool { effects.isActive || (kind == .video && (upscaleHeight > 0 || aspect != .original)) }
}

// MARK: - 中繼資料（歌名、歌手…）

struct TrackMetadata: Codable, Equatable {
    var fileName = ""
    var title = ""
    var artist = ""
    var album = ""
    var albumArtist = ""
    var year = ""
    var genre = ""
}

// MARK: - yt-dlp 回傳的影片資訊（只取我們需要的欄位）

struct MediaInfo {
    var id: String
    var webpageURL: String
    var title: String
    var uploader: String
    var channel: String
    var duration: Double
    var viewCount: Int
    var thumbnail: URL?
    var isPlaylist: Bool
    var entries: [PlaylistTrack]
    /// 原始 JSON，下載時會把修改過的資訊寫回去再交給 yt-dlp（--load-info-json）
    var raw: [String: Any]

    /// 依 YouTube 提供的資訊產生預設的檔名與歌曲資訊
    var defaultMetadata: TrackMetadata {
        func s(_ k: String) -> String {
            if let v = raw[k] as? String { return v }
            if let v = raw[k] as? [String] { return v.joined(separator: ", ") }
            if let v = raw[k] as? Int { return String(v) }
            return ""
        }
        var m = TrackMetadata()
        m.title = s("track").isEmpty ? title : s("track")
        let artist = s("artist").isEmpty ? s("artists") : s("artist")
        m.artist = artist.isEmpty ? (s("creator").isEmpty ? channel.replacingOccurrences(of: " - Topic", with: "") : s("creator")) : artist
        m.album = s("album")
        m.albumArtist = s("album_artist")
        if !s("release_year").isEmpty { m.year = s("release_year") }
        else if s("upload_date").count >= 4 { m.year = String(s("upload_date").prefix(4)) }
        m.genre = s("genre").isEmpty ? s("genres") : s("genre")
        // 有歌手資訊（音樂影片）時用「歌手 - 歌名」，否則用 YouTube 原標題
        if !s("track").isEmpty && !artist.isEmpty {
            m.fileName = "\(artist) - \(s("track"))"
        } else {
            m.fileName = title
        }
        m.fileName = sanitizeFileName(m.fileName)
        return m
    }
}

/// 播放清單中的一首歌（來自 Spotify / Apple Music / YouTube 清單）
struct PlaylistTrack: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var artist: String
    var album: String = ""
    var durationSeconds: Double = 0
    /// 若已知直接的影片網址（YouTube 清單）就不需要搜尋
    var directURL: String? = nil
    var selected = true
}

func sanitizeFileName(_ s: String) -> String {
    let bad = CharacterSet(charactersIn: "/\\:*?\"<>|\n\r\t")
    let cleaned = s.components(separatedBy: bad).joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return String(cleaned.prefix(180))
}

func formatDuration(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "--:--" }
    let s = Int(seconds.rounded())
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
}
