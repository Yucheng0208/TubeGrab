import Foundation
import Observation
import AVFoundation

/// 「套用設定後」的預覽：
/// 1. 用 yt-dlp 抓一小段（修剪範圍，或目前位置起 20 秒）
/// 2. 用與正式下載相同的 ffmpeg 處理（格式／位元率、聲道、去人聲、升降 Key、速度、淡入淡出、畫質提升）
/// 同一段只下載一次；只改效果時直接重算，幾秒就好。
@MainActor
@Observable
final class PreviewRenderer {
    enum State: Equatable {
        case idle
        case fetching(Double)    // 下載預覽片段中（0~1）
        case rendering(Double)   // 套用效果中（0~1）
        case ready(URL)
        case failed(String)
    }

    var state: State = .idle
    /// 已產生的預覽對應的設定；和目前設定不同時代表「需要更新」
    private(set) var renderedOptions: DownloadOptions?
    private(set) var clipStart: Double = 0
    private(set) var clipLength: Double = 0
    /// 去人聲時量到的「左右差異比整體小幾 dB」；越大越接近單聲道
    private(set) var monoLikeDB: Double?

    private var cachedClip: (key: String, file: URL)?
    private var cachedCover: URL?
    private var handle: RunningProcess?
    private var generation = 0

    static let maxLength: Double = 30
    static let defaultLength: Double = 20

    private var dir: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("tubegrab-preview", isDirectory: true)
    }

    func isStale(_ o: DownloadOptions) -> Bool {
        guard let r = renderedOptions else { return true }
        return r != o
    }

    /// 決定預覽範圍：有修剪就用修剪範圍（最多 30 秒），否則從目前播放位置開始 20 秒
    static func range(options o: DownloadOptions, current: Double, duration: Double) -> (Double, Double) {
        if o.trimEnabled && o.trimEnd > o.trimStart {
            return (o.trimStart, min(o.trimEnd - o.trimStart, maxLength))
        }
        let len = duration > 0 ? min(defaultLength, duration) : defaultLength
        var start = max(0, current)
        if duration > 0, start + len > duration { start = max(0, duration - len) }
        return (start, len)
    }

    func cancel() {
        handle?.cancel()
        generation += 1
    }

    func render(info raw: [String: Any], options o: DownloadOptions, current: Double, duration: Double) async {
        cancel()
        let gen = generation
        let (start, length) = Self.range(options: o, current: current, duration: duration)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        do {
            // 1. 取得原始片段（同範圍、同類型、同畫質只抓一次）
            let fetchHeight = o.kind == .video ? min(o.maxHeight == 0 ? 1080 : o.maxHeight, 1080) : 0
            let key = "\(raw["id"] ?? "")|\(Int(start * 10))|\(Int(length * 10))|\(o.kind.rawValue)|\(fetchHeight)"
            let clip: URL
            if let c = cachedClip, c.key == key, FileManager.default.fileExists(atPath: c.file.path) {
                clip = c.file
            } else {
                state = .fetching(0)
                clip = try await fetchClip(raw: raw, kind: o.kind, height: fetchHeight, start: start, length: length) { p in
                    Task { @MainActor in
                        if gen == self.generation, case .fetching = self.state { self.state = .fetching(p) }
                    }
                }
                guard gen == generation else { return }
                cachedClip = (key, clip)
            }

            // 去人聲：先檢查這段錄音是不是幾乎單聲道（那樣去人聲做不出效果）
            if o.effects.removeVocals {
                monoLikeDB = await AudioAnalysis.sideToMidDB(clip)
                guard gen == generation else { return }
            } else {
                monoLikeDB = nil
            }

            // 2. 套用設定
            state = .rendering(0)
            let out = try await process(clip: clip, options: o, length: length, raw: raw) { p in
                Task { @MainActor in
                    if gen == self.generation, case .rendering = self.state { self.state = .rendering(p) }
                }
            }
            guard gen == generation else { return }
            clipStart = start
            clipLength = length
            renderedOptions = o
            state = .ready(out)
        } catch {
            guard gen == generation else { return }
            state = .failed(error.localizedDescription)
        }
    }

    private func fetchClip(raw: [String: Any], kind: MediaKind, height: Int, start: Double, length: Double,
                           onProgress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let json = dir.appendingPathComponent("info-\(UUID().uuidString).json")
        try JSONSerialization.data(withJSONObject: raw).write(to: json)
        defer { try? FileManager.default.removeItem(at: json) }
        let name = "clip-\(UUID().uuidString)"

        var args = YTDLP.commonArgs + ["--load-info-json", json.path, "-P", dir.path, "-o", "\(name).%(ext)s",
                    "--download-sections", String(format: "*%.2f-%.2f", start, start + length),
                    "--print", "after_move:@@F %(filepath)s", "--no-mtime",
                    // 片段由 ffmpeg 下載，讓它回報進度
                    "--downloader-args", "ffmpeg:-progress pipe:2 -nostats -loglevel error"]
        if kind == .audio {
            args += ["-f", "ba/b"]
        } else {
            args += ["-f", "bv*[height<=\(height)]+ba/b[height<=\(height)]/b",
                     "-S", "vcodec:h264,acodec:m4a", "--merge-output-format", "mp4"]
        }
        let h = RunningProcess()
        handle = h
        // 影片要下載影像 + 聲音兩段，各佔一半
        let parts = kind == .video ? 2.0 : 1.0
        let counter = PartCounter()
        let r = try await ProcessRunner.stream(YTDLP.exe, args, handle: h) { line, _ in
            if line.hasPrefix("out_time_us="), length > 0, let us = Double(line.dropFirst("out_time_us=".count)) {
                let p = min(1, us / 1_000_000 / length)
                onProgress(min(1, (counter.update(p) + p) / parts))
            }
        }
        if h.isCancelled { throw CancellationError() }
        guard r.status == 0,
              let line = r.stdout.split(separator: "\n").last(where: { $0.hasPrefix("@@F ") }) else {
            throw ToolError(message: YTDLP.lastErrorLine(r.stderr))
        }
        return URL(fileURLWithPath: String(line.dropFirst(4)))
    }

    /// 與正式下載相同的處理，輸出成 AVPlayer 能播放的格式
    private func process(clip: URL, options o: DownloadOptions, length: Double, raw: [String: Any],
                         onProgress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        // AVPlayer 不支援 opus / ogg / webm / mkv → 預覽改用相近格式（聲音效果相同）
        let ext: String
        if o.kind == .audio {
            switch o.audioFormat {
            case .mp3: ext = "mp3"
            case .flac: ext = "flac"
            case .wav: ext = "wav"
            case .aac, .m4a, .alac, .opus, .vorbis: ext = "m4a"
            }
        } else {
            ext = "mp4"
        }
        let out = dir.appendingPathComponent("preview-\(UUID().uuidString).\(ext)")

        var args = ["-hide_banner", "-nostats", "-loglevel", "error", "-progress", "pipe:2", "-y"]
        if o.kind == .audio {
            args += ["-i", clip.path, "-vn"]
        } else {
            // 預覽片段最高只抓 1080p，所以用片段實際的尺寸計算
            let (cw, ch) = Self.videoSize(of: clip) ?? ((raw["width"] as? Int) ?? 0, (raw["height"] as? Int) ?? 0)
            var cover: URL? = nil
            if MediaPostProcessor.needsCover(o) {
                if let c = cachedCover, FileManager.default.fileExists(atPath: c.path) { cover = c }
                else { cover = await MediaPostProcessor.fetchCover(raw); cachedCover = cover }
            }
            let v = MediaPostProcessor.videoArgs(input: clip, cover: cover, options: o, srcWidth: cw, srcHeight: ch,
                                                 ext: "mp4", keepOtherStreams: false)
            args += v.args
            if !v.changed { args += ["-map", "0:v:0", "-map", "0:a:0?", "-c:v", "copy"] }
            args += ["-movflags", "+faststart"]
        }
        if o.effects.isActive {
            args += ["-af", o.effects.filterChain(duration: length, allowSpeed: o.kind == .audio)]
        }
        // 音訊一律依所選格式 / 位元率重新編碼，聽得出品質差異
        args += MediaPostProcessor.audioCodecArgs(for: o.kind == .audio ? ext : "mp4", options: o)
        args.append(out.path)

        let outLength = o.kind == .audio ? length / max(o.effects.speed, 0.1) : length
        let h = RunningProcess()
        handle = h
        let r = try await ProcessRunner.stream(AppSettings.shared.ffmpegPath, args, handle: h) { line, _ in
            if line.hasPrefix("out_time_us="), outLength > 0, let us = Double(line.dropFirst("out_time_us=".count)) {
                onProgress(min(1, us / 1_000_000 / outLength))
            }
        }
        if h.isCancelled { throw CancellationError() }
        guard r.status == 0 else { throw ToolError(message: "ffmpeg: " + YTDLP.lastErrorLine(r.stderr)) }
        return out
    }

    /// 讀取影片實際寬高
    nonisolated static func videoSize(of file: URL) -> (Int, Int)? {
        let asset = AVURLAsset(url: file)
        let sem = DispatchSemaphore(value: 0)
        var size: CGSize?
        Task.detached {
            if let track = try? await asset.loadTracks(withMediaType: .video).first,
               let s = try? await track.load(.naturalSize), let tf = try? await track.load(.preferredTransform) {
                let r = s.applying(tf)
                size = CGSize(width: abs(r.width), height: abs(r.height))
            }
            sem.signal()
        }
        sem.wait()
        guard let s = size, s.width > 0 else { return nil }
        return (Int(s.width), Int(s.height))
    }

    /// 關閉畫面時清掉暫存檔
    func cleanup() {
        cancel()
        try? FileManager.default.removeItem(at: dir)
        cachedClip = nil
        if let c = cachedCover { try? FileManager.default.removeItem(at: c) }
        cachedCover = nil
        renderedOptions = nil
        state = .idle
    }
}

/// 偵測進度從頭開始（進入下一段）
private final class PartCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var last: Double = 0
    private var done: Double = 0
    /// 回傳已完成的段數
    func update(_ p: Double) -> Double {
        lock.lock(); defer { lock.unlock() }
        if p < last - 0.3 { done += 1 }
        last = p
        return done
    }
}
