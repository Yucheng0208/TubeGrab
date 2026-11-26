import Foundation

/// 讀取 Spotify / Apple Music 公開清單或專輯的歌曲列表
enum PlaylistImporter {
    enum Source { case spotify, appleMusic, kkbox }

    static func source(of url: String) -> Source? {
        guard let host = URL(string: url)?.host?.lowercased() else { return nil }
        if host.contains("spotify.com") { return .spotify }
        if host.contains("music.apple.com") { return .appleMusic }
        if host.contains("kkbox.com") || host.contains("kkbox.fm") { return .kkbox }
        return nil
    }

    static func importTracks(_ url: String) async throws -> (name: String, tracks: [PlaylistTrack]) {
        switch source(of: url) {
        case .spotify: return try await spotify(url)
        case .appleMusic: return try await appleMusic(url)
        case .kkbox: return try await kkbox(url)
        case nil: throw ToolError(message: t("err.badURL"))
        }
    }

    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    private static func fetchHTML(_ url: URL) async throws -> String {
        var req = URLRequest(url: url)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("zh-TW,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        let (data, _) = try await URLSession.shared.data(for: req)
        return String(decoding: data, as: UTF8.self)
    }

    private static func scriptJSON(id: String, in html: String) -> Any? {
        let pattern = "<script[^>]*id=\"\(id)\"[^>]*>(.*?)</script>"
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
              let m = re.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let r = Range(m.range(at: 1), in: html) else { return nil }
        return try? JSONSerialization.jsonObject(with: Data(html[r].utf8))
    }

    /// 遞迴走訪 JSON，找出符合條件的物件
    private static func collect(_ obj: Any, where match: ([String: Any]) -> Bool, into out: inout [[String: Any]]) {
        if let d = obj as? [String: Any] {
            if match(d) { out.append(d) }
            for v in d.values { collect(v, where: match, into: &out) }
        } else if let a = obj as? [Any] {
            for v in a { collect(v, where: match, into: &out) }
        }
    }

    // MARK: Spotify

    /// 解析 open.spotify.com/playlist/{id} 或 /album/{id}
    private static func spotifyID(_ url: String) -> (kind: String, id: String)? {
        guard let comps = URL(string: url)?.pathComponents else { return nil }
        // 可能是 /intl-zh/playlist/xxx 這種格式
        for kind in ["playlist", "album", "track"] {
            if let i = comps.firstIndex(of: kind), i + 1 < comps.count { return (kind, comps[i + 1]) }
        }
        return nil
    }

    private static func spotify(_ url: String) async throws -> (String, [PlaylistTrack]) {
        guard let (kind, id) = spotifyID(url) else { throw ToolError(message: t("err.badURL")) }
        let s = AppSettings.shared
        // 有填 API 金鑰就用官方 API（可讀完整清單）
        if !s.spotifyClientID.isEmpty, !s.spotifyClientSecret.isEmpty,
           let r = try? await spotifyAPI(kind: kind, id: id, clientID: s.spotifyClientID, secret: s.spotifyClientSecret),
           !r.1.isEmpty {
            return r
        }
        // 否則讀公開的嵌入頁面（不需帳號，但最多約 50~100 首）
        let html = try await fetchHTML(URL(string: "https://open.spotify.com/embed/\(kind)/\(id)")!)
        guard let root = scriptJSON(id: "__NEXT_DATA__", in: html) else { throw ToolError(message: t("err.noTracks")) }
        var entities: [[String: Any]] = []
        collect(root, where: { $0["trackList"] != nil }, into: &entities)
        guard let entity = entities.first else { throw ToolError(message: t("err.noTracks")) }
        let name = (entity["name"] as? String) ?? (entity["title"] as? String) ?? "Spotify"
        let albumName = kind == "album" ? name : ""
        let list = (entity["trackList"] as? [[String: Any]]) ?? []
        let tracks = list.compactMap { t -> PlaylistTrack? in
            guard let title = t["title"] as? String else { return nil }
            return PlaylistTrack(title: title, artist: (t["subtitle"] as? String) ?? "",
                                 album: albumName,
                                 durationSeconds: ((t["duration"] as? Double) ?? 0) / 1000)
        }
        return (name, tracks)
    }

    private static func spotifyAPI(kind: String, id: String, clientID: String, secret: String) async throws -> (String, [PlaylistTrack]) {
        // 1. Client Credentials 取得 token
        var tokenReq = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        tokenReq.httpMethod = "POST"
        let basic = Data("\(clientID):\(secret)".utf8).base64EncodedString()
        tokenReq.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        tokenReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        tokenReq.httpBody = Data("grant_type=client_credentials".utf8)
        let (td, _) = try await URLSession.shared.data(for: tokenReq)
        guard let tj = try JSONSerialization.jsonObject(with: td) as? [String: Any],
              let token = tj["access_token"] as? String else { throw ToolError(message: "Spotify token error") }

        func get(_ u: String) async throws -> [String: Any] {
            var r = URLRequest(url: URL(string: u)!)
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (d, _) = try await URLSession.shared.data(for: r)
            return (try JSONSerialization.jsonObject(with: d) as? [String: Any]) ?? [:]
        }

        let base = try await get("https://api.spotify.com/v1/\(kind)s/\(id)")
        let name = (base["name"] as? String) ?? "Spotify"
        var tracks: [PlaylistTrack] = []
        var page = base["tracks"] as? [String: Any]
        while let p = page {
            for item in (p["items"] as? [[String: Any]]) ?? [] {
                // 播放清單的項目包一層 track；專輯直接是 track
                let tr = (item["track"] as? [String: Any]) ?? item
                guard let title = tr["name"] as? String else { continue }
                let artists = ((tr["artists"] as? [[String: Any]]) ?? []).compactMap { $0["name"] as? String }
                let album = ((tr["album"] as? [String: Any])?["name"] as? String) ?? (kind == "album" ? name : "")
                tracks.append(PlaylistTrack(title: title, artist: artists.joined(separator: ", "), album: album,
                                            durationSeconds: ((tr["duration_ms"] as? Double) ?? 0) / 1000))
            }
            if let next = p["next"] as? String { page = try await get(next) } else { page = nil }
        }
        return (name, tracks)
    }

    // MARK: KKBOX（官方 Open API，需要在設定填入 Client ID / Secret）

    private static func kkbox(_ url: String) async throws -> (String, [PlaylistTrack]) {
        let s = AppSettings.shared
        guard !s.kkboxClientID.isEmpty, !s.kkboxClientSecret.isEmpty else {
            throw ToolError(message: t("err.kkboxKey"))
        }
        guard let comps = URL(string: url)?.pathComponents else { throw ToolError(message: t("err.badURL")) }
        var kind = "", id = ""
        for k in ["playlist", "album"] {
            if let i = comps.firstIndex(of: k), i + 1 < comps.count { kind = k; id = comps[i + 1] }
        }
        guard !id.isEmpty else { throw ToolError(message: t("err.badURL")) }
        // 網址中的地區（tw / hk / sg / my / jp）
        let territory = (comps.count > 1 && comps[1].count == 2) ? comps[1].uppercased() : "TW"

        var tokenReq = URLRequest(url: URL(string: "https://account.kkbox.com/oauth2/token")!)
        tokenReq.httpMethod = "POST"
        tokenReq.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "grant_type=client_credentials&client_id=\(s.kkboxClientID)&client_secret=\(s.kkboxClientSecret)"
        tokenReq.httpBody = Data(body.utf8)
        let (td, _) = try await URLSession.shared.data(for: tokenReq)
        guard let tj = try JSONSerialization.jsonObject(with: td) as? [String: Any],
              let token = tj["access_token"] as? String else { throw ToolError(message: "KKBOX token error") }

        func get(_ u: String) async throws -> [String: Any] {
            var r = URLRequest(url: URL(string: u)!)
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (d, _) = try await URLSession.shared.data(for: r)
            return (try JSONSerialization.jsonObject(with: d) as? [String: Any]) ?? [:]
        }

        let base = kind == "album" ? "albums" : "shared-playlists"
        let info = try await get("https://api.kkbox.com/v1.1/\(base)/\(id)?territory=\(territory)")
        let name = (info["title"] as? String) ?? (info["name"] as? String) ?? "KKBOX"
        var tracks: [PlaylistTrack] = []
        var next: String? = "https://api.kkbox.com/v1.1/\(base)/\(id)/tracks?territory=\(territory)&limit=500"
        while let n = next {
            let page = try await get(n)
            for tr in (page["data"] as? [[String: Any]]) ?? [] {
                guard let title = tr["name"] as? String else { continue }
                let album = tr["album"] as? [String: Any]
                let artist = ((album?["artist"] as? [String: Any])?["name"] as? String) ?? ""
                tracks.append(PlaylistTrack(title: title, artist: artist,
                                            album: (album?["name"] as? String) ?? (kind == "album" ? name : ""),
                                            durationSeconds: ((tr["duration"] as? Double) ?? 0) / 1000))
            }
            next = (page["paging"] as? [String: Any])?["next"] as? String
        }
        return (name, tracks)
    }

    // MARK: 貼上的文字歌單（任何平台複製出來的清單都可以）

    /// 每行一首，支援「歌手 - 歌名」「歌名 / 歌手」「1. 歌名 - 歌手」、Tab 分隔（從試算表複製）等格式
    static func parseTextList(_ text: String) -> [PlaylistTrack] {
        let separators = [" - ", " – ", " — ", "\t", " / ", "／", " | "]
        var out: [PlaylistTrack] = []
        for raw in text.components(separatedBy: .newlines) {
            var line = raw.trimmingCharacters(in: .whitespaces)
            // 去掉開頭的編號：「1.」「01 」「3)」「#4」
            if let r = line.range(of: #"^#?\d{1,4}[\.\)、:：\s]+"#, options: .regularExpression) {
                line = String(line[r.upperBound...])
            }
            // 去掉結尾的時間長度「3:45」
            if let r = line.range(of: #"\s+\d{1,2}:\d{2}$"#, options: .regularExpression) {
                line = String(line[..<r.lowerBound])
            }
            line = line.trimmingCharacters(in: .whitespaces)
            guard line.count >= 2, normalizeURL(line) == nil || line.contains(" ") else { continue }
            var artist = "", title = line
            for sep in separators {
                let parts = line.components(separatedBy: sep).map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2, !parts[0].isEmpty, !parts[1].isEmpty {
                    // 預設「歌手 - 歌名」；Tab / 斜線格式通常是「歌名 / 歌手」
                    if sep == " - " || sep == " – " || sep == " — " { artist = parts[0]; title = parts[1...].joined(separator: " - ") }
                    else { title = parts[0]; artist = parts[1] }
                    break
                }
            }
            out.append(PlaylistTrack(title: title, artist: artist))
        }
        return out
    }

    // MARK: Apple Music

    private static func appleMusic(_ url: String) async throws -> (String, [PlaylistTrack]) {
        guard let u = URL(string: url) else { throw ToolError(message: t("err.badURL")) }
        let html = try await fetchHTML(u)
        guard let root = scriptJSON(id: "serialized-server-data", in: html) else { throw ToolError(message: t("err.noTracks")) }
        var items: [[String: Any]] = []
        collect(root, where: { $0["title"] is String && $0["artistName"] is String }, into: &items)

        var seen = Set<String>()
        var tracks: [PlaylistTrack] = []
        let isAlbum = u.path.contains("/album/")
        let pageTitle = ogTitle(html) ?? "Apple Music"
        for it in items {
            let title = it["title"] as! String
            let artist = it["artistName"] as! String
            let key = (it["id"] as? String) ?? "\(title)|\(artist)"
            guard seen.insert(key).inserted else { continue }
            let album = ((it["tertiaryLinks"] as? [[String: Any]])?.first?["title"] as? String) ?? (isAlbum ? pageTitle : "")
            tracks.append(PlaylistTrack(title: title, artist: artist, album: album,
                                        durationSeconds: ((it["duration"] as? Double) ?? 0) / 1000))
        }
        return (pageTitle, tracks)
    }

    private static func ogTitle(_ html: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: "<meta property=\"og:title\" content=\"([^\"]*)\""),
              let m = re.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let r = Range(m.range(at: 1), in: html) else { return nil }
        return String(html[r])
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }
}

/// 從 YouTube 搜尋結果中挑出最適合的影片：
/// 1. 優先：唱片公司 / 官方來源（「- Topic」自動頻道、VEVO、知名唱片公司、歌手官方頻道）
/// 2. 都沒有時：觀看次數最高的一支
enum TrackMatcher {
    static let labelKeywords = [
        "vevo", "records", "music", "entertainment", "sony", "universal", "warner", "emi", "avex",
        "hybe", "smtown", "jyp", "yg ", "starship", "kakao", "stone music", "genie", "1thek",
        "華納", "环球", "環球", "索尼", "滾石", "滚石", "相信音樂", "相信音乐", "華研", "华研",
        "金牌大風", "杰威爾", "杰威尔", "種子音樂", "種子音乐", "aniplex", "ponycanyon", "pony canyon",
        "king records", "victor", "lantis", "toho", "official"
    ]
    static let badWords = ["cover", "karaoke", "伴奏", "翻唱", "reaction", "remix", "8d", "sped up",
                           "slowed", "nightcore", "instrumental", "lyrics video", "1 hour", "1小時", "教學", "tutorial"]

    /// 搜尋結果是否來自唱片公司 / 官方頻道（給搜尋清單標示「官方」）
    static func isOfficial(_ r: YTDLP.SearchResult) -> Bool {
        let ch = r.channel.lowercased()
        return ch.hasSuffix(" - topic") || ch.contains("vevo")
            || labelKeywords.contains(where: { ch.contains($0) })
            || r.title.lowercased().contains("official") || r.title.contains("官方")
    }

    /// 關鍵字搜尋的推薦：官方來源中觀看次數最高者；沒有官方就選觀看次數最高
    static func recommend(_ results: [YTDLP.SearchResult]) -> YTDLP.SearchResult? {
        let clean = results.filter { r in !badWords.contains(where: { r.title.lowercased().contains($0) }) }
        let pool = clean.isEmpty ? results : clean
        let official = pool.filter(isOfficial)
        return (official.isEmpty ? pool : official).max(by: { $0.viewCount < $1.viewCount })
    }

    static func normalize(_ s: String) -> String {
        s.lowercased().folding(options: [.diacriticInsensitive, .widthInsensitive], locale: nil)
            .filter { !$0.isWhitespace && !$0.isPunctuation }
    }

    static func pick(_ results: [YTDLP.SearchResult], for track: PlaylistTrack) -> YTDLP.SearchResult? {
        guard !results.isEmpty else { return nil }
        let wantedTitle = normalize(track.title)
        let firstArtist = track.artist.split(separator: ",").first.map(String.init) ?? track.artist
        let wantedArtist = normalize(firstArtist)
        let queryLower = (track.title + " " + track.artist).lowercased()

        func isBad(_ r: YTDLP.SearchResult) -> Bool {
            let t = r.title.lowercased()
            if badWords.contains(where: { t.contains($0) && !queryLower.contains($0) }) { return true }
            // 長度差太多（例如 1 小時合輯）
            if track.durationSeconds > 0, r.duration > 0, abs(r.duration - track.durationSeconds) > 45 { return true }
            return false
        }

        func officialScore(_ r: YTDLP.SearchResult) -> Int {
            let ch = r.channel.lowercased()
            let nch = normalize(r.channel)
            var s = 0
            if ch.hasSuffix(" - topic") { s += 100 }               // YouTube 依唱片公司發行資料自動產生的頻道
            if ch.contains("vevo") { s += 90 }
            if labelKeywords.contains(where: { ch.contains($0) }) { s += 70 }
            if !wantedArtist.isEmpty && (nch.contains(wantedArtist) || wantedArtist.contains(nch)) && !nch.isEmpty { s += 70 }
            if r.verified { s += 10 }
            // 標題要包含歌名才算數
            if !wantedTitle.isEmpty && !normalize(r.title).contains(wantedTitle) { s -= 80 }
            if track.durationSeconds > 0, r.duration > 0, abs(r.duration - track.durationSeconds) <= 8 { s += 15 }
            return s
        }

        let candidates = results.filter { !isBad($0) }
        let pool = candidates.isEmpty ? results : candidates
        // 分數相同時取觀看次數較高者
        if let best = pool.max(by: { (officialScore($0), $0.viewCount) < (officialScore($1), $1.viewCount) }),
           officialScore(best) >= 70 {
            return best
        }
        return pool.max(by: { $0.viewCount < $1.viewCount })
    }
}
