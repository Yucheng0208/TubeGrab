import SwiftUI
import UniformTypeIdentifiers

/// 一般按鈕：圓角、帶主題色的淡底、滑過與按下有回饋；刪除類按鈕顯示紅色
struct SoftButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        let destructive = configuration.role == .destructive
        let tint = destructive ? Color.red : AppSettings.shared.theme.color
        return configuration.label
            .font(.app(.body).weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 16).padding(.vertical, 9)
            .frame(minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.26 : (hovering ? 0.18 : 0.11)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(tint.opacity(hovering ? 0.35 : 0.18), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .opacity(enabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .onHover { hovering = $0 && enabled }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

/// 漸層橫幅上的按鈕：半透明白底（次要）或白底主題色字（主要）
struct HeroButtonStyle: ButtonStyle {
    var primary = false
    @Environment(\.isEnabled) private var enabled
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(.headline))
            .foregroundStyle(primary ? AppSettings.shared.theme.color : .white)
            .padding(.horizontal, primary ? 24 : 18).padding(.vertical, 14)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(primary ? Color.white : Color.white.opacity(configuration.isPressed ? 0.34 : (hovering ? 0.3 : 0.22)))
            )
            .shadow(color: .black.opacity(primary && enabled ? 0.12 : 0), radius: 6, y: 3)
            .opacity(enabled ? 1 : 0.55)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .onHover { hovering = $0 && enabled }
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// 頁首的漸層輸入橫幅（搜尋歌曲、歌單批次下載共用）
struct HeroInputBar<Actions: View, Footer: View>: View {
    var icon: String
    var title: String
    var subtitle: String
    var placeholder: String
    var fieldIcon: String = "link"
    @Binding var text: String
    var onSubmit: () -> Void
    @ViewBuilder var actions: Actions
    @ViewBuilder var footer: Footer

    var body: some View {
        let theme = AppSettings.shared.theme
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.app(.title)).foregroundStyle(.white)
                    Text(subtitle).font(.app(.callout)).foregroundStyle(.white.opacity(0.88))
                }
            }
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: fieldIcon).foregroundStyle(.secondary)
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain).font(.app(.title3))
                        .onSubmit(onSubmit)
                    if !text.isEmpty {
                        Button { text = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 15)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                actions
            }
            footer
        }
        .padding(22)
        .background(theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: theme.color.opacity(0.3), radius: 10, y: 5)
    }
}

extension HeroInputBar where Footer == EmptyView {
    init(icon: String, title: String, subtitle: String, placeholder: String, fieldIcon: String = "link",
         text: Binding<String>, onSubmit: @escaping () -> Void, @ViewBuilder actions: () -> Actions) {
        self.init(icon: icon, title: title, subtitle: subtitle, placeholder: placeholder, fieldIcon: fieldIcon,
                  text: text, onSubmit: onSubmit, actions: actions, footer: { EmptyView() })
    }
}
