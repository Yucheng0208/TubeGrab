import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 用 `swift run` 直接執行時也能顯示成一般視窗 App
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct TubeGrabApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup("TubeGrab") {
            ContentView()
                .frame(minWidth: 900, minHeight: 640)
        }
        .windowResizability(.contentMinSize)
    }
}

enum SidebarItem: String, Hashable, CaseIterable {
    case new, queue, settings, about
}

struct ContentView: View {
    @State private var section: SidebarItem = .new
    private var settings = AppSettings.shared
    private var manager = DownloadManager.shared

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // App 標誌
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.to.line.compact")
                        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(settings.theme.gradient, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    Text("TubeGrab").font(.app(.title3).weight(.bold))
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 10)

                List(selection: $section) {
                    sidebarRow(.new, t("nav.new"), "plus.circle.fill")
                    sidebarRow(.queue, t("nav.queue"), "arrow.down.circle.fill")
                        .badge(manager.tasks.filter { !$0.status.isFinished }.count)
                    sidebarRow(.settings, t("nav.settings"), "gearshape.fill")
                    sidebarRow(.about, t("nav.about"), "info.circle.fill")
                }
                .listStyle(.sidebar)

                // 側邊欄底部：目前整體下載進度
                if manager.tasks.contains(where: { $0.status.isActive }) {
                    let active = manager.tasks.filter { $0.status.isActive }
                    let p = active.map(\.progress).reduce(0, +) / Double(max(active.count, 1))
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(t("status.downloading")).font(.app(.caption).weight(.semibold))
                            Spacer()
                            Text("\(Int(p * 100))%").font(.app(.caption).monospacedDigit())
                        }
                        GradientProgressBar(value: p, height: 6)
                    }
                    .padding(14)
                    .onTapGesture { section = .queue }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            switch section {
            case .new: NewDownloadView(onAdded: { section = .queue })
            case .queue: QueueView()
            case .settings: SettingsView()
            case .about: AboutView()
            }
        }
        // 外觀：深色 / 淺色 / 系統、主題色、字型、粗體
        .preferredColorScheme(settings.appearance.colorScheme)
        .tint(settings.theme.color)
        .fontDesign(settings.fontChoice.design)
        .font(.app(.body))
        .id("\(settings.language.rawValue)-\(settings.textSize.rawValue)-\(settings.boldText)-\(settings.fontChoice.rawValue)")
        .onChange(of: settings.appearance, initial: true) { _, mode in
            // 讓視窗標題列也一起切換
            NSApp.appearance = mode == .system ? nil : NSAppearance(named: mode == .dark ? .darkAqua : .aqua)
        }
    }

    private func sidebarRow(_ item: SidebarItem, _ title: String, _ icon: String) -> some View {
        Label {
            Text(title).font(.app(.body).weight(.medium))
        } icon: {
            Image(systemName: icon).foregroundStyle(section == item ? AnyShapeStyle(.white) : AnyShapeStyle(settings.theme.gradient))
        }
        .padding(.vertical, 3)
        .tag(item)
    }
}
