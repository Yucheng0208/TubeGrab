import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 用 `swift run` 直接執行時也能顯示成一般視窗 App
        NSApp.setActivationPolicy(.regular)
        // 用 swift run 執行時 Dock 也顯示正確的圖示
        if let icon = AppIcon.image { NSApp.applicationIconImage = icon }
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
                .frame(minWidth: 1100, minHeight: 760)
        }
        .defaultSize(width: 1280, height: 880)
        .windowResizability(.contentMinSize)
    }
}

struct ContentView: View {
    /// 側欄是否顯示。用 @State 才有動畫（@AppStorage 的變更不會帶動畫），另外存起來記住上次狀態
    @State private var sidebarVisible = UserDefaults.standard.object(forKey: "sidebarVisible") as? Bool ?? true
    private let sidebarWidth: CGFloat = 250
    /// 視窗標題列（紅綠燈那一列）的高度
    private let titleBarHeight: CGFloat = 52
    private var router = AppRouter.shared
    private var settings = AppSettings.shared
    private var manager = DownloadManager.shared

    var body: some View {
        @Bindable var router = router
        // 自己做的側欄：收合 / 展開時整個側欄往左滑出、頁面同步推開
        //（系統的 NavigationSplitView 在 macOS 上是把側欄「裁掉、被頁面蓋住」，看起來卡卡的）
        HStack(spacing: 0) {
            sidebar
                .frame(width: sidebarWidth)
                .frame(width: sidebarVisible ? sidebarWidth : 0, alignment: .trailing)
                .clipped()
            Divider().opacity(sidebarVisible ? 1 : 0)
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.smooth(duration: 0.32)) { sidebarVisible.toggle() }
                    UserDefaults.standard.set(sidebarVisible, forKey: "sidebarVisible")
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .help(sidebarVisible ? t("side.hide") : t("side.show"))
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }
        .navigationTitle(t(router.section.titleKey))
        // 外觀：深色 / 淺色 / 系統、主題色、字型、粗體
        .tint(settings.theme.color)
        .fontDesign(settings.fontChoice.design)
        .font(.app(.body))
        // 整體按鈕、選單、開關都用大一號
        .controlSize(.large)
        .id("\(settings.language.rawValue)-\(settings.textSize.rawValue)-\(settings.boldText)-\(settings.fontChoice.rawValue)")
        .onChange(of: settings.appearance, initial: true) { _, mode in
            // 只在 App 層級設定外觀：nil = 跟隨系統。
            // （SwiftUI 的 preferredColorScheme 在 macOS 上一旦設過深色/淺色，改回 nil 不會還原，所以不用它）
            let appearance: NSAppearance? = mode == .system ? nil : NSAppearance(named: mode == .dark ? .darkAqua : .aqua)
            NSApp.appearance = appearance
            for w in NSApp.windows { w.appearance = appearance }
        }
    }

    // MARK: 側欄

    private var sidebar: some View {
        @Bindable var router = router
        return VStack(spacing: 0) {
            // 標誌與下載進度都掛在清單上（safeAreaInset），收合 / 展開時跟清單一起移動
            List(selection: $router.section) {
                Section(t("side.download")) {
                    sidebarRow(.new, t("nav.new"), "plus.circle.fill")
                    sidebarRow(.search, t("nav.search"), "magnifyingglass.circle.fill")
                    sidebarRow(.batch, t("nav.batch"), "music.note.list")
                    sidebarRow(.queue, t("nav.queue"), "arrow.down.circle.fill",
                               badge: manager.tasks.filter { !$0.status.isFinished }.count)
                }
                Section(t("side.settings")) {
                    sidebarRow(.appearance, t("nav.appearance"), "paintpalette.fill")
                    sidebarRow(.settings, t("nav.prefs"), "gearshape.fill")
                }
                Section(t("side.support")) {
                    sidebarRow(.help, t("nav.help"), "questionmark.circle.fill")
                    sidebarRow(.about, t("nav.about"), "info.circle.fill")
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .top, spacing: 0) {
                HStack(spacing: 10) {
                    AppLogo(size: 34)
                    Text("TubeGrab").font(.app(.title3).weight(.bold))
                        .lineLimit(1).fixedSize()
                    Spacer(minLength: 0)
                }
                // 側欄自己決定位置（不跟著頁面的標題列變化），所以要自己留出標題列的高度
                .padding(.horizontal, 16).padding(.top, titleBarHeight + 14).padding(.bottom, 12)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
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
                    .contentShape(Rectangle())
                    .onTapGesture { router.go(.queue) }
                }
            }
        }
        // 不管右邊是哪個頁面，側欄都固定在同一個位置（不同頁面的標題列高度會不同，造成側欄上下跳）
        .ignoresSafeArea(edges: .top)
        .background(SidebarMaterial().ignoresSafeArea())
    }

    // MARK: 頁面

    private var detail: some View {
            // 一次只顯示一個頁面（內容存在 PageStores，切回來仍保留）
            Group {
                switch router.section {
                case .new: NewDownloadView(onAdded: { router.go(.queue) })
                case .search: SearchView()
                case .batch: BatchView()
                case .queue: QueueView()
                case .appearance: AppearanceView()
                case .settings: SettingsView()
                case .help: HelpView()
                case .about: AboutView()
                }
            }
            .id(router.section)
            // 所有沒有指定樣式的一般按鈕都用統一的樣式
            .buttonStyle(SoftButtonStyle())
    }

    /// 側欄的一列。注意：.tag 必須是最外層，否則點了不會被選取（.badge 要放在 .tag 之前）
    private func sidebarRow(_ item: SidebarItem, _ title: String, _ icon: String, badge: Int = 0) -> some View {
        Label {
            Text(title).font(.app(.body).weight(.medium))
        } icon: {
            Image(systemName: icon).foregroundStyle(router.section == item ? AnyShapeStyle(.white) : AnyShapeStyle(settings.theme.gradient))
        }
        .padding(.vertical, 6)
        .badge(badge)
        .tag(item)
    }
}

/// 側欄的半透明背景（和系統側欄相同的材質）
struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .followsWindowActiveState
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {}
}
