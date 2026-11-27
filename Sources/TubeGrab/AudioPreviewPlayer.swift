import AVFoundation
import Observation

/// 搜尋結果的試聽播放器：一次只播一首，切換時自動停止上一首
@MainActor
@Observable
final class AudioPreviewPlayer {
    static let shared = AudioPreviewPlayer()

    enum State: Equatable { case idle, loading, playing, paused, failed(String) }

    private(set) var current: YTDLP.SearchResult?
    private(set) var state: State = .idle
    var position: Double = 0
    private(set) var duration: Double = 0

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var observer: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    /// 已解析過的串流網址（約 6 小時內有效）
    @ObservationIgnored private var cache: [String: (url: URL, at: Date)] = [:]
    @ObservationIgnored private var generation = 0

    func isCurrent(_ r: YTDLP.SearchResult) -> Bool { current?.url == r.url }

    /// 按下某首的播放鍵：同一首就切換播放／暫停，不同首就換歌
    func toggle(_ r: YTDLP.SearchResult) {
        if isCurrent(r) {
            switch state {
            case .playing: pause()
            case .paused: resume()
            case .loading: break
            default: play(r)
            }
        } else {
            play(r)
        }
    }

    func play(_ r: YTDLP.SearchResult) {
        stop()
        generation += 1
        let gen = generation
        current = r
        duration = r.duration
        position = 0
        state = .loading
        Task {
            do {
                let stream = try await streamURL(for: r.url)
                guard gen == generation else { return }
                start(stream)
            } catch {
                guard gen == generation else { return }
                state = .failed(error.localizedDescription)
            }
        }
    }

    func pause() { player?.pause(); if state == .playing { state = .paused } }
    func resume() { player?.play(); if state == .paused { state = .playing } }

    func seek(to s: Double) {
        position = s
        player?.seek(to: CMTime(seconds: s, preferredTimescale: 600))
    }

    func stop() {
        generation += 1
        player?.pause()
        if let o = observer { player?.removeTimeObserver(o) }
        if let e = endObserver { NotificationCenter.default.removeObserver(e) }
        observer = nil; endObserver = nil; player = nil
        current = nil
        state = .idle
        position = 0
    }

    private func start(_ url: URL) {
        let p = AVPlayer(url: url)
        observer = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] t in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.position = t.seconds
                if let d = p.currentItem?.duration.seconds, d.isFinite, d > 0 { self.duration = d }
            }
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                             object: p.currentItem, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.state = .paused; self?.seek(to: 0) }
        }
        player = p
        p.play()
        state = .playing
    }

    private func streamURL(for page: String) async throws -> URL {
        if let c = cache[page], Date().timeIntervalSince(c.at) < 5 * 3600 { return c.url }
        let u = try await YTDLP.audioStreamURL(page)
        cache[page] = (u, Date())
        return u
    }
}
