import Foundation

/// 匯入歌單檔案：TXT（每行一首）、CSV、XLSX（Excel / Numbers 匯出）
/// CSV / XLSX 會自動找「歌名 / 歌手 / 專輯 / 長度」欄位（中英文欄名都可以，例如 Spotify 匯出的 Track Name、Artist Name(s)）
enum PlaylistFileImporter {
    static let supportedExtensions = ["txt", "csv", "tsv", "xlsx"]

    static func load(_ url: URL) throws -> [PlaylistTrack] {
        switch url.pathExtension.lowercased() {
        case "xlsx": return fromRows(try XLSXReader.rows(of: url))
        case "csv": return fromRows(CSV.parse(try readText(url), separator: ","))
        case "tsv": return fromRows(CSV.parse(try readText(url), separator: "\t"))
        default:
            let text = try readText(url)
            // 有些 .txt 其實是 Tab 分隔的表格
            if text.contains("\t") && headerColumns(CSV.parse(text, separator: "\t").first ?? []) != nil {
                return fromRows(CSV.parse(text, separator: "\t"))
            }
            return PlaylistImporter.parseTextList(text)
        }
    }

    /// 讀文字檔（UTF-8、含 BOM、UTF-16、Big5 / GB18030 都試）
    static func readText(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        for enc: String.Encoding in [.utf8, .utf16] {
            if let s = String(data: data, encoding: enc) { return s.replacingOccurrences(of: "\u{FEFF}", with: "") }
        }
        let big5 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.big5.rawValue)))
        let gb = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        for enc in [big5, gb] { if let s = String(data: data, encoding: enc) { return s } }
        throw ToolError(message: t("imp.badFile"))
    }

    // MARK: 表格 → 歌曲

    private static let titleNames = ["歌名", "歌曲", "曲名", "標題", "标题", "名稱", "名称", "title", "song", "track", "track name", "name", "曲", "곡명", "제목"]
    private static let artistNames = ["歌手", "演出者", "藝人", "艺人", "演唱", "artist", "artists", "artist name", "artist name(s)", "singer", "アーティスト", "가수", "아티스트"]
    private static let albumNames = ["專輯", "专辑", "album", "album name", "アルバム", "앨범"]
    private static let durationNames = ["長度", "时长", "時長", "duration", "time", "length", "duration (ms)", "track duration (ms)"]

    /// 找表頭欄位位置
    static func headerColumns(_ header: [String]) -> (title: Int, artist: Int?, album: Int?, duration: Int?, durationMS: Bool)? {
        let h = header.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        func find(_ names: [String]) -> Int? {
            h.firstIndex { cell in names.contains(cell) } ?? h.firstIndex { cell in names.contains { !$0.isEmpty && cell.contains($0) } }
        }
        guard let ti = find(titleNames) else { return nil }
        var ai = find(artistNames)
        if ai == ti { ai = nil }
        let di = find(durationNames)
        return (ti, ai, find(albumNames), di, di.map { h[$0].contains("ms") } ?? false)
    }

    static func fromRows(_ rows: [[String]]) -> [PlaylistTrack] {
        let rows = rows.filter { $0.contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty } }
        guard let first = rows.first else { return [] }
        if let cols = headerColumns(first) {
            return rows.dropFirst().compactMap { r in
                func cell(_ i: Int?) -> String { guard let i, i < r.count else { return "" }; return r[i].trimmingCharacters(in: .whitespaces) }
                let title = cell(cols.title)
                guard !title.isEmpty else { return nil }
                var artist = cell(cols.artist)
                // Spotify 匯出的多位歌手用逗號或分號分隔，只留前兩位
                artist = artist.split(whereSeparator: { $0 == ";" || $0 == "," }).prefix(2)
                    .map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", ")
                return PlaylistTrack(title: title, artist: artist, album: cell(cols.album),
                                     durationSeconds: parseDuration(cell(cols.duration), ms: cols.durationMS))
            }
        }
        // 沒有表頭：兩欄當「歌名、歌手」，一欄就交給文字解析
        if first.count >= 2 {
            return rows.compactMap { r in
                let title = r[0].trimmingCharacters(in: .whitespaces)
                guard !title.isEmpty else { return nil }
                return PlaylistTrack(title: title, artist: r.count > 1 ? r[1].trimmingCharacters(in: .whitespaces) : "",
                                     album: r.count > 2 ? r[2].trimmingCharacters(in: .whitespaces) : "")
            }
        }
        return PlaylistImporter.parseTextList(rows.map { $0.first ?? "" }.joined(separator: "\n"))
    }

    /// "3:45"、"225"、"225000"(ms) → 秒
    static func parseDuration(_ s: String, ms: Bool) -> Double {
        guard !s.isEmpty else { return 0 }
        if s.contains(":") {
            let parts = s.split(separator: ":").compactMap { Double($0) }
            return parts.reduce(0) { $0 * 60 + $1 }
        }
        guard let v = Double(s) else { return 0 }
        return ms || v > 10_000 ? v / 1000 : v
    }
}

/// 簡單的 CSV 解析（支援引號、引號內的逗號與換行、"" 跳脫）
enum CSV {
    static func parse(_ text: String, separator: Character) -> [[String]] {
        var rows: [[String]] = [], row: [String] = [], field = ""
        var inQuotes = false
        var it = Array(text).makeIterator()
        var pending: Character? = nil
        func next() -> Character? { if let p = pending { pending = nil; return p }; return it.next() }
        while let c = next() {
            if inQuotes {
                if c == "\"" {
                    if let n = next() {
                        if n == "\"" { field.append("\"") } else { inQuotes = false; pending = n }
                    } else { inQuotes = false }
                } else { field.append(c) }
            } else if c == "\"" {
                inQuotes = true
            } else if c == separator {
                row.append(field); field = ""
            } else if c == "\n" || c == "\r\n" || c == "\r" {
                row.append(field); rows.append(row); row = []; field = ""
            } else {
                field.append(c)
            }
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}

/// 讀 .xlsx 的第一個工作表（.xlsx 其實是 zip 包著 XML）
enum XLSXReader {
    static func rows(of url: URL) throws -> [[String]] {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("tubegrab-xlsx-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = ["-x", "-k", url.path, dir.path]
        try p.run(); p.waitUntilExit()
        guard p.terminationStatus == 0 else { throw ToolError(message: t("imp.badFile")) }

        let shared = (try? Data(contentsOf: dir.appendingPathComponent("xl/sharedStrings.xml"))).map(SharedStrings.parse) ?? []
        let sheetsDir = dir.appendingPathComponent("xl/worksheets")
        let sheets = ((try? FileManager.default.contentsOfDirectory(atPath: sheetsDir.path)) ?? [])
            .filter { $0.hasPrefix("sheet") && $0.hasSuffix(".xml") }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        guard let first = sheets.first, let data = try? Data(contentsOf: sheetsDir.appendingPathComponent(first)) else {
            throw ToolError(message: t("imp.badFile"))
        }
        return Sheet.parse(data, shared: shared)
    }

    private final class SharedStrings: NSObject, XMLParserDelegate {
        var items: [String] = []
        private var current = "", inSI = false, inT = false
        static func parse(_ d: Data) -> [String] {
            let x = SharedStrings(); let p = XMLParser(data: d); p.delegate = x; p.parse(); return x.items
        }
        func parser(_ p: XMLParser, didStartElement e: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
            if e == "si" { inSI = true; current = "" } else if e == "t" && inSI { inT = true }
        }
        func parser(_ p: XMLParser, foundCharacters s: String) { if inT { current += s } }
        func parser(_ p: XMLParser, didEndElement e: String, namespaceURI: String?, qualifiedName: String?) {
            if e == "t" { inT = false } else if e == "si" { items.append(current); inSI = false }
        }
    }

    private final class Sheet: NSObject, XMLParserDelegate {
        var rows: [[String]] = []
        let shared: [String]
        private var row: [Int: String] = [:], col = 0, type = "", value = "", inV = false, inIS = false
        init(shared: [String]) { self.shared = shared }
        static func parse(_ d: Data, shared: [String]) -> [[String]] {
            let x = Sheet(shared: shared); let p = XMLParser(data: d); p.delegate = x; p.parse(); return x.rows
        }
        /// "C12" → 欄位 2
        private func column(_ ref: String) -> Int {
            ref.prefix { $0.isLetter }.uppercased().unicodeScalars.reduce(0) { $0 * 26 + Int($1.value) - 64 } - 1
        }
        func parser(_ p: XMLParser, didStartElement e: String, namespaceURI: String?, qualifiedName: String?, attributes a: [String: String] = [:]) {
            switch e {
            case "row": row = [:]
            case "c": col = a["r"].map(column) ?? (row.keys.max() ?? -1) + 1; type = a["t"] ?? ""; value = ""
            case "v": inV = true
            case "is": inIS = true
            case "t": if inIS { inV = true }
            default: break
            }
        }
        func parser(_ p: XMLParser, foundCharacters s: String) { if inV { value += s } }
        func parser(_ p: XMLParser, didEndElement e: String, namespaceURI: String?, qualifiedName: String?) {
            switch e {
            case "v", "t": inV = false
            case "is": inIS = false
            case "c":
                var v = value
                if type == "s", let i = Int(value), i < shared.count { v = shared[i] }
                if type == "b" { v = value == "1" ? "TRUE" : "FALSE" }
                row[col] = v
            case "row":
                let n = (row.keys.max() ?? -1) + 1
                rows.append((0..<n).map { row[$0] ?? "" })
            default: break
            }
        }
    }
}
