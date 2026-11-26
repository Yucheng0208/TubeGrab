import Foundation

/// 所有和 yt-dlp 溝通的功能都在這裡
enum YTDLP {
    static var exe: String { AppSettings.shared.ytdlpPath }
    static var ffmpeg: String { AppSettings.shared.ffmpegPath }

    private static var commonArgs: [String] {
        var a = ["--no-warnings"]
        if !ffmpeg.isEmpty { a += ["--ffmpeg-location", ffmpeg] }
        return a
    }

    // MARK: 讀取影片 / 清單資訊

    static func fetchInfo(_ url: String, singleVideo: Bool = false) async throws -> MediaInfo {
        var args = commonArgs + ["-J"]
        // 「watch?v=…&list=RD…」是 YouTube 自動產生的合輯（無限延伸），當成單一影片處理；
        // 一般播放清單（list=PL… / OLAK… 專輯）則整份讀取
        let comps = URLComponents(string: url)
        let list = comps?.queryItems?.first(where: { $0.name == "list" })?.value ?? ""
        let hasVideo = comps?.queryItems?.contains(where: { $0.name == "v" }) ?? false
        let isMix = list.hasPrefix("RD") || list.hasPrefix("UL")
        if singleVideo || (hasVideo && isMix) {
            args += ["--no-playlist"]
        } else {
            args += ["--flat-playlist", "--yes-playlist"]
        }
        args.append(url)
        let r = try await ProcessRunner.run(exe, args)
        guard r.status == 0, let data = r.stdout.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ToolError(message: lastErrorLine(r.stderr))
        }
        return parseInfo(json)
    }

    static func parseInfo(_ j: [String: Any]) -> MediaInfo {
        let isPlaylist = (j["_type"] as? String) == "playlist"
        var entries: [PlaylistTrack] = []
        if isPlaylist, let es = j["entries"] as? [[String: Any]] {
            for e in es {
                let url = (e["url"] as? String) ?? (e["webpage_url"] as? String)
                let title = (e["title"] as? String) ?? "?"
                let channel = (e["channel"] as? String) ?? (e["uploader"] as? String) ?? ""
                entries.append(PlaylistTrack(title: title, artist: channel.replacingOccurrences(of: " - Topic", with: ""),
                                             durationSeconds: (e["duration"] as? Double) ?? 0, directURL: url))
            }
        }
        let thumb = (j["thumbnail"] as? String) ?? ((j["thumbnails"] as? [[String: Any]])?.last?["url"] as? String)
        return MediaInfo(
            id: (j["id"] as? String) ?? UUID().uuidString,
            webpageURL: (j["webpage_url"] as? String) ?? (j["original_url"] as? String) ?? "",
            title: (j["title"] as? String) ?? "",
            uploader: (j["uploader"] as? String) ?? "",
            channel: (j["channel"] as? String) ?? (j["uploader"] as? String) ?? "",
            duration: (j["duration"] as? Double) ?? 0,
            viewCount: (j["view_count"] as? Int) ?? 0,
            thumbnail: thumb.flatMap(URL.init(string:)),
            isPlaylist: isPlaylist,
            entries: entries,
            raw: j)
    }

    // MARK: 預覽用串流網址（給 AVPlayer 播放）

    /// 先從已取得的資訊找可直接播放的網址：
    /// 1. YouTube 的 HLS 主清單（AVPlayer 原生支援，含影音）
    /// 2. 其他網站的「影音合一」mp4
    static func previewURL(fromInfo raw: [String: Any]) -> URL? {
        let formats = (raw["formats"] as? [[String: Any]]) ?? []
        if let m = formats.compactMap({ $0["manifest_url"] as? String }).first(where: { $0.contains("m3u8") || $0.contains("hls") }) {
            return URL(string: m)
        }
        let muxed = formats.filter {
            ($0["vcodec"] as? String ?? "none") != "none" && ($0["acodec"] as? String ?? "none") != "none"
                && ["mp4", "mov", "m4v"].contains($0["ext"] as? String ?? "")
                && !(($0["protocol"] as? String) ?? "").contains("dash")
        }
        if let best = muxed.max(by: { ($0["height"] as? Int ?? 0) < ($1["height"] as? Int ?? 0) }),
           let u = best["url"] as? String { return URL(string: u) }
        return nil
    }

    static func previewStreamURL(_ url: String) async throws -> URL {
        let args = commonArgs + ["--no-playlist", "-g", "-f", "b[ext=mp4][height<=720]/b[ext=mp4]/b", url]
        let r = try await ProcessRunner.run(exe, args)
        guard r.status == 0,
              let line = r.stdout.split(separator: "\n").first,
              let u = URL(string: String(line)) else {
            throw ToolError(message: lastErrorLine(r.stderr))
        }
        return u
    }

    // MARK: YouTube 搜尋（播放清單自動下載用）

    struct SearchResult {
        var url: String
        var title: String
        var channel: String
        var viewCount: Int
        var duration: Double
        var verified: Bool
        var thumbnail: URL?
    }

    static func search(_ query: String, count: Int = 10) async throws -> [SearchResult] {
        let args = commonArgs + ["-J", "--flat-playlist", "ytsearch\(count):\(query)"]
        let r = try await ProcessRunner.run(exe, args)
        guard r.status == 0, let data = r.stdout.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let es = json["entries"] as? [[String: Any]] else {
            throw ToolError(message: lastErrorLine(r.stderr))
        }
        return es.compactMap { e in
            guard let id = e["id"] as? String else { return nil }
            return SearchResult(
                url: (e["url"] as? String) ?? "https://www.youtube.com/watch?v=\(id)",
                title: (e["title"] as? String) ?? "",
                channel: (e["channel"] as? String) ?? (e["uploader"] as? String) ?? "",
                viewCount: (e["view_count"] as? Int) ?? 0,
                duration: (e["duration"] as? Double) ?? 0,
                verified: (e["channel_is_verified"] as? Bool) ?? false,
                thumbnail: ((e["thumbnails"] as? [[String: Any]])?.last?["url"] as? String).flatMap(URL.init(string:)))
        }
    }

    // MARK: 下載

    /// 把使用者修改後的歌曲資訊寫回 info JSON。
    /// yt-dlp 的 --embed-metadata 會讀 `meta_xxx` 欄位並優先寫入檔案。
    static func applyMetadata(_ m: TrackMetadata, to raw: [String: Any]) -> [String: Any] {
        var j = raw
        func set(_ key: String, _ value: String) {
            guard !value.isEmpty else { return }
            j["meta_\(key)"] = value
        }
        set("title", m.title)
        set("artist", m.artist)
        set("album", m.album)
        set("album_artist", m.albumArtist)
        set("date", m.year)
        set("genre", m.genre)
        if !m.title.isEmpty { j["track"] = m.title }
        if !m.artist.isEmpty { j["artist"] = m.artist; j["artists"] = [m.artist] }
        if !m.album.isEmpty { j["album"] = m.album }
        return j
    }

    static func downloadArguments(infoJSONPath: String, options o: DownloadOptions,
                                  fileName: String, outputDir: URL) -> [String] {
        var a = commonArgs
        a += ["--load-info-json", infoJSONPath,
              "-P", outputDir.path,
              // 檔名直接用使用者確認過的名稱；% 需跳脫
              "-o", sanitizeFileName(fileName).replacingOccurrences(of: "%", with: "%%") + ".%(ext)s",
              "--newline", "--progress",
              "--progress-template", "download:@@P %(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._downloaded_bytes_str)s|%(progress._total_bytes_str,progress._total_bytes_estimate_str)s",
              "--progress-template", "postprocess:@@PP %(progress.postprocessor)s|%(progress.status)s",
              "--print", "after_move:@@F %(filepath)s",
              "--embed-metadata",
              "--no-mtime"]

        switch o.kind {
        case .audio:
            a += ["-f", "ba/b", "-x", "--audio-format", o.audioFormat.rawValue]
            if o.audioFormat.isLossless || o.audioBitrate == 0 {
                a += ["--audio-quality", "0"]
            } else {
                a += ["--audio-quality", "\(o.audioBitrate)K"]
            }
            if o.embedThumbnail && o.audioFormat.supportsCover {
                // 把 YouTube 縮圖裁成正方形當專輯封面
                a += ["--embed-thumbnail", "--convert-thumbnails", "jpg",
                      "--ppa", "ThumbnailsConvertor+ffmpeg_o:-c:v mjpeg -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\""]
            }
        case .video:
            let h = o.maxHeight
            let res = h > 0 ? "res:\(h)" : "res"
            a += ["-f", "bv*+ba/b"]
            switch o.container {
            case .mp4, .mov:
                // 1080p 以下優先 H.264，QuickTime / iPhone 都能直接播放
                a += ["-S", (h > 0 && h <= 1080) ? "\(res),vcodec:h264,acodec:m4a" : "\(res),acodec:m4a"]
            case .webm:
                a += ["-S", "\(res),vcodec:vp9,acodec:opus"]
            case .mkv:
                a += ["-S", res]
            }
            a += ["--merge-output-format", o.container.rawValue,
                  "--remux-video", o.container.rawValue]
            if o.embedThumbnail && [.mp4, .mkv].contains(o.container) {
                a += ["--embed-thumbnail"]
            }
            if o.subtitles {
                a += ["--write-subs", "--sub-langs", "zh-Hant,zh-TW,zh-HK,zh-Hans,zh-CN,zh,en.*,ja,ko",
                      "--embed-subs"]
            }
        }

        if o.trimEnabled && o.trimEnd > o.trimStart {
            a += ["--download-sections", String(format: "*%.2f-%.2f", o.trimStart, o.trimEnd),
                  "--force-keyframes-at-cuts",
                  // 修剪時由 ffmpeg 下載，讓它回報進度（out_time_us）才能顯示百分比
                  "--downloader-args", "ffmpeg:-progress pipe:2 -nostats -loglevel error"]
        }
        return a
    }

    static func lastErrorLine(_ stderr: String) -> String {
        let lines = stderr.split(separator: "\n").map(String.init)
        return lines.last(where: { $0.contains("ERROR") }) ?? lines.last ?? "Unknown error"
    }

    static func selfUpdate() async -> String {
        // Homebrew 安裝的 yt-dlp 需用 brew 更新
        if exe.hasPrefix("/opt/homebrew") || exe.hasPrefix("/usr/local"),
           let brew = ToolLocator.find("brew") {
            let r = try? await ProcessRunner.run(brew, ["upgrade", "yt-dlp"])
            return (r?.stdout ?? "") + (r?.stderr ?? "")
        }
        let r = try? await ProcessRunner.run(exe, ["-U"])
        return (r?.stdout ?? "") + (r?.stderr ?? "")
    }
}
