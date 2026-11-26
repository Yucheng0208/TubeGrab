import Foundation

/// 聲道模式
enum ChannelMode: String, CaseIterable, Identifiable, Codable {
    case stereo, leftOnly, rightOnly, swap, mono
    var id: String { rawValue }
    var labelKey: String { "fx.ch.\(rawValue)" }
}

/// 下載完成後套用的音訊效果（用 ffmpeg 處理）
struct AudioEffects: Codable, Equatable {
    var channelMode: ChannelMode = .stereo
    /// 左右平衡：-1 = 只有左邊，0 = 置中，1 = 只有右邊
    var balance: Double = 0
    /// 去除人聲（卡拉 OK）：消除左右聲道相同的中央聲音，保留低音
    var removeVocals = false
    /// 音量調整（dB）
    var volumeDB: Double = 0
    /// 音量標準化（每首歌一樣大聲）
    var normalize = false
    /// 播放速度 0.5 ~ 2.0（只用於音樂）
    var speed: Double = 1
    /// 升降 Key（半音）-6 ~ +6
    var pitch: Int = 0
    var fadeIn: Double = 0
    var fadeOut: Double = 0

    var isActive: Bool { self != AudioEffects() }

    /// 產生 ffmpeg -af 的濾鏡字串
    func filterChain(duration: Double, allowSpeed: Bool) -> String {
        var f: [String] = ["aresample=44100"]

        if removeVocals {
            // 左減右 → 中央的人聲被抵消；低於 180Hz 的低音用原聲補回來
            f.append("asplit[tg_a][tg_b];[tg_a]lowpass=f=180[tg_low];[tg_b]pan=stereo|c0=c0-c1|c1=c1-c0,highpass=f=180[tg_side];[tg_low][tg_side]amix=inputs=2:normalize=0")
        }

        switch channelMode {
        case .stereo: break
        case .leftOnly: f.append("pan=stereo|c0=c0|c1=c0")
        case .rightOnly: f.append("pan=stereo|c0=c1|c1=c1")
        case .swap: f.append("pan=stereo|c0=c1|c1=c0")
        case .mono: f.append("pan=stereo|c0=0.5*c0+0.5*c1|c1=0.5*c0+0.5*c1")
        }

        if abs(balance) > 0.01 {
            let l = balance > 0 ? 1 - balance : 1
            let r = balance < 0 ? 1 + balance : 1
            f.append(String(format: "pan=stereo|c0=%.3f*c0|c1=%.3f*c1", l, r))
        }

        if pitch != 0 {
            // 改變取樣率來升降調，再用 atempo 把長度拉回原本
            let ratio = pow(2.0, Double(pitch) / 12.0)
            f.append(String(format: "asetrate=44100*%.6f,aresample=44100,atempo=%.6f", ratio, 1 / ratio))
        }

        var outDuration = duration
        if allowSpeed && abs(speed - 1) > 0.01 {
            f.append(String(format: "atempo=%.3f", speed))
            outDuration = duration / speed
        }

        if abs(volumeDB) > 0.05 { f.append(String(format: "volume=%.1fdB", volumeDB)) }
        if fadeIn > 0 { f.append(String(format: "afade=t=in:d=%.1f", fadeIn)) }
        if fadeOut > 0, outDuration > fadeOut {
            f.append(String(format: "afade=t=out:st=%.2f:d=%.1f", outDuration - fadeOut, fadeOut))
        }
        if normalize { f.append("loudnorm=I=-14:TP=-1.5:LRA=11") }
        return f.joined(separator: ",")
    }
}

/// 下載後處理：音訊效果 + 影片畫質提升，一次 ffmpeg 完成
enum MediaPostProcessor {
    /// 依副檔名挑選重新編碼的音訊格式
    static func audioCodecArgs(for ext: String, options: DownloadOptions) -> [String] {
        let br = options.audioBitrate == 0 ? 320 : options.audioBitrate
        switch ext {
        case "mp3": return ["-c:a", "libmp3lame", "-b:a", "\(br)k", "-id3v2_version", "3"]
        case "m4a": return options.kind == .audio && options.audioFormat == .alac ? ["-c:a", "alac"] : ["-c:a", "aac", "-b:a", "\(min(br, 256))k"]
        case "aac": return ["-c:a", "aac", "-b:a", "\(min(br, 256))k"]
        case "flac": return ["-c:a", "flac"]
        case "wav": return ["-c:a", "pcm_s16le"]
        case "opus", "webm": return ["-c:a", "libopus", "-b:a", "160k"]
        case "ogg": return ["-c:a", "libvorbis", "-q:a", "6"]
        default: return ["-c:a", "aac", "-b:a", "192k"]  // mp4 / mov / mkv 影片
        }
    }

    /// 影片濾鏡（ffmpeg -filter_complex）：畫質提升 + 改變比例
    /// 補邊方式：黑邊 / 白邊 / 模糊影片背景 / 霧化封面 / 裁切填滿
    /// 輸入：[0:v:0] 影片，霧化封面時 [1:v] 為封面圖；輸出標籤 [vout]
    /// 回傳 (濾鏡圖, 輸出短邊)；不需要處理時回傳 nil
    static func videoFilter(options o: DownloadOptions, srcWidth: Int, srcHeight: Int, hasCover: Bool) -> (String, Int)? {
        guard srcWidth > 0, srcHeight > 0 else { return nil }
        let srcShort = min(srcWidth, srcHeight)
        let upscale = o.upscaleHeight > srcShort ? o.upscaleHeight : 0
        let ratio = o.aspect.ratio
        // 比例和原本幾乎一樣就不必補邊
        let sameRatio = ratio.map { abs(Double($0.0) / Double($0.1) - Double(srcWidth) / Double(srcHeight)) < 0.01 } ?? true
        guard upscale > 0 || !sameRatio else { return nil }

        let even = { (v: Int) in max(2, v / 2 * 2) }
        let short = upscale > 0 ? upscale : srcShort
        var w: Int, h: Int
        if let (rw, rh) = ratio, !sameRatio {
            if rw >= rh { h = even(short); w = even(short * rw / rh) }
            else { w = even(short); h = even(short * rh / rw) }
        } else if srcWidth >= srcHeight {
            h = even(short); w = even(short * srcWidth / srcHeight)
        } else {
            w = even(short); h = even(short * srcHeight / srcWidth)
        }

        let fit = "scale=\(w):\(h):force_original_aspect_ratio=decrease:flags=lanczos"
        let fill = "scale=\(w):\(h):force_original_aspect_ratio=increase:flags=lanczos,crop=\(w):\(h)"
        let pre = upscale > 0 ? "hqdn3d=1.5:1.5:6:6," : ""
        var post = ""
        if upscale > 0 {
            let strength = srcShort <= 480 ? 0.6 : (srcShort <= 720 ? 0.45 : 0.3)
            post += ",cas=\(strength)"
        }
        post += ",setsar=1,format=yuv420p"

        var style = o.padStyle
        if style == .coverBlur && !hasCover { style = .blur }  // 沒有封面就改用影片模糊

        let graph: String
        if sameRatio {
            graph = "[0:v:0]\(pre)scale=\(w):\(h):flags=lanczos\(post)[vout]"
        } else {
            switch style {
            case .black, .white:
                let color = style == .black ? "black" : "white"
                graph = "[0:v:0]\(pre)\(fit),pad=\(w):\(h):(ow-iw)/2:(oh-ih)/2:color=\(color)\(post)[vout]"
            case .crop:
                graph = "[0:v:0]\(pre)\(fill)\(post)[vout]"
            case .blur:
                graph = "[0:v:0]\(pre)split[tg_bg][tg_fg];"
                    + "[tg_bg]\(fill),boxblur=20:2,eq=brightness=-0.05[tg_b];"
                    + "[tg_fg]\(fit)[tg_f];"
                    + "[tg_b][tg_f]overlay=(W-w)/2:(H-h)/2\(post)[vout]"
            case .coverBlur:
                // 封面圖放大、霧化、稍微調暗當背景；影片置中疊在上面
                graph = "[1:v]\(fill),boxblur=30:3,eq=brightness=-0.08:saturation=1.1,setsar=1[tg_b];"
                    + "[0:v:0]\(pre)\(fit)[tg_f];"
                    + "[tg_b][tg_f]overlay=(W-w)/2:(H-h)/2:shortest=1\(post)[vout]"
            }
        }
        return (graph, min(w, h))
    }

    /// 需不需要封面圖（霧化封面補邊）
    static func needsCover(_ o: DownloadOptions) -> Bool {
        o.kind == .video && o.aspect != .original && o.padStyle == .coverBlur
    }

    /// 下載封面圖到暫存（給霧化封面用）
    static func fetchCover(_ raw: [String: Any]) async -> URL? {
        guard let s = raw["thumbnail"] as? String, let u = URL(string: s),
              let (data, resp) = try? await URLSession.shared.data(from: u),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        let ext = u.pathExtension.isEmpty ? "jpg" : u.pathExtension
        let f = FileManager.default.temporaryDirectory.appendingPathComponent("tubegrab-cover-\(UUID().uuidString).\(ext)")
        return (try? data.write(to: f)) != nil ? f : nil
    }

    /// 組出影片處理用的 ffmpeg 參數（輸入、濾鏡、對應、編碼）
    static func videoArgs(input: URL, cover: URL?, options o: DownloadOptions, srcWidth: Int, srcHeight: Int,
                          ext: String, keepOtherStreams: Bool) -> (args: [String], changed: Bool) {
        var args = ["-i", input.path]
        if let cover { args += ["-loop", "1", "-i", cover.path] }
        guard o.kind == .video,
              let (graph, outShort) = videoFilter(options: o, srcWidth: srcWidth, srcHeight: srcHeight, hasCover: cover != nil) else {
            return (args, false)
        }
        args += ["-filter_complex", graph, "-map", "[vout]", "-map", "0:a?"]
        if keepOtherStreams { args += ["-map", "0:s?"] }
        args += ["-c", "copy"] + videoCodecArgs(for: ext, height: outShort)
        return (args, true)
    }

    static func videoCodecArgs(for ext: String, height: Int) -> [String] {
        let mbps = height >= 2160 ? 30 : (height >= 1440 ? 16 : 10)
        if ext == "webm" {
            return ["-c:v:0", "libvpx-vp9", "-b:v:0", "\(mbps)M", "-deadline", "realtime", "-cpu-used", "8", "-row-mt", "1"]
        }
        // Mac 內建硬體 HEVC 編碼，速度快；hvc1 標籤讓 QuickTime / iPhone 可以播放
        return ["-c:v:0", "hevc_videotoolbox", "-b:v:0", "\(mbps)M", "-tag:v:0", "hvc1"]
    }

    static func process(file: URL, options: DownloadOptions, duration: Double, srcWidth: Int, srcHeight: Int,
                        raw: [String: Any] = [:],
                        handle: RunningProcess, onProgress: @escaping @Sendable (Double) -> Void) async throws {
        let ffmpeg = AppSettings.shared.ffmpegPath
        let ext = file.pathExtension.lowercased()
        let tmp = file.deletingLastPathComponent()
            .appendingPathComponent(".tubegrab-fx-\(UUID().uuidString).\(ext)")
        let cover = needsCover(options) ? await fetchCover(raw) : nil
        defer { if let cover { try? FileManager.default.removeItem(at: cover) } }

        var args = ["-hide_banner", "-nostats", "-loglevel", "error", "-progress", "pipe:2", "-y"]
        let v = videoArgs(input: file, cover: cover, options: options, srcWidth: srcWidth, srcHeight: srcHeight,
                          ext: ext, keepOtherStreams: true)
        let fx = options.effects
        guard v.changed || fx.isActive else { return }  // 沒有需要做的事
        args += v.args
        if !v.changed { args += ["-map", "0", "-c", "copy"] }  // 只改聲音：其他串流（含封面、字幕）原樣保留
        if fx.isActive {
            args += ["-af", fx.filterChain(duration: duration, allowSpeed: options.kind == .audio)]
            args += audioCodecArgs(for: ext, options: options)
        }
        if ["mp4", "m4a", "mov"].contains(ext) { args += ["-movflags", "+faststart"] }
        args.append(tmp.path)

        let outDuration = options.kind == .audio ? duration / max(fx.speed, 0.1) : duration
        let r = try await ProcessRunner.stream(ffmpeg, args, handle: handle) { line, _ in
            if line.hasPrefix("out_time_us="), outDuration > 0,
               let us = Double(line.dropFirst("out_time_us=".count)) {
                onProgress(min(1, us / 1_000_000 / outDuration))
            }
        }
        guard r.status == 0, FileManager.default.fileExists(atPath: tmp.path) else {
            try? FileManager.default.removeItem(at: tmp)
            if handle.isCancelled { return }
            throw ToolError(message: "ffmpeg: " + YTDLP.lastErrorLine(r.stderr))
        }
        _ = try FileManager.default.replaceItemAt(file, withItemAt: tmp)
    }
}
