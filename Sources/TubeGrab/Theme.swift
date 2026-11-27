import SwiftUI

// MARK: - 外觀設定選項

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
    var labelKey: String { "look.mode.\(rawValue)" }
    var icon: String {
        switch self { case .system: return "circle.lefthalf.filled"; case .light: return "sun.max.fill"; case .dark: return "moon.fill" }
    }
}

enum AccentTheme: String, CaseIterable, Identifiable {
    case ruby, ocean, violet, forest, sunset, sakura, graphite, custom
    var id: String { rawValue }
    var labelKey: String { "look.theme.\(rawValue)" }

    var colors: [Color] {
        switch self {
        case .ruby: return [Color(red: 0.94, green: 0.20, blue: 0.27), Color(red: 0.98, green: 0.45, blue: 0.25)]
        case .ocean: return [Color(red: 0.10, green: 0.45, blue: 0.95), Color(red: 0.20, green: 0.78, blue: 0.92)]
        case .violet: return [Color(red: 0.49, green: 0.30, blue: 0.96), Color(red: 0.85, green: 0.35, blue: 0.90)]
        case .forest: return [Color(red: 0.10, green: 0.62, blue: 0.42), Color(red: 0.55, green: 0.80, blue: 0.30)]
        case .sunset: return [Color(red: 0.98, green: 0.55, blue: 0.10), Color(red: 0.95, green: 0.30, blue: 0.45)]
        case .sakura: return [Color(red: 0.93, green: 0.42, blue: 0.62), Color(red: 0.98, green: 0.70, blue: 0.75)]
        case .graphite: return [Color(red: 0.32, green: 0.35, blue: 0.40), Color(red: 0.55, green: 0.58, blue: 0.64)]
        case .custom:
            let s = AppSettings.shared
            return [Color(hex: s.customColorA) ?? .purple, Color(hex: s.customColorB) ?? .pink]
        }
    }
    var color: Color { colors[0] }

    /// 漸層：方向與「使用漸層」開關都在「外觀」設定；關掉漸層時用單一顏色
    var gradient: LinearGradient {
        let s = AppSettings.shared
        let c = s.useGradient ? colors : [colors[0], colors[0]]
        let (a, b) = s.gradientDirection.points
        return LinearGradient(colors: c, startPoint: a, endPoint: b)
    }
}

enum FontChoice: String, CaseIterable, Identifiable {
    case standard, rounded, serif, mono
    var id: String { rawValue }
    var labelKey: String { "look.font.\(rawValue)" }
    var design: Font.Design {
        switch self { case .standard: return .default; case .rounded: return .rounded; case .serif: return .serif; case .mono: return .monospaced }
    }
}

/// 字體大小（給長輩用可以調大）
enum TextSize: String, CaseIterable, Identifiable {
    case small, medium, large, xlarge
    var id: String { rawValue }
    var labelKey: String { "look.size.\(rawValue)" }
    var scale: CGFloat {
        switch self { case .small: return 0.92; case .medium: return 1.0; case .large: return 1.15; case .xlarge: return 1.32 }
    }
}

// MARK: - 字體

enum AppTextStyle {
    case largeTitle, title, title2, title3, headline, body, callout, caption, caption2
    var baseSize: CGFloat {
        switch self {
        case .largeTitle: return 28
        case .title: return 24
        case .title2: return 19
        case .title3: return 16
        case .headline: return 14
        case .body: return 14
        case .callout: return 13
        case .caption: return 11.5
        case .caption2: return 10.5
        }
    }
    var defaultWeight: Font.Weight {
        switch self {
        case .largeTitle, .title: return .bold
        case .title2, .headline: return .semibold
        default: return .regular
        }
    }
}

extension Font {
    /// 依「設定 → 外觀」的字型、大小、粗體產生字體
    static func app(_ style: AppTextStyle) -> Font {
        let s = AppSettings.shared
        var weight = style.defaultWeight
        if s.boldText {
            switch weight {
            case .regular: weight = .semibold
            case .semibold: weight = .bold
            default: weight = .heavy
            }
        }
        return .system(size: style.baseSize * s.textSize.scale, weight: weight, design: s.fontChoice.design)
    }
}

// MARK: - 卡片樣式

struct Card<Content: View>: View {
    var title: String? = nil
    var icon: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(AppSettings.shared.theme.gradient, in: RoundedRectangle(cornerRadius: 7))
                    }
                    Text(title).font(.app(.headline))
                }
            }
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07))
        )
    }
}

/// 漸層主要按鈕
struct GradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @State private var hovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(.headline))
            .foregroundStyle(.white)
            .padding(.horizontal, 24).padding(.vertical, 13)
            .frame(minHeight: 44)
            .background(AppSettings.shared.theme.gradient, in: Capsule())
            .shadow(color: AppSettings.shared.theme.color.opacity(enabled ? 0.35 : 0), radius: 8, y: 3)
            .brightness(hovering ? 0.06 : 0)
            .opacity(enabled ? (configuration.isPressed ? 0.8 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .onHover { hovering = $0 && enabled }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

/// 大型可選擇的方塊（影片 / 音樂）
struct ChoiceTile: View {
    var title: String
    var icon: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 24 * AppSettings.shared.textSize.scale, weight: .semibold))
                Text(title).font(.app(.headline))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .foregroundStyle(selected ? .white : .primary)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? AnyShapeStyle(AppSettings.shared.theme.gradient) : AnyShapeStyle(Color.primary.opacity(0.05)))
            }
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(selected ? Color.clear : Color.primary.opacity(0.1)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: selected)
    }
}

/// 小標籤
struct Pill: View {
    var text: String
    var icon: String? = nil
    var body: some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.app(.caption))
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Color.primary.opacity(0.07), in: Capsule())
    }
}

// MARK: - App 圖示

enum AppIcon {
    /// App 圖示（.app 內的 Resources/AppIcon.png；用 swift run 時讀 assets/AppIcon.png）
    static let image: NSImage? = {
        if let u = Bundle.main.url(forResource: "AppIcon", withExtension: "png"), let i = NSImage(contentsOf: u) { return i }
        let dev = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("assets/AppIcon.png")
        return NSImage(contentsOf: dev)
    }()
}

/// 介面上顯示的 App Logo；找不到圖檔時用原本的漸層方塊
struct AppLogo: View {
    var size: CGFloat
    var body: some View {
        if let img = AppIcon.image {
            Image(nsImage: img)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                // 圖檔四周留有 macOS 標準邊距，放大一點讓視覺大小一致
                .scaleEffect(1.22)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.system(size: size * 0.45, weight: .bold)).foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(AppSettings.shared.theme.gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        }
    }
}

/// 漸層方向
enum GradientDirection: String, CaseIterable, Identifiable {
    case diagonal, diagonalUp, horizontal, vertical
    var id: String { rawValue }
    var labelKey: String { "look.dir.\(rawValue)" }
    var icon: String {
        switch self {
        case .diagonal: return "arrow.down.right"
        case .diagonalUp: return "arrow.up.right"
        case .horizontal: return "arrow.right"
        case .vertical: return "arrow.down"
        }
    }
    var points: (UnitPoint, UnitPoint) {
        switch self {
        case .diagonal: return (.topLeading, .bottomTrailing)
        case .diagonalUp: return (.bottomLeading, .topTrailing)
        case .horizontal: return (.leading, .trailing)
        case .vertical: return (.top, .bottom)
        }
    }
}

extension Color {
    /// "#RRGGBB" → Color
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespaces)
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        self.init(red: Double(v >> 16 & 0xFF) / 255, green: Double(v >> 8 & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
    }

    /// Color → "#RRGGBB"
    var hexString: String {
        let c = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return String(format: "#%02X%02X%02X", Int((c.redComponent * 255).rounded()),
                      Int((c.greenComponent * 255).rounded()), Int((c.blueComponent * 255).rounded()))
    }
}
