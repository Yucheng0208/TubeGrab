import SwiftUI
import AppKit

struct NewDownloadView: View {
    var onAdded: () -> Void

    @State private var urlText = ""
    @State private var loading = false
    @State private var errorText: String?
    @State private var info: MediaInfo?
    @State private var playlistName = ""
    @State private var playlistTracks: [PlaylistTrack] = []
    @State private var options = DownloadOptions()
    @State private var metadata = TrackMetadata()
    @State private var toast: String?
    @State private var searchResults: [YTDLP.SearchResult] = []
    @State private var searchQuery = ""
    @State private var showListSheet = false
    @State private var listText = ""
    private var installer = ToolInstaller.shared

    private var theme: AccentTheme { AppSettings.shared.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                if !installer.toolsReady { toolsBanner }
                if let e = errorText {
                    Card {
                        Label(e, systemImage: "exclamationmark.triangle.fill")
                            .font(.app(.body))
                            .foregroundStyle(.red).textSelection(.enabled)
                    }
                }
                if loading {
                    HStack(spacing: 12) {
                        ProgressView().controlSize(.regular)
                        Text(t("new.loading")).font(.app(.title3)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 30)
                } else if let info, !info.isPlaylist {
                    singleVideo(info)
                } else if !searchResults.isEmpty {
                    SearchResultsSection(query: searchQuery, results: searchResults,
                                         onPick: { r in urlText = r.url; Task { await load() } },
                                         onQuickAudio: { r in quickAudio(r) })
                } else if !playlistTracks.isEmpty {
                    PlaylistSection(name: playlistName, tracks: $playlistTracks, options: $options) { chosen in
                        DownloadManager.shared.enqueuePlaylist(chosen, options: options)
                        onAdded()
                    }
                } else {
                    steps
                }
            }
            .padding(28)
            .frame(maxWidth: 940, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(backgroundWash)
        .overlay(alignment: .bottom) {
            if let toast {
                Label(toast, systemImage: "checkmark.circle.fill")
                    .font(.app(.headline)).foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(theme.gradient, in: Capsule())
                    .shadow(radius: 10, y: 4)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(t("nav.new"))
        .sheet(isPresented: $showListSheet) { listSheet }
    }

    // MARK: 第一次使用：安裝工具

    private var toolsBanner: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: "shippingbox.fill").font(.system(size: 26))
                    .foregroundStyle(theme.gradient)
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("tools.missingTitle")).font(.app(.headline))
                    Text(t("tools.missingBody")).font(.app(.caption)).foregroundStyle(.secondary)
                    if installer.isInstalling {
                        GradientProgressBar(value: installer.progress, height: 8).padding(.top, 4)
                        Text(installer.log.split(separator: "\n").last.map(String.init) ?? "")
                            .font(.app(.caption2).monospaced()).foregroundStyle(.secondary).lineLimit(1)
                    } else if let err = installer.lastError {
                        Text(err).font(.app(.caption)).foregroundStyle(.red)
                    }
                }
                Spacer()
                Button {
                    Task { await installer.detectOrInstall() }
                } label: {
                    Label(installer.isInstalling ? t("tools.installing") : t("tools.install"), systemImage: "arrow.down.app.fill")
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(installer.isInstalling)
            }
        }
    }

    // MARK: 貼上歌單文字

    private var listSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(t("list.title"), systemImage: "text.badge.plus").font(.app(.title2))
            Text(t("list.hint")).font(.app(.callout)).foregroundStyle(.secondary)
            TextEditor(text: $listText)
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
                    loadTextList(listText)
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

    private func loadTextList(_ text: String) {
        let tracks = PlaylistImporter.parseTextList(text)
        guard !tracks.isEmpty else { return }
        info = nil; searchResults = []; errorText = nil
        playlistName = t("list.name")
        playlistTracks = tracks
        options.kind = .audio
    }

    private func quickAudio(_ r: YTDLP.SearchResult) {
        var o = options
        o.kind = .audio
        o.trimEnabled = false
        var m = TrackMetadata()
        m.title = r.title
        m.artist = r.channel.replacingOccurrences(of: " - Topic", with: "")
        m.fileName = sanitizeFileName(r.title)
        let task = DownloadTask(url: r.url, options: o, metadata: m)
        task.thumbnail = r.thumbnail
        task.useYouTubeMetadata = true
        DownloadManager.shared.add(task)
        withAnimation(.spring) { toast = t("new.added") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { withAnimation { toast = nil } }
    }

    private var backgroundWash: some View {
        ZStack(alignment: .top) {
            Color(nsColor: .windowBackgroundColor)
            theme.gradient.opacity(0.10).frame(height: 320).mask(
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom))
        }
        .ignoresSafeArea()
    }

    // MARK: 頂部大標題 + 網址列

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "arrow.down.to.line.compact")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("TubeGrab").font(.app(.largeTitle)).foregroundStyle(.white)
                    Text(t("app.tagline")).font(.app(.callout)).foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1).fixedSize()
                }
                .layoutPriority(1)
                Spacer(minLength: 8)
                // 視窗太窄時自動隱藏來源標籤，避免標題被擠到換行
                ViewThatFits(in: .horizontal) {
                    badges
                    Color.clear.frame(width: 0, height: 0)
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "link").foregroundStyle(.secondary)
                    TextField(t("new.placeholder"), text: $urlText)
                        .textFieldStyle(.plain)
                        .font(.app(.title3))
                        .onSubmit { Task { await load() } }
                    if !urlText.isEmpty {
                        Button { urlText = ""; info = nil; playlistTracks = []; searchResults = []; errorText = nil } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    if let s = NSPasteboard.general.string(forType: .string) {
                        let text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                        // 複製了多行歌單 → 直接當清單
                        if text.contains("\n"), PlaylistImporter.parseTextList(text).count > 1 {
                            listText = text
                            showListSheet = true
                        } else {
                            urlText = text
                            Task { await load() }
                        }
                    }
                } label: {
                    Label(t("new.paste"), systemImage: "doc.on.clipboard.fill")
                        .font(.app(.headline))
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button { showListSheet = true } label: {
                    Image(systemName: "text.badge.plus")
                        .font(.app(.headline))
                        .padding(.horizontal, 12).padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(t("list.button"))

                Button {
                    Task { await load() }
                } label: {
                    Text(normalizeURL(urlText) == nil && !urlText.isEmpty ? t("search.button") : t("new.analyze"))
                        .font(.app(.headline))
                        .padding(.horizontal, 18).padding(.vertical, 11)
                        .foregroundStyle(theme.color)
                        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(urlText.isEmpty || loading)
                .opacity(urlText.isEmpty ? 0.6 : 1)
            }
        }
        .padding(22)
        .background(theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: theme.color.opacity(0.3), radius: 10, y: 5)
    }

    private var badges: some View {
        HStack(spacing: 6) {
            sourceBadge("play.rectangle.fill", "YouTube", logo: "youtube")
            sourceBadge("music.note", "Spotify", logo: "spotify")
            sourceBadge("applelogo", "Apple Music", logo: "applemusic")
            sourceBadge("music.quarternote.3", "KKBOX", logo: "kkbox")
        }
    }

    private func sourceBadge(_ icon: String, _ name: String, logo: String) -> some View {
        HStack(spacing: 4) {
            // 有放官方 Logo（logos/<名稱>.png）就用 Logo，否則用系統圖示
            if let img = SourceLogo.image(logo) {
                Image(nsImage: img).resizable().scaledToFit().frame(height: 13)
            } else {
                Image(systemName: icon)
            }
            Text(name)
        }
        .font(.app(.caption))
        .lineLimit(1)
        .fixedSize()
        .foregroundStyle(.white)
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(.white.opacity(0.18), in: Capsule())
    }

    /// 還沒貼網址時顯示的步驟說明
    private var steps: some View {
        HStack(spacing: 14) {
            stepCard(1, "doc.on.clipboard", t("new.paste"))
            stepCard(2, "magnifyingglass", t("new.analyze"))
            stepCard(3, "slider.horizontal.3", t("opt.quality"))
            stepCard(4, "arrow.down.circle", t("new.add"))
        }
    }

    private func stepCard(_ n: Int, _ icon: String, _ title: String) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(n)").font(.app(.headline)).foregroundStyle(.white)
                        .frame(width: 26, height: 26).background(theme.gradient, in: Circle())
                    Spacer()
                    Image(systemName: icon).font(.system(size: 22)).foregroundStyle(theme.color)
                }
                Text(title).font(.app(.title3).weight(.semibold))
            }
        }
    }

    private func load() async {
        let typed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !typed.isEmpty else { return }
        guard let url = normalizeURL(typed) else {
            // 不是網址 → 當成歌名 / 歌手，到 YouTube 搜尋
            loading = true; errorText = nil; info = nil; playlistTracks = []; searchResults = []
            defer { loading = false }
            do {
                let r = try await YTDLP.search(typed, count: 15)
                if r.isEmpty { errorText = t("search.none") }
                searchQuery = typed
                searchResults = r
            } catch { errorText = error.localizedDescription }
            return
        }
        urlText = url
        loading = true; errorText = nil; info = nil; playlistTracks = []; searchResults = []
        defer { loading = false }
        do {
            if PlaylistImporter.source(of: url) != nil {
                // Spotify / Apple Music → 預設下載音樂
                let r = try await PlaylistImporter.importTracks(url)
                guard !r.tracks.isEmpty else { throw ToolError(message: t("err.noTracks")) }
                playlistName = r.name
                playlistTracks = r.tracks
                options.kind = .audio
            } else {
                let i = try await YTDLP.fetchInfo(url)
                if i.isPlaylist {
                    playlistName = i.title
                    playlistTracks = i.entries
                } else {
                    info = i
                    metadata = i.defaultMetadata
                    // 有歌曲資訊（YouTube Music / 官方音樂）就預設音樂
                    options.kind = (i.raw["track"] != nil || url.contains("music.youtube.com")) ? .audio : .video
                    options.trimStart = 0
                    options.trimEnd = i.duration
                    options.trimEnabled = false
                }
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    // MARK: 單一影片

    @ViewBuilder
    private func singleVideo(_ info: MediaInfo) -> some View {
        Card {
            HStack(alignment: .top, spacing: 18) {
                AsyncImage(url: info.thumbnail) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                    .frame(width: 220, height: 124)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                VStack(alignment: .leading, spacing: 10) {
                    Text(info.title).font(.app(.title2)).lineLimit(3).textSelection(.enabled)
                    HStack(spacing: 6) {
                        Pill(text: info.channel, icon: "person.crop.circle")
                        Pill(text: formatDuration(info.duration), icon: "clock")
                        Pill(text: info.viewCount.formatted(), icon: "eye")
                    }
                }
            }
        }

        OptionsSection(options: $options)

        AudioToolsSection(options: $options)

        Card(title: t("trim.title"), icon: "scissors") {
            PreviewTrimView(url: info.webpageURL, info: info.raw, duration: info.duration, options: $options, metadata: metadata)
        }

        MetadataEditor(metadata: $metadata, original: info.defaultMetadata,
                       lookupQuery: MetadataLookup.cleanQuery(title: info.title, artist: info.channel))

        HStack {
            Spacer()
            Button {
                let task = DownloadTask(url: info.webpageURL, options: options, metadata: metadata, info: info)
                DownloadManager.shared.add(task)
                withAnimation(.spring) { toast = t("new.added") }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { toast = nil }
                    onAdded()
                }
            } label: {
                Label(t("new.add"), systemImage: "arrow.down.circle.fill").font(.app(.title3).weight(.bold))
                    .padding(.horizontal, 8).padding(.vertical, 2)
            }
            .buttonStyle(GradientButtonStyle())
            .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - 格式 / 品質選項

struct OptionsSection: View {
    @Binding var options: DownloadOptions

    var body: some View {
        Card(title: t("opt.kind"), icon: "slider.horizontal.3") {
            HStack(spacing: 12) {
                ChoiceTile(title: t("opt.video"), icon: "film.fill", selected: options.kind == .video) { withAnimation(.snappy(duration: 0.28)) { options.kind = .video } }
                ChoiceTile(title: t("opt.audio"), icon: "music.note", selected: options.kind == .audio) { withAnimation(.snappy(duration: 0.28)) { options.kind = .audio } }
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                if options.kind == .video {
                    GridRow {
                        label(t("opt.format"))
                        Picker("", selection: $options.container) {
                            ForEach(VideoContainer.allCases) { Text($0.rawValue.uppercased()).tag($0) }
                        }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
                    }
                    GridRow {
                        label(t("opt.quality"))
                        Picker("", selection: $options.maxHeight) {
                            ForEach(videoHeights, id: \.self) { h in
                                Text(h == 0 ? t("opt.best") : (h == 2160 ? "4K" : "\(h)p")).tag(h)
                            }
                        }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 520)
                    }
                    GridRow {
                        label(t("up.title"))
                        VStack(alignment: .leading, spacing: 6) {
                            Picker("", selection: $options.upscaleHeight) {
                                Text(t("up.off")).tag(0)
                                Text("1080p").tag(1080)
                                Text("1440p").tag(1440)
                                Text("4K").tag(2160)
                            }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 380)
                            if options.upscaleHeight > 0 {
                                Label(t("up.hint"), systemImage: "sparkles")
                                    .font(.app(.caption)).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    GridRow {
                        label(t("ar.title"))
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("", selection: $options.aspect) {
                                ForEach(AspectRatio.allCases) { Text($0.label).tag($0) }
                            }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 520)
                            if options.aspect != .original {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        Text(t("ar.fill")).font(.app(.callout)).foregroundStyle(.secondary)
                                        Picker("", selection: $options.padStyle) {
                                            ForEach(PadStyle.allCases) { Text(t($0.labelKey)).tag($0) }
                                        }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 460)
                                    }
                                    Label(options.padStyle == .crop
                                          ? t("ar.warnCrop")
                                          : String(format: t("ar.warnPad"), t(options.padStyle.labelKey)),
                                          systemImage: "exclamationmark.triangle.fill")
                                        .font(.app(.caption))
                                        .foregroundStyle(.orange)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(8)
                                        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    GridRow {
                        Color.clear.frame(width: 1, height: 1)
                        HStack(spacing: 22) {
                            Toggle(t("opt.thumbnail"), isOn: $options.embedThumbnail)
                            Toggle(t("opt.subtitles"), isOn: $options.subtitles)
                        }.toggleStyle(.switch).font(.app(.body))
                    }
                } else {
                    GridRow {
                        label(t("opt.format"))
                        Picker("", selection: $options.audioFormat) {
                            ForEach(AudioFormat.allCases) { Text($0.label).tag($0) }
                        }.labelsHidden().frame(maxWidth: 280)
                    }
                    if !options.audioFormat.isLossless {
                        GridRow {
                            label(t("opt.quality"))
                            Picker("", selection: $options.audioBitrate) {
                                ForEach(audioBitrates, id: \.self) { b in
                                    Text(b == 0 ? t("opt.best") : "\(b)k").tag(b)
                                }
                            }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: 380)
                        }
                    }
                    GridRow {
                        Color.clear.frame(width: 1, height: 1)
                        Toggle(t("opt.thumbnail"), isOn: $options.embedThumbnail)
                            .toggleStyle(.switch).font(.app(.body))
                            .disabled(!options.audioFormat.supportsCover)
                    }
                }
            }
            .padding(.top, 4)
            .animation(.snappy(duration: 0.28), value: options.upscaleHeight > 0)
            .animation(.snappy(duration: 0.28), value: options.aspect)
            .animation(.snappy(duration: 0.28), value: options.audioFormat.isLossless)
        }
    }

    private func label(_ s: String) -> some View {
        Text(s).font(.app(.body).weight(.semibold)).foregroundStyle(.secondary)
    }
}

// MARK: - 歌曲資訊編輯

struct MetadataEditor: View {
    @Binding var metadata: TrackMetadata
    var original: TrackMetadata
    /// 有提供就自動到網路查詢歌曲資訊
    var lookupQuery: String? = nil

    @State private var query = ""
    @State private var suggestions: [SongInfo] = []
    @State private var searching = false
    @State private var searched = false

    var body: some View {
        Card(title: t("meta.title"), icon: "tag.fill") {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                row("meta.filename", $metadata.fileName, icon: "doc")
                row("meta.songTitle", $metadata.title, icon: "music.note")
                row("meta.artist", $metadata.artist, icon: "music.mic")
                row("meta.album", $metadata.album, icon: "square.stack")
                row("meta.albumArtist", $metadata.albumArtist, icon: "person.2")
                GridRow {
                    rowLabel("meta.year", icon: "calendar")
                    HStack(spacing: 12) {
                        field($metadata.year).frame(width: 100)
                        rowLabel("meta.genre", icon: "guitars")
                        field($metadata.genre)
                    }
                }
            }
            HStack {
                Spacer()
                Button { metadata = original } label: {
                    Label(t("meta.reset"), systemImage: "arrow.uturn.backward")
                }
                .disabled(metadata == original)
            }
            if lookupQuery != nil { lookupSection }
        }
        .task(id: lookupQuery) {
            guard let q = lookupQuery, !searched else { return }
            query = q
            await runLookup()
        }
    }

    // MARK: 網路上的歌曲資訊（參考）

    private var lookupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
            HStack(spacing: 8) {
                Label(t("ml.title"), systemImage: "globe").font(.app(.headline))
                Spacer()
                TextField(t("ml.placeholder"), text: $query)
                    .textFieldStyle(.roundedBorder).frame(maxWidth: 260)
                    .onSubmit { Task { await runLookup() } }
                Button { Task { await runLookup() } } label: {
                    if searching { ProgressView().controlSize(.small) } else { Image(systemName: "magnifyingglass") }
                }
                .disabled(searching || query.isEmpty)
            }
            Text(t("ml.hint")).font(.app(.caption)).foregroundStyle(.secondary)
            if suggestions.isEmpty && searched && !searching {
                Text(t("ml.none")).font(.app(.caption)).foregroundStyle(.secondary)
            }
            ForEach(suggestions) { s in suggestionRow(s) }
        }
        .animation(.snappy(duration: 0.28), value: suggestions)
    }

    private func suggestionRow(_ s: SongInfo) -> some View {
        let applied = metadata.title == s.title && metadata.artist == s.artist && metadata.album == s.album
        return HStack(spacing: 12) {
            AsyncImage(url: s.artwork) { $0.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.15) }
                .frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 3) {
                Text(s.title).font(.app(.body).weight(.semibold)).lineLimit(1)
                Text([s.artist, s.album].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.app(.caption)).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 6) {
                    if !s.year.isEmpty { Pill(text: s.year, icon: "calendar") }
                    if !s.genre.isEmpty { Pill(text: s.genre, icon: "guitars") }
                    if let n = s.trackNumber { Pill(text: "#\(n)") }
                    if s.durationSeconds > 0 { Pill(text: formatDuration(s.durationSeconds), icon: "clock") }
                }
            }
            Spacer()
            Button {
                withAnimation(.snappy(duration: 0.25)) { apply(s) }
            } label: {
                Label(applied ? t("ml.applied") : t("ml.apply"), systemImage: applied ? "checkmark.circle.fill" : "arrow.down.doc")
            }
            .disabled(applied)
        }
        .padding(8)
        .background(applied ? AppSettings.shared.theme.color.opacity(0.08) : Color.primary.opacity(0.03),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func apply(_ s: SongInfo) {
        metadata.title = s.title
        metadata.artist = s.artist
        metadata.album = s.album
        metadata.albumArtist = s.artist
        if !s.year.isEmpty { metadata.year = s.year }
        if !s.genre.isEmpty { metadata.genre = s.genre }
        metadata.fileName = sanitizeFileName("\(s.artist) - \(s.title)")
    }

    private func runLookup() async {
        guard !query.isEmpty else { return }
        searching = true
        defer { searching = false; searched = true }
        suggestions = (try? await MetadataLookup.search(query)) ?? []
    }

    private func rowLabel(_ key: String, icon: String) -> some View {
        Label(t(key), systemImage: icon)
            .font(.app(.callout).weight(.medium)).foregroundStyle(.secondary)
    }

    private func field(_ binding: Binding<String>) -> some View {
        TextField("", text: binding)
            .textFieldStyle(.plain)
            .font(.app(.body))
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func row(_ key: String, _ binding: Binding<String>, icon: String) -> some View {
        GridRow {
            rowLabel(key, icon: icon)
            field(binding)
        }
    }
}

// MARK: - 播放清單

struct PlaylistSection: View {
    var name: String
    @Binding var tracks: [PlaylistTrack]
    @Binding var options: DownloadOptions
    var onDownload: ([PlaylistTrack]) -> Void

    private var theme: AccentTheme { AppSettings.shared.theme }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Card {
                HStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
                        .frame(width: 70, height: 70)
                        .background(theme.gradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(name).font(.app(.title2))
                        HStack(spacing: 6) {
                            Pill(text: "\(tracks.count) \(t("pl.tracks"))", icon: "music.note")
                            Pill(text: "\(tracks.filter(\.selected).count) ✓")
                        }
                        Label(t("pl.rule"), systemImage: "checkmark.seal.fill")
                            .font(.app(.caption)).foregroundStyle(.secondary)
                    }
                }
            }

            OptionsSection(options: $options)

            AudioToolsSection(options: $options)

            Card(title: t("pl.title"), icon: "list.bullet") {
                HStack {
                    Button(t("pl.selectAll")) { for i in tracks.indices { tracks[i].selected = true } }
                    Button(t("pl.selectNone")) { for i in tracks.indices { tracks[i].selected = false } }
                    Spacer()
                    Button(t("pl.downloadSelected")) { onDownload(tracks.filter(\.selected)) }
                        .disabled(!tracks.contains(where: \.selected))
                    Button {
                        onDownload(tracks)
                    } label: { Label(t("pl.downloadAll"), systemImage: "arrow.down.circle.fill") }
                        .buttonStyle(GradientButtonStyle())
                }

                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array($tracks.enumerated()), id: \.element.id) { idx, $tr in
                        HStack(spacing: 12) {
                            Toggle("", isOn: $tr.selected).labelsHidden().toggleStyle(.checkbox)
                            Text("\(idx + 1)").font(.app(.callout).monospacedDigit())
                                .foregroundStyle(.secondary).frame(width: 30, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tr.title).font(.app(.body).weight(.medium)).lineLimit(1)
                                Text([tr.artist, tr.album].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.app(.caption)).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            if tr.durationSeconds > 0 {
                                Text(formatDuration(tr.durationSeconds)).font(.app(.callout).monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8).padding(.horizontal, 8)
                        .background(idx % 2 == 0 ? Color.primary.opacity(0.03) : .clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .opacity(tr.selected ? 1 : 0.5)
                    }
                }
            }
        }
    }
}

/// 從貼上的文字找出網址（例如分享訊息「快聽這首 https://…」），沒寫 https:// 也自動補上
func normalizeURL(_ input: String) -> String? {
    let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return nil }
    if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
       let m = detector.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
       let u = m.url, let scheme = u.scheme?.lowercased(), scheme == "http" || scheme == "https" {
        return u.absoluteString
    }
    if !text.contains(" "), text.contains("."), let u = URL(string: "https://" + text), u.host != nil {
        return u.absoluteString
    }
    return nil
}

// MARK: - 音訊工具（聲道、去人聲、音量、速度、升降 Key、淡入淡出）

struct AudioToolsSection: View {
    @Binding var options: DownloadOptions
    @State private var expanded = false
    private var fx: Binding<AudioEffects> { $options.effects }

    var body: some View {
        Card {
            Button { withAnimation(.snappy(duration: 0.3)) { expanded.toggle() } } label: {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.white).frame(width: 26, height: 26)
                        .background(AppSettings.shared.theme.gradient, in: RoundedRectangle(cornerRadius: 7))
                    Text(t("fx.title")).font(.app(.headline))
                    if options.effects.isActive {
                        Circle().fill(AppSettings.shared.theme.color).frame(width: 8, height: 8)
                    }
                    Spacer()
                    Image(systemName: "chevron.down").rotationEffect(.degrees(expanded ? 180 : 0))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
              VStack(alignment: .leading, spacing: 14) {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                    GridRow {
                        label("fx.channel", "speaker.wave.2")
                        Picker("", selection: fx.channelMode) {
                            ForEach(ChannelMode.allCases) { Text(t($0.labelKey)).tag($0) }
                        }.pickerStyle(.segmented).labelsHidden()
                    }
                    GridRow {
                        label("fx.balance", "slider.horizontal.below.rectangle")
                        HStack {
                            Text(t("fx.left")).font(.app(.caption))
                            Slider(value: fx.balance, in: -1...1, step: 0.05)
                            Text(t("fx.right")).font(.app(.caption))
                            Text(balanceText).font(.app(.caption).monospacedDigit()).frame(width: 60)
                        }
                    }
                    GridRow {
                        label("fx.volume", "speaker.plus")
                        HStack {
                            Slider(value: fx.volumeDB, in: -12...12, step: 1)
                            Text(String(format: "%+.0f dB", options.effects.volumeDB))
                                .font(.app(.caption).monospacedDigit()).frame(width: 60)
                        }
                    }
                    GridRow {
                        label("fx.pitch", "music.quarternote.3")
                        Stepper(value: fx.pitch, in: -6...6) {
                            Text(options.effects.pitch == 0 ? "0" : String(format: "%+d", options.effects.pitch))
                                .font(.app(.body).monospacedDigit())
                        }
                    }
                    if options.kind == .audio {
                        GridRow {
                            label("fx.speed", "gauge.with.dots.needle.33percent")
                            HStack {
                                Slider(value: fx.speed, in: 0.5...2.0, step: 0.05)
                                Text(String(format: "%.2fx", options.effects.speed))
                                    .font(.app(.caption).monospacedDigit()).frame(width: 60)
                            }
                        }
                    }
                    GridRow {
                        label("fx.fadeIn", "arrow.up.right")
                        HStack(spacing: 20) {
                            Stepper(value: fx.fadeIn, in: 0...10, step: 1) {
                                Text("\(Int(options.effects.fadeIn)) \(t("fx.sec"))").font(.app(.body).monospacedDigit())
                            }
                            label("fx.fadeOut", "arrow.down.right")
                            Stepper(value: fx.fadeOut, in: 0...10, step: 1) {
                                Text("\(Int(options.effects.fadeOut)) \(t("fx.sec"))").font(.app(.body).monospacedDigit())
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: fx.removeVocals) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(t("fx.vocals")).font(.app(.body).weight(.semibold))
                            Text(t("fx.vocalsHint")).font(.app(.caption)).foregroundStyle(.secondary)
                        }
                    }
                    Toggle(t("fx.normalize"), isOn: fx.normalize).font(.app(.body))
                }
                .toggleStyle(.switch)
                HStack {
                    if options.kind == .video {
                        Label(t("fx.videoNote"), systemImage: "info.circle").font(.app(.caption)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(t("fx.reset")) { options.effects = AudioEffects() }
                        .disabled(!options.effects.isActive)
                }
              }
              .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var balanceText: String {
        let b = options.effects.balance
        if abs(b) < 0.01 { return "C" }
        return b < 0 ? "L \(Int(-b * 100))" : "R \(Int(b * 100))"
    }

    private func label(_ key: String, _ icon: String) -> some View {
        Label(t(key), systemImage: icon).font(.app(.callout).weight(.medium)).foregroundStyle(.secondary)
    }
}

// MARK: - 關鍵字搜尋結果

struct SearchResultsSection: View {
    var query: String
    var results: [YTDLP.SearchResult]
    var onPick: (YTDLP.SearchResult) -> Void
    var onQuickAudio: (YTDLP.SearchResult) -> Void

    var body: some View {
        let rec = TrackMatcher.recommend(results)
        Card(title: "\(t("search.title"))：\(query)", icon: "magnifyingglass") {
            Label(t("pl.rule"), systemImage: "checkmark.seal.fill").font(.app(.caption)).foregroundStyle(.secondary)
            VStack(spacing: 8) {
                ForEach(results, id: \.url) { r in
                    row(r, recommended: r.url == rec?.url)
                }
            }
        }
    }

    private func row(_ r: YTDLP.SearchResult, recommended: Bool) -> some View {
        let theme = AppSettings.shared.theme
        return HStack(spacing: 12) {
            AsyncImage(url: r.thumbnail) { img in img.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.15) }
                .frame(width: 120, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    if r.duration > 0 {
                        Text(formatDuration(r.duration)).font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.white).padding(.horizontal, 4).padding(.vertical, 1)
                            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 3)).padding(4)
                    }
                }
            VStack(alignment: .leading, spacing: 5) {
                Text(r.title).font(.app(.body).weight(.semibold)).lineLimit(2)
                HStack(spacing: 6) {
                    if recommended {
                        Label(t("search.recommended"), systemImage: "star.fill")
                            .font(.app(.caption2).weight(.bold)).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(theme.gradient, in: Capsule())
                    }
                    if TrackMatcher.isOfficial(r) {
                        Label(t("search.official"), systemImage: "checkmark.seal.fill")
                            .font(.app(.caption2).weight(.semibold)).foregroundStyle(theme.color)
                    }
                    Text(r.channel).font(.app(.caption)).foregroundStyle(.secondary).lineLimit(1)
                    Text("· \(r.viewCount.formatted()) \(t("new.views"))").font(.app(.caption)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Button(t("search.pick")) { onPick(r) }
                    .buttonStyle(GradientButtonStyle())
                Button { onQuickAudio(r) } label: {
                    Label(t("search.quickAudio"), systemImage: "music.note")
                }
                .controlSize(.small)
            }
        }
        .padding(10)
        .background(recommended ? theme.color.opacity(0.08) : Color.primary.opacity(0.03),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// 讀取平台官方 Logo。請自行從各平台的品牌資源頁下載並遵守其商標使用規範，
/// 放在專案的 logos/ 資料夾（kkbox.png、spotify.png、youtube.png、applemusic.png），
/// scripts/build-app.sh 會把它們複製到 App 裡。
enum SourceLogo {
    static func image(_ name: String) -> NSImage? {
        var candidates: [URL] = []
        for ext in ["png", "pdf", "svg"] {
            if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "logos") { candidates.append(u) }
            // 用 swift run 開發時，從目前資料夾的 logos/ 讀取
            candidates.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("logos/\(name).\(ext)"))
        }
        for u in candidates where FileManager.default.fileExists(atPath: u.path) {
            if let img = NSImage(contentsOf: u) { return img }
        }
        return nil
    }
}
