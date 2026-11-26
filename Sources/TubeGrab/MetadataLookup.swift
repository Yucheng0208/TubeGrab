import Foundation

/// 從網路查詢歌曲資訊（Apple iTunes Search API，免費、免金鑰），提供給使用者參考後再套用
struct SongInfo: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var artist: String
    var album: String
    var year: String
    var genre: String
    var trackNumber: Int?
    var artwork: URL?
    var durationSeconds: Double
}

enum MetadataLookup {
    /// 依介面語言選擇商店地區（影響歌名語言與可找到的歌曲）
    static var storefront: String {
        switch AppSettings.shared.language.resolved {
        case .ja: return "JP"
        case .ko: return "KR"
        case .en: return "US"
        default: return "TW"
        }
    }

    /// 把 YouTube 標題整理成適合搜尋的字串：去掉【】、(Official Music Video)、MV、歌詞版…
    static func cleanQuery(title: String, artist: String) -> String {
        var s = title
        let noise = [#"(?i)official\s*(music\s*)?video"#, #"(?i)official\s*(audio|mv|lyric(s)?\s*video)"#,
                     #"(?i)\bm/?v\b"#, #"(?i)lyrics?"#, #"(?i)\b(hd|4k|hq)\b"#, "歌詞版", "動態歌詞", "完整版", "官方", "高音質",
                     #"(?i)\bfeat\.?\b.*$"#]
        for p in noise { s = s.replacingOccurrences(of: p, with: " ", options: .regularExpression) }
        // 括號符號變空白（保留裡面的歌名，例如「周杰倫【晴天】」）
        s = s.replacingOccurrences(of: #"[【】\[\]（）()「」『』《》|｜\-–—_]"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        let a = artist.replacingOccurrences(of: " - Topic", with: "")
        if !a.isEmpty, !s.localizedCaseInsensitiveContains(a) { s = a + " " + s }
        return String(s.prefix(100))
    }

    static func search(_ query: String, limit: Int = 6) async throws -> [SongInfo] {
        var c = URLComponents(string: "https://itunes.apple.com/search")!
        c.queryItems = [
            .init(name: "term", value: query),
            .init(name: "entity", value: "song"),
            .init(name: "limit", value: String(limit)),
            .init(name: "country", value: storefront),
        ]
        let (data, _) = try await URLSession.shared.data(from: c.url!)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else { return [] }
        var seen = Set<String>()
        return results.compactMap { r in
            guard let title = r["trackName"] as? String, let artist = r["artistName"] as? String else { return nil }
            let album = (r["collectionName"] as? String) ?? ""
            guard seen.insert("\(title)|\(artist)|\(album)").inserted else { return nil }
            let art = (r["artworkUrl100"] as? String)?.replacingOccurrences(of: "100x100", with: "600x600")
            return SongInfo(title: title, artist: artist, album: album,
                            year: String(((r["releaseDate"] as? String) ?? "").prefix(4)),
                            genre: (r["primaryGenreName"] as? String) ?? "",
                            trackNumber: r["trackNumber"] as? Int,
                            artwork: art.flatMap(URL.init(string:)),
                            durationSeconds: ((r["trackTimeMillis"] as? Double) ?? 0) / 1000)
        }
    }
}
