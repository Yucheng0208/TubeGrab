import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 找譜：用瀏覽器打開常見樂譜網站的搜尋結果（只開網頁，不下載樂譜）
enum ScoreFinder {
    struct Site: Identifiable {
        let id: String
        let titleKey: String
        let icon: String
        let url: (String) -> URL?
    }

    private static func enc(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&+="))) ?? s
    }
    private static func google(_ q: String) -> URL? { URL(string: "https://www.google.com/search?q=" + enc(q)) }

    static let sites: [Site] = [
        Site(id: "ug", titleKey: "score.guitar", icon: "guitars") {
            URL(string: "https://www.ultimate-guitar.com/search.php?search_type=title&value=" + enc($0))
        },
        Site(id: "91pu", titleKey: "score.91pu", icon: "music.note.list") { google($0 + " site:91pu.com.tw") },
        Site(id: "musescore", titleKey: "score.staff", icon: "music.quarternote.3") {
            URL(string: "https://musescore.com/sheetmusic?text=" + enc($0))
        },
        Site(id: "jianpu", titleKey: "score.jianpu", icon: "number") { google($0 + " 簡譜") },
        Site(id: "piano", titleKey: "score.piano", icon: "pianokeys") { google($0 + " 鋼琴譜 piano sheet") },
    ]

    static func query(title: String, artist: String) -> String {
        [artist.replacingOccurrences(of: " - Topic", with: ""), title].filter { !$0.isEmpty }.joined(separator: " ")
    }

    static func open(_ site: Site, title: String, artist: String) {
        if let u = site.url(query(title: title, artist: artist)) { NSWorkspace.shared.open(u) }
    }
}

/// 「找譜」選單
struct ScoreMenu: View {
    var title: String
    var artist: String
    var body: some View {
        Menu {
            ForEach(ScoreFinder.sites) { site in
                Button { ScoreFinder.open(site, title: title, artist: artist) } label: {
                    Label(t(site.titleKey), systemImage: site.icon)
                }
            }
        } label: {
            Label(t("score.find"), systemImage: "music.note.house")
        }
        .menuStyle(.button)
        .fixedSize()
        .disabled(title.isEmpty)
        .help(t("score.hint"))
    }
}

/// 歌詞匯出：複製、存成 .lrc（同步）或 .txt（純文字）
enum LyricsExporter {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    @MainActor
    static func save(_ text: String, suggestedName: String, ext: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = sanitizeFileName(suggestedName) + "." + ext
        panel.allowedContentTypes = [UTType(filenameExtension: ext) ?? .plainText]
        panel.directoryURL = AppSettings.shared.outputFolder
        if panel.runModal() == .OK, let u = panel.url {
            try? text.write(to: u, atomically: true, encoding: .utf8)
            NSWorkspace.shared.activateFileViewerSelecting([u])
        }
    }

    /// 帶標題資訊的 .lrc 內容
    static func lrc(_ l: Lyrics, title: String, artist: String, album: String, script: LyricsScript = .auto) -> String {
        var s = "[ti:\(title)]\n[ar:\(artist)]\n"
        if !album.isEmpty { s += "[al:\(album)]\n" }
        s += "[by:LRCLIB]\n"
        s += LyricsService.convert(l.synced?.isEmpty == false ? l.synced! : l.plainText, script)
        return s
    }

    /// 純文字（標題 + 完整歌詞）
    static func txt(_ l: Lyrics, title: String, artist: String, script: LyricsScript = .auto) -> String {
        "\(title) - \(artist)\n\n" + LyricsService.convert(l.plainText, script)
    }
}
