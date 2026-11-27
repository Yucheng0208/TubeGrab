import SwiftUI
import AppKit

/// 側欄「搜尋歌曲」：輸入歌名 / 歌手，到 YouTube 搜尋
struct SearchView: View {

    /// 由側欄決定：「搜尋歌曲」或「用歌詞找歌」
    var mode: SearchMode = .song
    @Bindable private var store = PageStores.search
    private var query: String { get { store.query } nonmutating set { store.query = newValue } }
    private var results: [YTDLP.SearchResult] { get { store.results } nonmutating set { store.results = newValue } }
    private var lastQuery: String { get { store.lastQuery } nonmutating set { store.lastQuery = newValue } }
    private var loading: Bool { get { store.loading } nonmutating set { store.loading = newValue } }
    private var errorText: String? { get { store.errorText } nonmutating set { store.errorText = newValue } }
    @State private var toast: String?
    private var router = AppRouter.shared
    private var preview = AudioPreviewPlayer.shared
    private var theme: AccentTheme { AppSettings.shared.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeroInputBar(icon: store.mode == .lyrics ? "quote.bubble.fill" : "magnifyingglass",
                             title: store.mode == .lyrics ? t("nav.lyrics") : t("nav.search"),
                             subtitle: store.mode == .lyrics ? t("search.lyricsSubtitle") : t("search.subtitle"),
                             placeholder: store.mode == .lyrics ? t("search.lyricsPlaceholder") : t("search.placeholder"),
                             fieldIcon: store.mode == .lyrics ? "text.quote" : "music.mic",
                             text: $store.query,
                             onSubmit: { Task { await run(query) } }) {
                    Button {
                        if let s = NSPasteboard.general.string(forType: .string) {
                            query = s.trimmingCharacters(in: .whitespacesAndNewlines)
                            Task { await run(query) }
                        }
                    } label: { Label(t("new.paste"), systemImage: "doc.on.clipboard.fill") }
                    .buttonStyle(HeroButtonStyle())

                    Button { Task { await run(query) } } label: {
                        HStack(spacing: 6) {
                            if loading { ProgressView().controlSize(.small) } else { Image(systemName: "magnifyingglass") }
                            Text(t("search.button"))
                        }
                    }
                    .buttonStyle(HeroButtonStyle(primary: true))
                    .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty || loading)
                } footer: {
                    // 搜尋方式：歌名／歌手 或 歌詞
                    HStack(spacing: 8) {
                        modeChip(.song, t("search.modeSong"), "music.mic")
                        modeChip(.lyrics, t("search.modeLyrics"), "quote.bubble")
                    }
                }

                if let errorText {
                    Label(errorText, systemImage: "exclamationmark.triangle.fill").font(.app(.body)).foregroundStyle(.red)
                }

                if !results.isEmpty {
                    SearchResultsSection(query: lastQuery, results: results,
                                         onPick: { r in preview.stop(); router.openDownload(r.url) },
                                         onQuickAudio: { r in quick(r) })
                    .transition(.opacity)
                } else if !loading {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(t("search.tipsTitle"), systemImage: "lightbulb.fill").font(.app(.headline)).foregroundStyle(theme.color)
                            Text(store.mode == .lyrics ? t("search.lyricsTips") : t("search.tips"))
                                .font(.app(.callout)).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(ui(36))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxWidth: .infinity)
            .animation(.snappy(duration: 0.28), value: results.map(\.url))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .safeAreaInset(edge: .bottom) {
            if preview.current != nil {
                MiniPreviewBar(onPick: { r in preview.stop(); router.openDownload(r.url) },
                               onQuickAudio: { r in quick(r) })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.28), value: preview.current?.url)
        .overlay(alignment: .bottom) { ToastView(text: toast) }
        .onDisappear { preview.stop() }
        .onAppear { if store.mode != mode { store.mode = mode; results = []; errorText = nil } }
        .task(id: router.pendingSearch) {
            if let q = router.pendingSearch {
                router.pendingSearch = nil
                query = q
                await run(q)
            }
        }
    }

    private func modeChip(_ m: SearchMode, _ title: String, _ icon: String) -> some View {
        let on = store.mode == m
        return Button {
            guard store.mode != m else { return }
            store.mode = m
            results = []
            // 側欄也跟著切到對應的項目
            if !query.isEmpty { router.openSearch(query, lyrics: m == .lyrics) }
            else { router.go(m == .lyrics ? .lyrics : .search) }
        } label: {
            Label(title, systemImage: icon)
                .font(.app(.callout).weight(.semibold))
                .foregroundStyle(on ? theme.color : .white)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(on ? Color.white : Color.white.opacity(0.18), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func quick(_ r: YTDLP.SearchResult) {
        DownloadManager.shared.quickAudio(r)
        withAnimation(.spring) { toast = t("new.added") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { toast = nil } }
    }

    private func run(_ q: String) async {
        let typed = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty else { return }
        // 其實是網址 → 交給「新增下載」
        if let url = normalizeURL(typed) { router.openDownload(url); return }
        loading = true; errorText = nil
        defer { loading = false }
        do {
            // 歌詞搜尋：加上「歌詞 / lyrics」，YouTube 的歌詞影片標題與說明大多有完整歌詞
            let hasCJK = typed.unicodeScalars.contains { (0x3040...0x9FFF).contains($0.value) || (0xAC00...0xD7AF).contains($0.value) }
            let q = store.mode == .lyrics ? typed + (hasCJK ? " 歌詞" : " lyrics") : typed
            let r = try await YTDLP.search(q, count: 15)
            lastQuery = typed
            results = r
            if r.isEmpty { errorText = t("search.none") }
        } catch { errorText = error.localizedDescription }
    }
}

/// 各頁面頂部的標題列
struct PageHeader: View {
    var icon: String
    var title: String
    var subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(AppSettings.shared.theme.gradient, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.app(.title))
                Text(subtitle).font(.app(.callout)).foregroundStyle(.secondary)
            }
        }
    }
}

/// 底部浮出的提示
struct ToastView: View {
    var text: String?
    var body: some View {
        if let text {
            Label(text, systemImage: "checkmark.circle.fill")
                .font(.app(.headline)).foregroundStyle(.white)
                .padding(.horizontal, 18).padding(.vertical, 12)
                .background(AppSettings.shared.theme.gradient, in: Capsule())
                .shadow(radius: 10, y: 4)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// 搜尋頁底部的試聽播放列
struct MiniPreviewBar: View {
    var onPick: (YTDLP.SearchResult) -> Void
    var onQuickAudio: (YTDLP.SearchResult) -> Void
    private var preview = AudioPreviewPlayer.shared
    private var theme: AccentTheme { AppSettings.shared.theme }

    init(onPick: @escaping (YTDLP.SearchResult) -> Void, onQuickAudio: @escaping (YTDLP.SearchResult) -> Void) {
        self.onPick = onPick
        self.onQuickAudio = onQuickAudio
    }

    var body: some View {
        if let r = preview.current {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    AsyncImage(url: r.thumbnail) { $0.resizable().scaledToFill() } placeholder: { theme.gradient.opacity(0.3) }
                        .frame(width: 64, height: 36).clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.title).font(.app(.callout).weight(.semibold)).lineLimit(1)
                        statusText(r)
                    }
                    Spacer()
                    Button { preview.toggle(r) } label: {
                        Group {
                            if preview.state == .loading { ProgressView().controlSize(.small).tint(.white) }
                            else { Image(systemName: preview.state == .playing ? "pause.fill" : "play.fill") }
                        }
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(theme.gradient, in: Circle())
                    }
                    .buttonStyle(.plain)
                    Button { onPick(r) } label: { Label(t("search.pick"), systemImage: "slider.horizontal.3") }
                    Button { onQuickAudio(r) } label: { Label(t("search.quickAudio"), systemImage: "arrow.down.circle.fill") }
                        .buttonStyle(GradientButtonStyle())
                    Button { preview.stop() } label: { Image(systemName: "xmark") }
                        .buttonStyle(.borderless).help(t("search.stopPreview"))
                }
                HStack(spacing: 8) {
                    Text(formatDuration(preview.position)).font(.app(.caption2).monospacedDigit()).foregroundStyle(.secondary)
                    Slider(value: Binding(get: { preview.position }, set: { preview.seek(to: $0) }),
                           in: 0...max(preview.duration, 1))
                        .disabled(preview.state == .loading)
                    Text(formatDuration(preview.duration)).font(.app(.caption2).monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(alignment: .top) { Divider() }
        }
    }

    @ViewBuilder private func statusText(_ r: YTDLP.SearchResult) -> some View {
        switch preview.state {
        case .loading:
            Text(t("search.previewLoading")).font(.app(.caption)).foregroundStyle(.secondary)
        case .failed(let msg):
            Text(msg).font(.app(.caption)).foregroundStyle(.red).lineLimit(2)
        default:
            Text(r.channel).font(.app(.caption)).foregroundStyle(.secondary).lineLimit(1)
        }
    }
}
