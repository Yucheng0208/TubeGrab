import Foundation

/// 歌詞：來自 LRCLIB（https://lrclib.net，免費、開放的歌詞資料庫，不需金鑰）
struct Lyrics: Equatable {
    var synced: String?     // LRC 格式：[mm:ss.xx]歌詞
    var plain: String?
    var trackName: String
    var artistName: String
    var albumName: String
    var duration: Double

    var hasAny: Bool { !(synced ?? "").isEmpty || !(plain ?? "").isEmpty }

    /// 純文字版（沒有純文字時把同步歌詞的時間標記去掉）
    var plainText: String {
        if let p = plain, !p.isEmpty { return p }
        return LyricsService.stripTimestamps(synced ?? "")
    }
}

/// 歌詞的繁簡轉換
enum LyricsScript: String, CaseIterable, Identifiable, Codable {
    case auto, keep, traditional, simplified
    var id: String { rawValue }
    var labelKey: String { "ly.script.\(rawValue)" }
}

/// 下載時的歌詞選項
struct LyricsOptions: Codable, Equatable {
    var enabled = false
    var saveLRC = true
    var embed = true
    var script: LyricsScript = .auto
}

enum LyricsService {
    private static let userAgent = "TubeGrab/1.0 (https://github.com/Yucheng0208/Tube-Grab)"

    // MARK: 查詢

    /// 依歌名、歌手（與長度）找歌詞；先精準比對，找不到再用搜尋挑最接近的
    static func find(title: String, artist: String, album: String = "", duration: Double = 0) async -> Lyrics? {
        let t = title.trimmingCharacters(in: .whitespaces)
        let a = artist.replacingOccurrences(of: " - Topic", with: "").trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }

        // 1. 精準比對（長度相差 2 秒內）
        if duration > 0, !a.isEmpty {
            var c = URLComponents(string: "https://lrclib.net/api/get")!
            c.queryItems = [.init(name: "track_name", value: t), .init(name: "artist_name", value: a),
                            .init(name: "duration", value: String(Int(duration.rounded())))]
            if !album.isEmpty { c.queryItems?.append(.init(name: "album_name", value: album)) }
            if let j = await getJSON(c.url!) as? [String: Any], let l = parse(j), l.hasAny { return l }
        }

        // 2. 搜尋：資料庫裡中文歌有的是繁體、有的是簡體，兩種都試；
        //    找到「歌手相符」的結果就停，避免發太多請求
        let tS = toSimplified(t), aS = toSimplified(a), tT = toTraditional(t), aT = toTraditional(a)
        var searches: [[URLQueryItem]] = []
        func add(_ items: [URLQueryItem]) {
            if !searches.contains(where: { $0 == items }) { searches.append(items) }
        }
        for (tt, aa) in [(t, a), (tS, aS), (tT, aT)] {
            var items = [URLQueryItem(name: "track_name", value: tt)]
            if !aa.isEmpty { items.append(.init(name: "artist_name", value: aa)) }
            add(items)
        }
        for q in fallbackQueries(title: t, artist: a) {
            add([.init(name: "q", value: q)])
            add([.init(name: "q", value: toSimplified(q))])
        }
        // 最後：只用歌名找，再用歌手過濾
        add([.init(name: "track_name", value: tS)])
        add([.init(name: "track_name", value: tT)])

        var all: [Lyrics] = []
        for items in searches {
            var u = URLComponents(string: "https://lrclib.net/api/search")!
            u.queryItems = items
            let found = ((await getJSON(u.url!) as? [[String: Any]]) ?? []).compactMap(parse).filter(\.hasAny)
            all += found
            if let best = pick(all, artist: a, duration: duration), artistMatches(best.artistName, a) {
                if duration <= 0 || abs(best.duration - duration) <= 8 { return best }
            }
        }
        return pick(all, artist: a, duration: duration, requireArtist: !a.isEmpty)
    }

    /// 從候選中挑最好的：歌手相符 → 有同步歌詞 → 長度最接近
    private static func pick(_ list: [Lyrics], artist: String, duration: Double, requireArtist: Bool = false) -> Lyrics? {
        let pool = requireArtist ? list.filter { artistMatches($0.artistName, artist) } : list
        return pool.min { l, r in
            let la = artistMatches(l.artistName, artist) ? 0 : 1, ra = artistMatches(r.artistName, artist) ? 0 : 1
            if la != ra { return la < ra }
            let ls = (l.synced ?? "").isEmpty ? 1 : 0, rs = (r.synced ?? "").isEmpty ? 1 : 0
            if ls != rs { return ls < rs }
            guard duration > 0 else { return false }
            return abs(l.duration - duration) < abs(r.duration - duration)
        }
    }

    /// 歌手是否相符（不分繁簡、大小寫、空白；多位歌手只要有一位相符）
    static func artistMatches(_ found: String, _ wanted: String) -> Bool {
        guard !wanted.isEmpty else { return true }
        func norm(_ s: String) -> String {
            toSimplified(s).lowercased().filter { !$0.isWhitespace && !$0.isPunctuation }
        }
        let f = norm(found)
        let parts = wanted.split(whereSeparator: { ",、&/;".contains($0) }).map { norm(String($0)) }.filter { !$0.isEmpty }
        return parts.contains { !f.isEmpty && (f.contains($0) || $0.contains(f)) }
    }

    static func toSimplified(_ s: String) -> String { s.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? s }
    static func toTraditional(_ s: String) -> String { s.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? s }

    /// 搜尋用的備用關鍵字：整理過的標題 →【】裡的歌名 → 只留中日韓文字 → 只留英文
    static func fallbackQueries(title: String, artist: String) -> [String] {
        var out: [String] = []
        func add(_ s: String) {
            let v = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
            if v.count >= 2, !out.contains(v) { out.append(v) }
        }
        let cleaned = MetadataLookup.cleanQuery(title: title, artist: artist)
        add(cleaned)
        // 【歌名】「歌名」《歌名》
        if let r = title.range(of: #"[【「《\[]([^】」》\]]+)[】」》\]]"#, options: .regularExpression) {
            let inner = String(title[r]).trimmingCharacters(in: CharacterSet(charactersIn: "【】「」《》[]"))
            add(artist + " " + inner)
            add(cjkOnly(artist + " " + inner))
        }
        add(cjkOnly(cleaned))
        add(latinOnly(cleaned))
        return out
    }

    private static func isCJK(_ c: Character) -> Bool {
        c.unicodeScalars.contains { (0x3040...0x30FF).contains($0.value) || (0x3400...0x9FFF).contains($0.value) || (0xAC00...0xD7AF).contains($0.value) }
    }
    private static func cjkOnly(_ s: String) -> String {
        guard s.contains(where: isCJK) else { return "" }
        return s.split(separator: " ").filter { $0.contains(where: isCJK) }.joined(separator: " ")
    }
    private static func latinOnly(_ s: String) -> String {
        s.split(separator: " ").filter { w in !w.contains(where: isCJK) && w.rangeOfCharacter(from: .letters) != nil }.joined(separator: " ")
    }

    private static func getJSON(_ url: URL) async -> Any? {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private static func parse(_ j: [String: Any]) -> Lyrics? {
        guard (j["instrumental"] as? Bool) != true else { return nil }
        return Lyrics(synced: j["syncedLyrics"] as? String, plain: j["plainLyrics"] as? String,
                      trackName: (j["trackName"] as? String) ?? "", artistName: (j["artistName"] as? String) ?? "",
                      albumName: (j["albumName"] as? String) ?? "", duration: (j["duration"] as? Double) ?? 0)
    }

    // MARK: 處理

    static func stripTimestamps(_ lrc: String) -> String {
        lrc.components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: #"^(\[\d{1,2}:\d{2}(?:[.:]\d{1,3})?\])+"#, with: "", options: .regularExpression) }
            .joined(separator: "\n")
    }

    /// 繁簡轉換；auto = 依介面語言（繁中 → 繁體、简中 → 简体，其他語言不轉）
    static func convert(_ text: String, _ script: LyricsScript) -> String {
        var target = script
        if script == .auto {
            switch AppSettings.shared.language.resolved {
            case .zhHant: target = .traditional
            case .zhHans: target = .simplified
            default: target = .keep
            }
        }
        switch target {
        case .traditional: return text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
        case .simplified: return text.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? text
        default: return text
        }
    }

    /// 修剪後：同步歌詞的時間往前移，並去掉範圍外的行
    static func shift(_ lrc: String, start: Double, length: Double) -> String {
        guard start > 0 || length > 0 else { return lrc }
        let re = try! NSRegularExpression(pattern: #"^\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\](.*)$"#)
        var out: [String] = []
        for line in lrc.components(separatedBy: .newlines) {
            let ns = line as NSString
            guard let m = re.firstMatch(in: line, range: NSRange(location: 0, length: ns.length)) else { continue }
            let mm = Double(ns.substring(with: m.range(at: 1))) ?? 0
            let ss = Double(ns.substring(with: m.range(at: 2))) ?? 0
            let fracStr = m.range(at: 3).location != NSNotFound ? ns.substring(with: m.range(at: 3)) : "0"
            let frac = (Double(fracStr) ?? 0) / pow(10, Double(fracStr.count))
            let t = mm * 60 + ss + frac - start
            if t < 0 || (length > 0 && t > length) { continue }
            let text = ns.substring(with: m.range(at: 4)).trimmingCharacters(in: .whitespaces)
            out.append(String(format: "[%02d:%05.2f]", Int(t) / 60, t.truncatingRemainder(dividingBy: 60)) + text)
        }
        return out.joined(separator: "\n")
    }

    // MARK: 寫入

    /// 下載完成後：存 .lrc 檔、寫入歌曲檔案
    static func apply(_ opts: LyricsOptions, to file: URL, metadata m: TrackMetadata, download o: DownloadOptions,
                      duration: Double) async -> Bool {
        let trimmed = o.trimEnabled && o.trimEnd > o.trimStart
        let length = trimmed ? o.trimEnd - o.trimStart : duration
        guard var l = await find(title: m.title, artist: m.artist, album: m.album, duration: trimmed ? 0 : duration) else {
            return false
        }
        if trimmed, let s = l.synced { l.synced = shift(s, start: o.trimStart, length: length) }
        let synced = l.synced.map { convert($0, opts.script) }
        let plain = convert(trimmed ? stripTimestamps(l.synced ?? "") : l.plainText, opts.script)

        if opts.saveLRC {
            var lrc = "[ti:\(m.title)]\n[ar:\(m.artist)]\n"
            if !m.album.isEmpty { lrc += "[al:\(m.album)]\n" }
            lrc += "[by:LRCLIB]\n"
            lrc += (synced?.isEmpty == false ? synced! : plain)
            try? lrc.write(to: file.deletingPathExtension().appendingPathExtension("lrc"), atomically: true, encoding: .utf8)
        }
        if opts.embed, !plain.isEmpty {
            await embed(plain, into: file)
        }
        return true
    }

    /// 把歌詞寫進檔案：MP3 用 ID3 的 USLT 欄位（Apple Music 讀得到），其他格式用 ffmpeg 寫 lyrics 標籤
    static func embed(_ text: String, into file: URL) async {
        let ext = file.pathExtension.lowercased()
        if ext == "mp3" {
            _ = ID3Lyrics.write(text, to: file)
            return
        }
        guard ["m4a", "mp4", "flac", "opus", "ogg", "mka", "mkv", "mov"].contains(ext) else { return }
        let tmp = file.deletingLastPathComponent().appendingPathComponent(".tubegrab-ly-\(UUID().uuidString).\(ext)")
        var args = ["-hide_banner", "-loglevel", "error", "-y", "-i", file.path, "-map", "0", "-c", "copy",
                    "-metadata", "lyrics=\(text)"]
        if ["opus", "ogg"].contains(ext) { args += ["-metadata:s:a:0", "lyrics=\(text)"] }
        args.append(tmp.path)
        if let r = try? await ProcessRunner.run(AppSettings.shared.ffmpegPath, args), r.status == 0 {
            _ = try? FileManager.default.replaceItemAt(file, withItemAt: tmp)
        } else {
            try? FileManager.default.removeItem(at: tmp)
        }
    }
}

/// 直接在 MP3 的 ID3v2 標籤裡加入 USLT（未同步歌詞）欄位。
/// ffmpeg 只能寫成自訂的 TXXX 欄位，Apple Music 不會讀，所以自己寫。
enum ID3Lyrics {
    static func write(_ lyrics: String, to file: URL, language: String = "zho") -> Bool {
        guard var data = try? Data(contentsOf: file), data.count > 10,
              data[0] == 0x49, data[1] == 0x44, data[2] == 0x33 else { return false }   // "ID3"
        let major = data[3]
        guard major == 3 || major == 4 else { return false }
        let flags = data[5]
        guard flags & 0x40 == 0 else { return false }   // 有擴充標頭時不處理
        let tagSize = syncsafe(data[6], data[7], data[8], data[9])
        guard 10 + tagSize <= data.count else { return false }
        let body = data.subdata(in: 10..<(10 + tagSize))

        // 收集既有的欄位（去掉舊的 USLT 與結尾的補零）
        var frames = Data()
        var pos = 0
        while pos + 10 <= body.count {
            let id = body.subdata(in: pos..<(pos + 4))
            if id.allSatisfy({ $0 == 0 }) { break }
            let size = major == 4
                ? syncsafe(body[pos + 4], body[pos + 5], body[pos + 6], body[pos + 7])
                : Int(body[pos + 4]) << 24 | Int(body[pos + 5]) << 16 | Int(body[pos + 6]) << 8 | Int(body[pos + 7])
            let end = pos + 10 + size
            guard size >= 0, end <= body.count else { break }
            if String(data: id, encoding: .ascii) != "USLT" { frames.append(body.subdata(in: pos..<end)) }
            pos = end
        }

        // USLT：編碼(1=UTF-16 含 BOM) + 語言(3) + 描述(空字串) + 歌詞
        var content = Data([0x01])
        content.append(language.data(using: .ascii)!.prefix(3))
        content.append(contentsOf: [0xFF, 0xFE, 0x00, 0x00])           // 空描述：BOM + 結尾 0x0000
        content.append(contentsOf: [0xFF, 0xFE])
        content.append(lyrics.data(using: .utf16LittleEndian)!)
        var frame = Data("USLT".utf8)
        let n = content.count
        frame.append(contentsOf: major == 4 ? toSyncsafe(n) : [UInt8(n >> 24 & 0xFF), UInt8(n >> 16 & 0xFF), UInt8(n >> 8 & 0xFF), UInt8(n & 0xFF)])
        frame.append(contentsOf: [0x00, 0x00])
        frame.append(content)
        frames.append(frame)
        frames.append(Data(count: 1024))   // 補零，之後再改標籤時不用整個檔案重寫

        var header = data.subdata(in: 0..<6)
        header.append(contentsOf: toSyncsafe(frames.count))
        let audio = data.subdata(in: (10 + tagSize)..<data.count)
        data = header + frames + audio
        return (try? data.write(to: file, options: .atomic)) != nil
    }

    private static func syncsafe(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) -> Int {
        Int(a & 0x7F) << 21 | Int(b & 0x7F) << 14 | Int(c & 0x7F) << 7 | Int(d & 0x7F)
    }
    private static func toSyncsafe(_ n: Int) -> [UInt8] {
        [UInt8(n >> 21 & 0x7F), UInt8(n >> 14 & 0x7F), UInt8(n >> 7 & 0x7F), UInt8(n & 0x7F)]
    }
}
