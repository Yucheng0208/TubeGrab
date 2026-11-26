import SwiftUI
import AVKit

/// 影片預覽 + 選取片段 + 「套用設定後」的實際效果預覽（原始 ↔ 套用後 切換比較）
struct PreviewTrimView: View {
    var url: String
    var info: [String: Any] = [:]
    var duration: Double
    @Binding var options: DownloadOptions
    var metadata: TrackMetadata = TrackMetadata()

    enum Mode: Hashable { case original, applied }

    @State private var player: AVPlayer?
    @State private var appliedPlayer: AVPlayer?
    @State private var mode: Mode = .original
    @State private var loading = false
    @State private var failed = false
    @State private var current: Double = 0
    @State private var timeObserver: Any?
    @State private var stopAt: Double?
    @State private var renderer = PreviewRenderer()
    @State private var autoUpdate = true
    @State private var debounce: Task<Void, Never>?

    private var theme: AccentTheme { AppSettings.shared.theme }
    private var stale: Bool { renderer.isStale(options) }
    private let snappy = Animation.snappy(duration: 0.28)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            modeBar
            playerArea
            renderBar
            fileInfo

            Toggle(t("trim.enable"), isOn: $options.trimEnabled.animation(snappy))
                .toggleStyle(.switch).font(.app(.headline))

            if options.trimEnabled && duration > 0 {
                trimControls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(snappy, value: options.trimEnabled)
        .animation(snappy, value: mode)
        .task(id: url) { await loadPreview() }
        .onChange(of: options) { _, _ in scheduleAutoRender() }
        .onDisappear {
            player?.pause(); appliedPlayer?.pause()
            if let o = timeObserver { player?.removeTimeObserver(o) }
            renderer.cleanup()
        }
    }

    // MARK: 原始 / 套用後 切換

    private var modeBar: some View {
        HStack(spacing: 10) {
            Picker("", selection: $mode) {
                Label(t("pv.original"), systemImage: "play.rectangle").tag(Mode.original)
                Label(t("pv.applied"), systemImage: "wand.and.stars").tag(Mode.applied)
            }
            .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
            .onChange(of: mode) { _, m in
                if m == .applied {
                    player?.pause()
                    if stale { startRender() } else { appliedPlayer?.play() }
                } else {
                    appliedPlayer?.pause()
                }
            }
            Spacer()
            if case .ready = renderer.state, mode == .applied {
                Text("\(t("pv.range")) \(formatDuration(renderer.clipStart))–\(formatDuration(renderer.clipStart + renderer.clipLength))")
                    .font(.app(.caption).monospacedDigit()).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: 播放器

    private var playerArea: some View {
        ZStack {
            Color.black
            if mode == .original {
                if let player {
                    PlayerView(player: player)
                } else if loading {
                    ProgressView().controlSize(.large).tint(.white)
                } else if failed {
                    Text(t("trim.previewFailed")).foregroundStyle(.white.opacity(0.8))
                } else {
                    Button { Task { await loadPreview() } } label: {
                        Label(t("trim.loadPreview"), systemImage: "play.circle.fill").font(.app(.title2))
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                appliedArea
            }
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .frame(maxWidth: 640)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder private var appliedArea: some View {
        switch renderer.state {
        case .ready:
            ZStack {
                // 音樂模式沒有畫面：顯示封面
                if options.kind == .audio, let thumb = (info["thumbnail"] as? String).flatMap(URL.init(string:)) {
                    AsyncImage(url: thumb) { $0.resizable().scaledToFill().blur(radius: 18).opacity(0.6) } placeholder: { Color.black }
                    AsyncImage(url: thumb) { $0.resizable().scaledToFit().padding(30) } placeholder: { EmptyView() }
                }
                if let appliedPlayer { PlayerView(player: appliedPlayer, transparent: options.kind == .audio) }
            }
        case .fetching:
            busy(t("pv.fetching"), nil)
        case .rendering(let p):
            busy(t("pv.rendering"), p)
        case .failed(let msg):
            VStack(spacing: 10) {
                Text(msg).font(.app(.caption)).foregroundStyle(.white.opacity(0.8)).multilineTextAlignment(.center)
                Button(t("q.retry")) { startRender() }
            }.padding()
        case .idle:
            Button { startRender() } label: {
                Label(t("pv.render"), systemImage: "wand.and.stars").font(.app(.title3))
            }
            .buttonStyle(GradientButtonStyle())
        }
    }

    private func busy(_ text: String, _ progress: Double?) -> some View {
        VStack(spacing: 12) {
            ProgressView().controlSize(.large).tint(.white)
            Text(text).font(.app(.callout)).foregroundStyle(.white.opacity(0.85))
            GradientProgressBar(value: progress, height: 6).frame(width: 220)
        }
    }

    // MARK: 產生 / 更新預覽

    private var renderBar: some View {
        HStack(spacing: 10) {
            Button { mode = .applied; startRender() } label: {
                Label(renderer.renderedOptions == nil ? t("pv.render") : t("pv.update"),
                      systemImage: stale && renderer.renderedOptions != nil ? "exclamationmark.arrow.circlepath" : "wand.and.stars")
            }
            .disabled(isBusy || (!stale && renderer.renderedOptions != nil))
            .tint(stale && renderer.renderedOptions != nil ? .orange : theme.color)

            Toggle(t("pv.autoUpdate"), isOn: $autoUpdate).toggleStyle(.checkbox).font(.app(.caption))
            Spacer()
        }
        .help(t("pv.hint"))
    }

    private var isBusy: Bool {
        switch renderer.state { case .fetching, .rendering: return true; default: return false }
    }

    private func startRender() {
        debounce?.cancel()
        appliedPlayer?.pause()
        Task {
            await renderer.render(info: info, options: options, current: current, duration: duration)
            if case .ready(let file) = renderer.state {
                let p = AVPlayer(url: file)
                appliedPlayer = p
                if mode == .applied { p.play() }
            }
        }
    }

    /// 已經預覽過、又改了設定 → 停 0.8 秒沒再動就自動重算
    private func scheduleAutoRender() {
        guard autoUpdate, renderer.renderedOptions != nil, stale else { return }
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await MainActor.run { if mode == .applied { startRender() } }
        }
    }

    // MARK: 將儲存為…

    private var fileInfo: some View {
        let ext: String = {
            if options.kind == .video { return options.container.rawValue }
            switch options.audioFormat {
            case .alac: return "m4a"
            case .vorbis: return "ogg"
            default: return options.audioFormat.rawValue
            }
        }()
        let name = (metadata.fileName.isEmpty ? (info["title"] as? String ?? "") : metadata.fileName) + "." + ext
        let tags = [metadata.title, metadata.artist, metadata.album, metadata.year].filter { !$0.isEmpty }.joined(separator: " · ")
        return HStack(spacing: 8) {
            Image(systemName: options.kind == .audio ? "music.note" : "film").foregroundStyle(theme.color)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(t("pv.file"))：\(name)").font(.app(.callout).weight(.semibold)).lineLimit(1).truncationMode(.middle)
                if !tags.isEmpty { Text(tags).font(.app(.caption)).foregroundStyle(.secondary).lineLimit(1) }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.color.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: 修剪

    private var trimControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
                GridRow {
                    Text(t("trim.start")).frame(width: 50, alignment: .leading)
                    Slider(value: Binding(get: { options.trimStart },
                                          set: { options.trimStart = min($0, options.trimEnd - 1); seek(options.trimStart) }),
                           in: 0...duration)
                    Text(formatDuration(options.trimStart)).monospacedDigit().frame(width: 70)
                    Button(t("trim.setStart")) { options.trimStart = min(current, max(0, options.trimEnd - 1)) }
                        .disabled(player == nil)
                }
                GridRow {
                    Text(t("trim.end")).frame(width: 50, alignment: .leading)
                    Slider(value: Binding(get: { options.trimEnd },
                                          set: { options.trimEnd = max($0, options.trimStart + 1); seek(options.trimEnd) }),
                           in: 0...duration)
                    Text(formatDuration(options.trimEnd)).monospacedDigit().frame(width: 70)
                    Button(t("trim.setEnd")) { options.trimEnd = max(current, options.trimStart + 1) }
                        .disabled(player == nil)
                }
            }
            HStack {
                Button {
                    guard let player else { return }
                    mode = .original
                    seek(options.trimStart)
                    stopAt = options.trimEnd
                    player.play()
                } label: { Label(t("trim.playSection"), systemImage: "play.fill") }
                .disabled(player == nil)
                Spacer()
                Text("\(formatDuration(options.trimEnd - options.trimStart))")
                    .monospacedDigit().foregroundStyle(.secondary)
            }
        }
    }

    private func seek(_ s: Double) {
        player?.seek(to: CMTime(seconds: s, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func loadPreview() async {
        guard player == nil, !loading else { return }
        loading = true; failed = false
        defer { loading = false }
        do {
            let stream: URL
            if let u = YTDLP.previewURL(fromInfo: info) { stream = u } else { stream = try await YTDLP.previewStreamURL(url) }
            let p = AVPlayer(url: stream)
            timeObserver = p.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { time in
                current = time.seconds
                if let s = stopAt, current >= s {
                    p.pause()
                    stopAt = nil
                }
            }
            player = p
        } catch {
            failed = true
        }
    }
}

/// 用 AppKit 的 AVPlayerView（SwiftUI 的 VideoPlayer 在 SwiftPM 編譯時可能會閃退）
struct PlayerView: NSViewRepresentable {
    var player: AVPlayer
    /// 音樂預覽時讓背後的封面透出來
    var transparent = false
    func makeNSView(context: Context) -> AVPlayerView {
        let v = AVPlayerView()
        v.player = player
        if transparent {
            v.wantsLayer = true
            v.layer?.backgroundColor = NSColor.clear.cgColor
        }
        v.controlsStyle = .inline
        v.showsFullScreenToggleButton = true
        return v
    }
    func updateNSView(_ v: AVPlayerView, context: Context) {
        if v.player !== player { v.player = player }
    }
}
