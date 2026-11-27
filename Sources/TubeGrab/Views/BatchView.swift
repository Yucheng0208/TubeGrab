import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 側欄「歌單批次下載」：Spotify / Apple Music / KKBOX / YouTube 播放清單，或貼上文字歌單
struct BatchView: View {

    @Bindable private var store = PageStores.batch
    private var urlText: String { get { store.urlText } nonmutating set { store.urlText = newValue } }
    private var loading: Bool { get { store.loading } nonmutating set { store.loading = newValue } }
    private var errorText: String? { get { store.errorText } nonmutating set { store.errorText = newValue } }
    private var name: String { get { store.name } nonmutating set { store.name = newValue } }
    private var tracks: [PlaylistTrack] { get { store.tracks } nonmutating set { store.tracks = newValue } }
    private var options: DownloadOptions { get { store.options } nonmutating set { store.options = newValue } }
    private var listText: String { get { store.listText } nonmutating set { store.listText = newValue } }
    @State private var showListSheet = false
    @State private var dropTargeted = false
    private var router = AppRouter.shared
    private var theme: AccentTheme { AppSettings.shared.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                inputCard

                if let errorText {
                    Card {
                        Label(errorText, systemImage: "exclamationmark.triangle.fill")
                            .font(.app(.body)).foregroundStyle(.red).textSelection(.enabled)
                    }
                }
                if loading {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(t("new.loading")).font(.app(.title3)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
                } else if !tracks.isEmpty {
                    PlaylistSection(name: name, tracks: $store.tracks, options: $store.options) { chosen in
                        DownloadManager.shared.enqueuePlaylist(chosen, options: options)
                        router.go(.queue)
                    }
                    .transition(.opacity)
                } else {
                    sourcesGrid
                }
            }
            .padding(36)
            .frame(maxWidth: 1160, alignment: .leading)
            .frame(maxWidth: .infinity)
            .animation(.snappy(duration: 0.28), value: tracks.count)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showListSheet) { listSheet }
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { providers in
            guard let p = providers.first else { return false }
            _ = p.loadObject(ofClass: URL.self) { url, _ in
                guard let url, PlaylistFileImporter.supportedExtensions.contains(url.pathExtension.lowercased()) else { return }
                Task { @MainActor in importFile(url) }
            }
            return true
        }
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(theme.color, style: StrokeStyle(lineWidth: 3, dash: [10, 6]))
                    .background(theme.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(Label(t("imp.dropNow"), systemImage: "doc.badge.arrow.up").font(.app(.title2)).foregroundStyle(theme.color))
                    .padding(16)
                    .allowsHitTesting(false)
            }
        }
        .task(id: router.pendingBatchURL ?? router.pendingBatchText ?? (router.openListSheet ? "sheet" : "")) {
            await consumePending()
        }
    }

    // MARK: 輸入

    private var inputCard: some View {
        HeroInputBar(icon: "music.note.list", title: t("nav.batch"), subtitle: t("batch.subtitle"),
                     placeholder: t("batch.placeholder"), text: $store.urlText,
                     onSubmit: { Task { await load(urlText) } }) {
            Button {
                if let s = NSPasteboard.general.string(forType: .string) {
                    let text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.contains("\n") { listText = text; showListSheet = true }
                    else { urlText = text; Task { await load(text) } }
                }
            } label: { Label(t("new.paste"), systemImage: "doc.on.clipboard.fill") }
            .buttonStyle(HeroButtonStyle())

            Button { Task { await load(urlText) } } label: {
                HStack(spacing: 6) {
                    if loading { ProgressView().controlSize(.small) } else { Image(systemName: "arrow.down.circle") }
                    Text(t("new.analyze"))
                }
            }
            .buttonStyle(HeroButtonStyle(primary: true))
            .disabled(urlText.isEmpty || loading)
        } footer: {
            HStack(spacing: 10) {
                Button { showListSheet = true } label: { Label(t("list.button"), systemImage: "text.badge.plus") }
                    .buttonStyle(HeroButtonStyle())
                Button { chooseFile() } label: { Label(t("imp.button"), systemImage: "doc.badge.arrow.up") }
                    .buttonStyle(HeroButtonStyle())
                Spacer()
                Label(t("imp.dropHint"), systemImage: "hand.point.up.left")
                    .font(.app(.caption)).foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: 匯入檔案（CSV / TXT / XLSX）

    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = PlaylistFileImporter.supportedExtensions.compactMap { UTType(filenameExtension: $0) }
        if panel.runModal() == .OK, let u = panel.url { importFile(u) }
    }

    private func importFile(_ url: URL) {
        do {
            let list = try PlaylistFileImporter.load(url)
            guard !list.isEmpty else { errorText = t("imp.empty"); return }
            errorText = nil
            name = url.deletingPathExtension().lastPathComponent
            tracks = list
            options.kind = .audio
        } catch {
            errorText = error.localizedDescription
        }
    }

    /// 還沒輸入時：顯示支援的來源
    private var sourcesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            sourceCard("play.rectangle.fill", "YouTube", t("batch.src.youtube"))
            sourceCard("music.note", "Spotify", t("batch.src.spotify"))
            sourceCard("applelogo", "Apple Music", t("batch.src.apple"))
            sourceCard("music.quarternote.3", "KKBOX", t("batch.src.kkbox"))
            sourceCard("text.badge.plus", t("list.button"), t("batch.src.text"))
            sourceCard("tablecells", t("imp.button"), t("imp.src"))
            sourceCard("checkmark.seal.fill", t("batch.ruleTitle"), t("pl.rule"))
        }
    }

    private func sourceCard(_ icon: String, _ title: String, _ body: String) -> some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundStyle(theme.color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.app(.headline))
                    Text(body).font(.app(.caption)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: 貼上歌單文字

    private var listSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(t("list.title"), systemImage: "text.badge.plus").font(.app(.title2))
            Text(t("list.hint")).font(.app(.callout)).foregroundStyle(.secondary)
            TextEditor(text: $store.listText)
                .font(.app(.body))
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                .frame(minHeight: 260)
            HStack {
                Text("\(PlaylistImporter.parseTextList(listText).count) \(t("pl.tracks"))")
                    .font(.app(.callout)).foregroundStyle(.secondary)
                Spacer()
                Button(t("list.cancel")) { showListSheet = false }
                Button {
                    loadText(listText)
                    showListSheet = false
                } label: { Label(t("list.parse"), systemImage: "checkmark") }
                .buttonStyle(GradientButtonStyle())
                .disabled(PlaylistImporter.parseTextList(listText).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 560)
        .tint(theme.color)
    }

    // MARK: 讀取

    private func consumePending() async {
        if let list = router.pendingBatchList {
            router.pendingBatchList = nil
            urlText = router.pendingBatchURL ?? urlText
            router.pendingBatchURL = nil
            errorText = nil
            name = list.name; tracks = list.tracks
            return
        }
        if let u = router.pendingBatchURL {
            router.pendingBatchURL = nil
            urlText = u
            await load(u)
        }
        if let text = router.pendingBatchText {
            router.pendingBatchText = nil
            listText = text
            showListSheet = true
        }
        if router.openListSheet {
            router.openListSheet = false
            showListSheet = true
        }
    }

    private func loadText(_ text: String) {
        let list = PlaylistImporter.parseTextList(text)
        guard !list.isEmpty else { return }
        errorText = nil
        name = t("list.name")
        tracks = list
        options.kind = .audio
    }

    private func load(_ input: String) async {
        guard let url = normalizeURL(input) else { errorText = t("err.badURL"); return }
        urlText = url
        loading = true; errorText = nil; tracks = []
        defer { loading = false }
        do {
            if PlaylistImporter.source(of: url) != nil {
                let r = try await PlaylistImporter.importTracks(url)
                guard !r.tracks.isEmpty else { throw ToolError(message: t("err.noTracks")) }
                name = r.name; tracks = r.tracks
                options.kind = .audio
            } else {
                let i = try await YTDLP.fetchInfo(url)
                if i.isPlaylist {
                    name = i.title; tracks = i.entries
                } else {
                    // 單一影片 → 交給「新增下載」
                    router.openDownload(url)
                }
            }
        } catch {
            errorText = error.localizedDescription
        }
    }
}
