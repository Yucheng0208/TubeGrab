import SwiftUI
import Observation

/// 依視窗大小調整介面：
/// - scale：文字、按鈕、間距跟著視窗等比例放大縮小（1280 寬 = 1.0，範圍 0.85～1.6）
/// - isCompact：頁面區域太窄時改用直排、選單等不會被截斷的排版
@Observable
final class LayoutState: @unchecked Sendable {
    static let shared = LayoutState()

    private(set) var windowWidth: CGFloat = 1280
    private(set) var contentWidth: CGFloat = 1030
    private(set) var rawScale: CGFloat = 1

    /// 實際使用的比例（可在「外觀」關閉）
    var scale: CGFloat {
        let s = AppSettings.shared
        return (s.scaleWithWindow ? rawScale : 1) * CGFloat(s.uiZoom)
    }
    /// 頁面區域太窄
    var isCompact: Bool { contentWidth < 780 * scale }
    /// 視窗太窄時，側欄改成浮在頁面上
    var isNarrowWindow: Bool { windowWidth < 820 }

    func update(windowWidth w: CGFloat, contentWidth c: CGFloat) {
        if abs(windowWidth - w) > 0.5 { windowWidth = w }
        if abs(contentWidth - c) > 0.5 { contentWidth = c }
        // 以 0.05 為一級，拖動視窗時不會每一個像素都重排
        let q = (min(max(w / 1280, 0.85), 1.6) * 20).rounded() / 20
        if q != rawScale { rawScale = q }
    }
}

/// 依介面比例換算尺寸
func ui(_ v: CGFloat) -> CGFloat { v * LayoutState.shared.scale }

/// 按鈕用：再乘上「按鈕大小」
func btn(_ v: CGFloat) -> CGFloat { ui(v) * AppSettings.shared.buttonSize.scale }

/// 介面比例的快捷鍵（⌘+ ⌘− ⌘0）
enum Zoom {
    static let steps: [Double] = [0.8, 0.9, 1.0, 1.1, 1.25, 1.4, 1.5]
    static func zoomIn() { let z = AppSettings.shared.uiZoom; AppSettings.shared.uiZoom = steps.first { $0 > z + 0.001 } ?? 1.5 }
    static func zoomOut() { let z = AppSettings.shared.uiZoom; AppSettings.shared.uiZoom = steps.last { $0 < z - 0.001 } ?? 0.8 }
    static func reset() { AppSettings.shared.uiZoom = 1.0 }
}

/// 窄畫面用選單、寬畫面用分段按鈕
struct AdaptivePickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        if LayoutState.shared.isCompact {
            content.pickerStyle(.menu)
        } else {
            content.pickerStyle(.segmented)
        }
    }
}

extension View {
    func adaptivePickerStyle() -> some View { modifier(AdaptivePickerStyle()) }
}

/// 寬的時候橫排、窄的時候直排
struct AdaptiveStack<Content: View>: View {
    var spacing: CGFloat = 10
    var alignment: HorizontalAlignment = .leading
    @ViewBuilder var content: Content

    var body: some View {
        if LayoutState.shared.isCompact {
            VStack(alignment: alignment, spacing: spacing) { content }
        } else {
            HStack(spacing: spacing) { content }
        }
    }
}
