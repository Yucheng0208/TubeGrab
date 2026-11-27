import SwiftUI
import AppKit

/// 漸層進度條；value == nil 時顯示來回移動的「處理中」動畫
/// showsPercent = true 時在右邊顯示百分比
struct GradientProgressBar: View {
    var value: Double?
    var height: CGFloat = 10
    var showsPercent = false
    @State private var phase: CGFloat = -0.4

    var body: some View {
        if showsPercent {
            HStack(spacing: 10) {
                bar
                Text(percentText)
                    .font(.app(.callout).weight(.bold).monospacedDigit())
                    .foregroundStyle(AppSettings.shared.theme.color)
                    .frame(minWidth: 46, alignment: .trailing)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.3), value: percentText)
            }
        } else {
            bar
        }
    }

    private var percentText: String {
        let v = min(max(value ?? 0, 0), 1)
        return "\(Int((v * 100).rounded(.down)))%"
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                if let value {
                    Capsule()
                        .fill(AppSettings.shared.theme.gradient)
                        .frame(width: max(height, geo.size.width * min(max(value, 0), 1)))
                        .animation(.easeOut(duration: 0.35), value: value)
                } else {
                    Capsule()
                        .fill(AppSettings.shared.theme.gradient)
                        .frame(width: geo.size.width * 0.3)
                        .offset(x: geo.size.width * phase)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { phase = 0.75 }
                        }
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
    }
}

struct QueueView: View {
    private var manager = DownloadManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if manager.tasks.isEmpty {
                    emptyState
                } else {
                    summary
                    ForEach(manager.tasks) { task in
                        TaskRow(task: task)
                            .contextMenu {
                                if task.outputFile != nil {
                                    Button(t("q.reveal")) {
                                        FileOpener.reveal(task.outputFile)
                                    }
                                }
                                Menu(t("score.find")) {
                                    ForEach(ScoreFinder.sites) { site in
                                        Button(t(site.titleKey)) { ScoreFinder.open(site, title: task.metadata.title, artist: task.metadata.artist) }
                                    }
                                }
                                Divider()
                                Button(t("q.remove"), role: .destructive) { manager.remove(task) }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
            .padding(36)
            .frame(maxWidth: 1160)
            .frame(maxWidth: .infinity)
            .animation(.spring(duration: 0.35), value: manager.tasks.map(\.id))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .toolbar {
            ToolbarItem {
                Button { NSWorkspace.shared.open(AppSettings.shared.outputFolder) } label: {
                    Label(t("q.reveal"), systemImage: "folder")
                }
            }
            ToolbarItem {
                Button(t("q.clearFinished")) { manager.clearFinished() }
                    .disabled(!manager.tasks.contains { $0.status == .done || $0.status == .cancelled })
            }
        }
    }

    /// 沒有任何下載時
    private var emptyState: some View {
        let theme = AppSettings.shared.theme
        return VStack(spacing: 18) {
            Image(systemName: "tray")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(theme.gradient)
                .frame(width: 110, height: 110)
                .background(theme.color.opacity(0.1), in: Circle())
            VStack(spacing: 6) {
                Text(t("q.emptyTitle")).font(.app(.title2))
                Text(t("q.emptyBody")).font(.app(.body)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 12) {
                Button { AppRouter.shared.go(.new) } label: { Label(t("nav.new"), systemImage: "plus.circle.fill") }
                    .buttonStyle(GradientButtonStyle())
                Button { AppRouter.shared.go(.search) } label: { Label(t("nav.search"), systemImage: "magnifyingglass") }
                Button { AppRouter.shared.go(.batch) } label: { Label(t("nav.batch"), systemImage: "music.note.list") }
            }
            Button { NSWorkspace.shared.open(AppSettings.shared.outputFolder) } label: {
                Label(t("q.openFolder"), systemImage: "folder")
            }
            .buttonStyle(.link)
        }
        .frame(maxWidth: .infinity).padding(.top, 90)
    }

    /// 上方的整體進度卡片
    private var summary: some View {
        let active = manager.tasks.filter { $0.status.isActive || $0.status == .waiting }.count
        let done = manager.tasks.filter { $0.status == .done }.count
        let total = manager.tasks.filter { $0.status != .cancelled }
        let overall = total.isEmpty ? 0 : total.map { $0.status == .done ? 1 : $0.progress }.reduce(0, +) / Double(total.count)
        return Card {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle().stroke(Color.primary.opacity(0.08), lineWidth: 8)
                    Circle().trim(from: 0, to: overall)
                        .stroke(AppSettings.shared.theme.gradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.4), value: overall)
                    Text("\(Int(overall * 100))%").font(.app(.headline).monospacedDigit())
                }
                .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 8) {
                    Text(t("q.total")).font(.app(.title3).weight(.semibold))
                    GradientProgressBar(value: overall, height: 12)
                    HStack(spacing: 8) {
                        Pill(text: "\(active) \(t("q.active"))", icon: "arrow.down.circle")
                        Pill(text: "\(done) \(t("q.doneCount"))", icon: "checkmark.circle")
                    }
                }
            }
        }
    }
}

struct TaskRow: View {
    var task: DownloadTask
    private var manager: DownloadManager { DownloadManager.shared }
    @State private var hovering = false
    @State private var cursorPushed = false

    var body: some View {
        Card {
            HStack(alignment: .top, spacing: 14) {
                AsyncImage(url: task.thumbnail) { img in img.resizable().scaledToFill() } placeholder: {
                    ZStack {
                        AppSettings.shared.theme.gradient.opacity(0.25)
                        Image(systemName: task.options.kind == .audio ? "music.note" : "film")
                            .font(.title2).foregroundStyle(.white)
                    }
                }
                .frame(width: 112, height: 63)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    if task.status == .done {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 26)).foregroundStyle(.white)
                            .shadow(radius: 4)
                            .opacity(hovering ? 1 : 0.75)
                    }
                }
                .onTapGesture { if task.status == .done { FileOpener.open(task.outputFile) } }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(task.displayTitle).font(.app(.headline)).lineLimit(1)
                            .foregroundStyle(task.status == .done && hovering ? AppSettings.shared.theme.color : .primary)
                            .onTapGesture { if task.status == .done { FileOpener.open(task.outputFile) } }
                        Spacer()
                        buttons
                    }
                    HStack(spacing: 6) {
                        Pill(text: formatLabel, icon: task.options.kind == .audio ? "music.note" : "film")
                        if !task.metadata.artist.isEmpty { Pill(text: task.metadata.artist, icon: "music.mic") }
                        if let found = task.lyricsFound {
                            Pill(text: found ? t("ly.pillFound") : t("ly.pillNone"), icon: found ? "quote.bubble.fill" : "quote.bubble")
                        }
                        if task.options.trimEnabled {
                            Pill(text: "\(formatDuration(task.options.trimStart))–\(formatDuration(task.options.trimEnd))", icon: "scissors")
                        }
                    }
                    if !task.sourceNote.isEmpty {
                        Label("YouTube: \(task.sourceNote)", systemImage: "checkmark.seal")
                            .font(.app(.caption2)).foregroundStyle(.secondary).lineLimit(1)
                    }
                    statusArea
                }
            }
        }
        .contentShape(Rectangle())
        // 完成的項目：點兩下整列也能打開
        .onTapGesture(count: 2) { if task.status == .done { FileOpener.open(task.outputFile) } }
        .onHover { h in
            withAnimation(.easeOut(duration: 0.15)) { hovering = h }
            // 只在完成的項目上顯示手指游標，離開時一定還原
            if h && task.status == .done && !cursorPushed { NSCursor.pointingHand.push(); cursorPushed = true }
            if !h && cursorPushed { NSCursor.pop(); cursorPushed = false }
        }
        .help(task.status == .done ? t("q.openHint") : "")
    }

    /// 回報問題時附上的下載設定（不含檔名與網址以外的個人資訊）
    private var reportContext: String {
        var lines = ["- \(t("opt.kind")): \(formatLabel)"]
        if let u = task.url { lines.append("- URL: \(u)") }
        if task.options.trimEnabled { lines.append("- Trim: \(formatDuration(task.options.trimStart))–\(formatDuration(task.options.trimEnd))") }
        if task.options.effects.isActive { lines.append("- Audio tools: on") }
        if task.options.kind == .video && task.options.upscaleHeight > 0 { lines.append("- Upscale: \(task.options.upscaleHeight)p") }
        if task.options.kind == .video && task.options.aspect != .original { lines.append("- Aspect: \(task.options.aspect.rawValue) / \(task.options.padStyle.rawValue)") }
        return lines.joined(separator: "\n")
    }

    private var formatLabel: String {
        task.options.kind == .audio
            ? task.options.audioFormat.rawValue.uppercased()
            : "\(task.options.container.rawValue.uppercased()) · \(task.options.maxHeight == 0 ? t("opt.best") : "\(task.options.maxHeight)p")"
    }

    @ViewBuilder private var statusArea: some View {
        switch task.status {
        case .downloading, .processing, .searching:
            VStack(alignment: .leading, spacing: 5) {
                GradientProgressBar(value: task.status == .searching ? nil : task.progress, height: 10, showsPercent: true)
                HStack(spacing: 10) {
                    if task.status == .searching {
                        Text(t("status.searching")).font(.app(.caption))
                    } else {
                        Text(t(task.stageKey)).font(.app(.caption).weight(.medium))
                    }
                    Spacer()
                    if !task.sizeText.isEmpty && task.status == .downloading {
                        Label(task.sizeText, systemImage: "internaldrive").font(.app(.caption).monospacedDigit())
                    }
                    if !task.speed.isEmpty {
                        Label(task.speed, systemImage: "speedometer").font(.app(.caption).monospacedDigit())
                    }
                    if !task.eta.isEmpty {
                        Label(task.eta, systemImage: "clock").font(.app(.caption).monospacedDigit())
                    }
                }
                .foregroundStyle(.secondary)
            }
        case .failed(let msg):
            VStack(alignment: .leading, spacing: 5) {
                if task.progress > 0 { GradientProgressBar(value: task.progress, height: 10, showsPercent: true).opacity(0.5) }
                Label("\(task.status.label): \(msg)", systemImage: "xmark.octagon.fill")
                    .font(.app(.caption)).foregroundStyle(.red).lineLimit(2).textSelection(.enabled)
            }
        case .done:
            VStack(alignment: .leading, spacing: 5) {
                GradientProgressBar(value: 1, height: 10, showsPercent: true)
                Label(task.status.label, systemImage: "checkmark.circle.fill")
                    .font(.app(.caption).weight(.semibold)).foregroundStyle(.green)
            }
        case .waiting:
            VStack(alignment: .leading, spacing: 5) {
                GradientProgressBar(value: 0, height: 10, showsPercent: true)
                Label(task.status.label, systemImage: "hourglass").font(.app(.caption)).foregroundStyle(.secondary)
            }
        case .cancelled:
            HStack(spacing: 8) {
                Label(task.status.label, systemImage: "stop.circle")
                if task.progress > 0 { Text("(\(Int(task.progress * 100))%)").monospacedDigit() }
            }
            .font(.app(.caption)).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var buttons: some View {
        HStack(spacing: 6) {
            switch task.status {
            case .done:
                Button { FileOpener.open(task.outputFile) } label: { Label(t("q.open"), systemImage: "play.fill") }
                    .buttonStyle(GradientButtonStyle())
                Button { FileOpener.reveal(task.outputFile) } label: {
                    Image(systemName: "folder")
                }.help(t("q.reveal"))
            case .failed(let msg):
                Button(t("q.retry")) { manager.retry(task) }
                Button { Feedback.open(.bug, error: msg, context: reportContext) } label: {
                    Label(t("fb.report"), systemImage: "ladybug")
                }
                .help(t("fb.reportHint"))
            case .cancelled:
                Button(t("q.retry")) { manager.retry(task) }
            case .waiting, .searching, .downloading, .processing:
                Button(t("q.cancel")) { manager.cancel(task) }
            }
            Button(role: .destructive) { manager.remove(task) } label: { Image(systemName: "trash") }
                .help(t("q.remove"))
        }
        .controlSize(.regular)
    }
}
