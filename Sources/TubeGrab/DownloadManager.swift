import Foundation
import Observation
import AppKit

enum DownloadStatus: Equatable {
    case waiting, searching, downloading, processing, done, failed(String), cancelled

    var label: String {
        switch self {
        case .waiting: return t("status.waiting")
        case .searching: return t("status.searching")
        case .downloading: return t("status.downloading")
        case .processing: return t("status.processing")
        case .done: return t("status.done")
        case .failed: return t("status.failed")
        case .cancelled: return t("status.cancelled")
        }
    }
    var isActive: Bool { [.searching, .downloading, .processing].contains(self) }
    var isFinished: Bool {
        switch self { case .done, .failed, .cancelled: return true; default: return false }
    }
}

@Observable
final class DownloadTask: Identifiable {
    let id = UUID()
    /// 影片網址；從 Spotify/Apple Music 來的項目一開始是 nil，會在開始時自動搜尋
    var url: String?
    var searchTrack: PlaylistTrack?
    var options: DownloadOptions
    var metadata: TrackMetadata
    var cachedInfo: [String: Any]?
    var cachedAt = Date()
    var thumbnail: URL?

    var status: DownloadStatus = .waiting
    /// 整體進度 0...1（影片 + 音訊 + 轉檔合併計算）
    var progress: Double = 0
    var speed = ""
    var eta = ""
    var sizeText = ""
    /// 目前階段的翻譯 key（下載影片 / 下載音訊 / 轉檔…）
    var stageKey = "status.waiting"
    var startedAt: Date?
    @ObservationIgnored var part = 0
    @ObservationIgnored var lastRaw: Double = 0
    var outputFile: URL?
    var sourceNote = ""
    var useYouTubeMetadata = false

    @ObservationIgnored var handle: RunningProcess?

    init(url: String?, options: DownloadOptions, metadata: TrackMetadata,
         info: MediaInfo? = nil, searchTrack: PlaylistTrack? = nil) {
        self.url = url
        self.options = options
        self.metadata = metadata
        self.cachedInfo = info?.raw
        self.thumbnail = info?.thumbnail
        self.searchTrack = searchTrack
    }

    var displayTitle: String {
        metadata.fileName.isEmpty ? (metadata.title.isEmpty ? (url ?? "?") : metadata.title) : metadata.fileName
    }
}

@MainActor
@Observable
final class DownloadManager {
    static let shared = DownloadManager()
    var tasks: [DownloadTask] = []

    func add(_ task: DownloadTask) {
        tasks.append(task)
        pump()
    }

    func remove(_ task: DownloadTask) {
        task.handle?.cancel()
        tasks.removeAll { $0.id == task.id }
        pump()
    }

    func cancel(_ task: DownloadTask) {
        task.handle?.cancel()
        task.status = .cancelled
        pump()
    }

    func retry(_ task: DownloadTask) {
        task.status = .waiting
        task.progress = 0
        task.part = 0
        task.lastRaw = 0
        task.cachedInfo = nil
        pump()
    }

    func clearFinished() {
        tasks.removeAll { $0.status == .done || $0.status == .cancelled }
    }

    /// 依「同時下載數量」啟動等待中的項目
    private func pump() {
        let limit = max(1, AppSettings.shared.maxConcurrent)
        let running = tasks.filter { $0.status.isActive }.count
        guard running < limit else { return }
        for task in tasks.filter({ $0.status == .waiting }).prefix(limit - running) {
            task.status = task.url == nil ? .searching : .downloading
            Task { await self.run(task) }
        }
    }

    private func run(_ task: DownloadTask) async {
        do {
            // 1. 播放清單歌曲：先到 YouTube 找最適合的版本
            if task.url == nil, let track = task.searchTrack {
                let query = "\(track.artist) \(track.title)"
                let results = try await YTDLP.search(query, count: 10)
                guard let best = TrackMatcher.pick(results, for: track) else {
                    throw ToolError(message: t("err.noMatch"))
                }
                task.url = best.url
                task.sourceNote = "\(best.channel) · \(best.viewCount.formatted()) \(t("new.views"))"
            }
            guard let url = task.url else { throw ToolError(message: t("err.badURL")) }
            if task.status == .cancelled { return }

            // 2. 取得完整資訊（超過 1 小時就重新取得，避免串流網址過期）
            task.status = .downloading
            if task.cachedInfo == nil || Date().timeIntervalSince(task.cachedAt) > 3600 {
                let info = try await YTDLP.fetchInfo(url, singleVideo: true)
                task.cachedInfo = info.raw
                task.cachedAt = Date()
                if task.thumbnail == nil { task.thumbnail = info.thumbnail }
                // 播放清單項目：檔名與歌曲資訊以 Spotify / Apple Music 為準，缺的再用 YouTube 補
                if task.useYouTubeMetadata {
                    task.metadata = info.defaultMetadata
                    task.useYouTubeMetadata = false
                } else if task.searchTrack != nil {
                    let yt = info.defaultMetadata
                    if task.metadata.album.isEmpty { task.metadata.album = yt.album }
                    if task.metadata.year.isEmpty { task.metadata.year = yt.year }
                    if task.metadata.genre.isEmpty { task.metadata.genre = yt.genre }
                }
            }
            guard let raw = task.cachedInfo else { throw ToolError(message: "No info") }

            // 3. 把修改後的資訊寫入暫存 JSON
            let merged = YTDLP.applyMetadata(task.metadata, to: raw)
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("tubegrab-\(task.id).info.json")
            try JSONSerialization.data(withJSONObject: merged).write(to: tmp)
            defer { try? FileManager.default.removeItem(at: tmp) }

            let outDir = AppSettings.shared.outputFolder
            try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
            let fileName = task.metadata.fileName.isEmpty ? (raw["title"] as? String ?? "video") : task.metadata.fileName
            let args = YTDLP.downloadArguments(infoJSONPath: tmp.path, options: task.options,
                                               fileName: fileName, outputDir: outDir)

            // 4. 執行下載並解析進度
            task.startedAt = Date()
            task.part = 0; task.lastRaw = 0
            task.stageKey = task.options.kind == .video ? "stage.video" : "stage.audio"
            let handle = RunningProcess()
            task.handle = handle
            let result = try await ProcessRunner.stream(YTDLP.exe, args, handle: handle) { line, _ in
                Task { @MainActor in self.handleLine(line, task: task) }
            }
            task.handle = nil
            if handle.isCancelled { task.status = .cancelled; pump(); return }
            guard result.status == 0 else { throw ToolError(message: YTDLP.lastErrorLine(result.stderr)) }

            if task.outputFile == nil,
               let line = result.stdout.split(separator: "\n").last(where: { $0.hasPrefix("@@F ") }) {
                task.outputFile = URL(fileURLWithPath: String(line.dropFirst(4)))
            }
            // 5. 音訊工具（聲道 / 去人聲 / 升降 Key …）與畫質提升
            if task.options.needsPostProcess, let file = task.outputFile {
                task.status = .processing
                task.stageKey = task.options.kind == .video && task.options.upscaleHeight > 0 ? "stage.upscale" : "stage.effects"
                task.speed = ""; task.eta = ""
                let length = task.options.trimEnabled && task.options.trimEnd > task.options.trimStart
                    ? task.options.trimEnd - task.options.trimStart
                    : ((raw["duration"] as? Double) ?? 0)
                let fxHandle = RunningProcess()
                task.handle = fxHandle
                let base = task.progress
                try await MediaPostProcessor.process(file: file, options: task.options, duration: length,
                                                     srcWidth: (raw["width"] as? Int) ?? 0,
                                                     srcHeight: (raw["height"] as? Int) ?? 0,
                                                     raw: raw,
                                                     handle: fxHandle) { p in
                    Task { @MainActor in task.progress = max(task.progress, base + p * (0.99 - base)) }
                }
                task.handle = nil
                if fxHandle.isCancelled { task.status = .cancelled; pump(); return }
            }

            task.progress = 1
            task.stageKey = "status.done"
            task.status = .done
        } catch {
            if task.status != .cancelled { task.status = .failed(error.localizedDescription) }
        }
        pump()
    }

    /// 把 yt-dlp 每一部分的 0~100% 換算成整體進度：
    /// 影片 = 視訊(0~75%) + 音訊(75~90%) + 合併/轉檔(90~100%)
    /// 音樂 = 音訊(0~85%) + 轉檔/寫入封面(85~100%)
    private func overall(_ raw: Double, task: DownloadTask) -> Double {
        let r = min(max(raw, 0), 1)
        // 畫質提升很花時間：下載只佔整體的 40%
        if task.options.kind == .video && (task.options.upscaleHeight > 0 || task.options.aspect != .original) {
            return (task.part == 0 ? r * 0.75 : 0.75 + r * 0.15) * 0.4
        }
        if task.options.kind == .video {
            return task.part == 0 ? r * 0.75 : 0.75 + r * 0.15
        }
        return r * 0.85
    }

    private func updateRaw(_ raw: Double, task: DownloadTask) {
        // 百分比突然從高變低 → 進入下一個部分（例如影片下載完開始下載音訊）
        if raw < task.lastRaw - 0.3 { task.part += 1 }
        task.lastRaw = raw
        if task.options.kind == .video {
            task.stageKey = task.part == 0 ? "stage.video" : "stage.audio"
        } else {
            task.stageKey = "stage.audio"
        }
        task.status = .downloading
        task.progress = max(task.progress, overall(raw, task: task))
    }

    private func handleLine(_ line: String, task: DownloadTask) {
        if line.hasPrefix("@@PP ") {
            // 後製（合併、轉 mp3、嵌入封面、寫入資訊）
            let parts = line.dropFirst(5).split(separator: "|").map(String.init)
            task.status = .processing
            let pp = parts.first ?? ""
            task.stageKey = pp.contains("Thumbnail") ? "stage.cover"
                : pp.contains("Metadata") ? "stage.tags"
                : pp.contains("Merger") ? "stage.merge"
                : "stage.convert"
            let base = task.options.kind == .video ? 0.90 : 0.85
            task.progress = max(task.progress, min(0.99, base + (task.progress >= base ? 0.02 : 0)))
            task.speed = ""; task.eta = ""
        } else if line.hasPrefix("@@P ") {
            let parts = line.dropFirst(4).split(separator: "|", omittingEmptySubsequences: false).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            if let p = parts.first, let v = Double(p.replacingOccurrences(of: "%", with: "")) {
                updateRaw(v / 100, task: task)
            }
            func clean(_ s: String) -> String { (s == "NA" || s.contains("Unknown")) ? "" : s }
            if parts.count > 1 { task.speed = clean(parts[1]) }
            if parts.count > 2 { task.eta = clean(parts[2]) }
            if parts.count > 4 {
                let done = clean(parts[3]), total = clean(parts[4])
                task.sizeText = total.isEmpty ? done : "\(done) / \(total)"
            }
        } else if line.hasPrefix("out_time_us=") || line.hasPrefix("out_time_ms=") {
            // 修剪模式：ffmpeg 回報已處理到第幾微秒
            let length = task.options.trimEnd - task.options.trimStart
            if let us = Double(line.split(separator: "=").last ?? ""), length > 0 {
                updateRaw(us / 1_000_000 / length, task: task)
            }
        } else if line.hasPrefix("speed=") {
            let v = String(line.dropFirst(6))
            if v != "N/A" { task.speed = v }
        } else if line.hasPrefix("@@F ") {
            task.outputFile = URL(fileURLWithPath: String(line.dropFirst(4)))
        }
    }

    /// 全部進行中項目的平均進度（給清單上方的總進度條）
    var overallProgress: Double {
        let active = tasks.filter { !$0.status.isFinished || $0.status == .done }
        guard !active.isEmpty, active.contains(where: { !$0.status.isFinished }) else { return 0 }
        return active.map(\.progress).reduce(0, +) / Double(active.count)
    }

        // MARK: 播放清單 → 自動加入下載

    func enqueuePlaylist(_ tracks: [PlaylistTrack], options: DownloadOptions) {
        for tr in tracks {
            var m = TrackMetadata()
            m.title = tr.title
            m.artist = tr.artist
            m.album = tr.album
            m.fileName = sanitizeFileName(tr.artist.isEmpty ? tr.title : "\(tr.artist) - \(tr.title)")
            if tr.directURL != nil { m.fileName = sanitizeFileName(tr.title) }
            let task = DownloadTask(url: tr.directURL, options: options, metadata: m,
                                    searchTrack: tr.directURL == nil ? tr : nil)
            // YouTube 播放清單的項目：下載前改用影片自己的資訊
            task.useYouTubeMetadata = tr.directURL != nil
            tasks.append(task)
        }
        pump()
    }
}
