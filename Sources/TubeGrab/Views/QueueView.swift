import SwiftUI
import AppKit

/// 漸層進度條；value == nil 時顯示來回移動的「處理中」動畫
struct GradientProgressBar: View {
    var value: Double?
    var height: CGFloat = 10
    @State private var phase: CGFloat = -0.4

    var body: some View {
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
                    VStack(spacing: 14) {
                        Image(systemName: "tray")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(AppSettings.shared.theme.gradient)
                            .frame(width: 100, height: 100)
                            .background(AppSettings.shared.theme.color.opacity(0.1), in: Circle())
                        Text(t("q.empty")).font(.app(.title3)).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity).padding(.top, 120)
                } else {
                    summary
                    ForEach(manager.tasks) { task in
                        TaskRow(task: task)
                            .contextMenu {
                                if task.outputFile != nil {
                                    Button(t("q.reveal")) {
                                        if let f = task.outputFile { NSWorkspace.shared.activateFileViewerSelecting([f]) }
                                    }
                                }
                                Button(t("q.remove"), role: .destructive) { manager.remove(task) }
                            }
                            .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 940)
            .frame(maxWidth: .infinity)
            .animation(.spring(duration: 0.35), value: manager.tasks.map(\.id))
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(t("nav.queue"))
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

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(task.displayTitle).font(.app(.headline)).lineLimit(1)
                        Spacer()
                        buttons
                    }
                    HStack(spacing: 6) {
                        Pill(text: formatLabel, icon: task.options.kind == .audio ? "music.note" : "film")
                        if !task.metadata.artist.isEmpty { Pill(text: task.metadata.artist, icon: "music.mic") }
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
                GradientProgressBar(value: task.status == .searching ? nil : task.progress, height: 10)
                HStack(spacing: 10) {
                    if task.status == .searching {
                        Text(t("status.searching")).font(.app(.caption))
                    } else {
                        Text("\(Int(task.progress * 100))%").font(.app(.callout).weight(.bold).monospacedDigit())
                            .foregroundStyle(AppSettings.shared.theme.color)
                        Text(t(task.stageKey)).font(.app(.caption))
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
            Label("\(task.status.label): \(msg)", systemImage: "xmark.octagon.fill")
                .font(.app(.caption)).foregroundStyle(.red).lineLimit(2).textSelection(.enabled)
        case .done:
            VStack(alignment: .leading, spacing: 5) {
                GradientProgressBar(value: 1, height: 10)
                Label(task.status.label, systemImage: "checkmark.circle.fill")
                    .font(.app(.caption).weight(.semibold)).foregroundStyle(.green)
            }
        case .waiting:
            VStack(alignment: .leading, spacing: 5) {
                GradientProgressBar(value: 0, height: 10)
                Label(task.status.label, systemImage: "hourglass").font(.app(.caption)).foregroundStyle(.secondary)
            }
        case .cancelled:
            Label(task.status.label, systemImage: "stop.circle").font(.app(.caption)).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var buttons: some View {
        HStack(spacing: 6) {
            switch task.status {
            case .done:
                Button(t("q.open")) { if let f = task.outputFile { NSWorkspace.shared.open(f) } }
                Button { if let f = task.outputFile { NSWorkspace.shared.activateFileViewerSelecting([f]) } } label: {
                    Image(systemName: "folder")
                }.help(t("q.reveal"))
            case .failed, .cancelled:
                Button(t("q.retry")) { manager.retry(task) }
            case .waiting, .searching, .downloading, .processing:
                Button(t("q.cancel")) { manager.cancel(task) }
            }
            Button(role: .destructive) { manager.remove(task) } label: { Image(systemName: "trash") }
                .help(t("q.remove"))
        }
        .controlSize(.small)
    }
}
