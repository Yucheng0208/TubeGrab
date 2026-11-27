import SwiftUI

/// 側欄「外觀」：深色 / 淺色 / 系統、主題配色、字型、字體大小、粗體
struct AppearanceView: View {
    @Bindable private var s = AppSettings.shared

    var body: some View {
        Form {
            Section {
                // 深色 / 淺色 / 跟隨系統
                LabeledContent {
                    Picker("", selection: $s.appearance) {
                        ForEach(AppearanceMode.allCases) { m in
                            Label(t(m.labelKey), systemImage: m.icon).tag(m)
                        }
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
                } label: { Label(t("look.mode"), systemImage: "circle.lefthalf.filled") }

                // 主題配色色票
                LabeledContent {
                    HStack(spacing: 10) {
                        ForEach(AccentTheme.allCases.filter { $0 != .custom }) { th in
                            Button { withAnimation(.snappy(duration: 0.25)) { s.theme = th } } label: {
                                Circle().fill(th.gradient)
                                    .frame(width: 26, height: 26)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: s.theme == th ? 3 : 0))
                                    .overlay(Circle().strokeBorder(th.color, lineWidth: s.theme == th ? 1.5 : 0).padding(-3))
                                    .shadow(color: th.color.opacity(0.4), radius: s.theme == th ? 4 : 0)
                            }
                            .buttonStyle(.plain)
                            .help(t(th.labelKey))
                        }
                        // 自訂
                        Button { withAnimation(.snappy(duration: 0.25)) { s.theme = .custom } } label: {
                            ZStack {
                                Circle().fill(AngularGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red], center: .center))
                                Image(systemName: "plus").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                                    .shadow(radius: 1)
                            }
                            .frame(width: 26, height: 26)
                            .overlay(Circle().strokeBorder(.white, lineWidth: s.theme == .custom ? 3 : 0))
                            .overlay(Circle().strokeBorder(Color.primary.opacity(0.5), lineWidth: s.theme == .custom ? 1.5 : 0).padding(-3))
                        }
                        .buttonStyle(.plain)
                        .help(t("look.theme.custom"))
                    }
                } label: { Label(t("look.theme"), systemImage: "paintpalette") }

                if s.theme == .custom {
                    LabeledContent {
                        HStack(spacing: 14) {
                            ColorPicker(t("look.colorA"), selection: Binding(
                                get: { Color(hex: s.customColorA) ?? .purple },
                                set: { s.customColorA = $0.hexString }), supportsOpacity: false)
                            ColorPicker(t("look.colorB"), selection: Binding(
                                get: { Color(hex: s.customColorB) ?? .pink },
                                set: { s.customColorB = $0.hexString }), supportsOpacity: false)
                                .disabled(!s.useGradient)
                            Button {
                                let a = s.customColorA; s.customColorA = s.customColorB; s.customColorB = a
                            } label: { Image(systemName: "arrow.left.arrow.right") }
                            .help(t("look.swap"))
                            .disabled(!s.useGradient)
                        }
                    } label: { Label(t("look.theme.custom"), systemImage: "eyedropper.halffull") }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Toggle(isOn: $s.useGradient.animation(.snappy(duration: 0.25))) {
                    Label(t("look.gradient"), systemImage: "circle.lefthalf.striped.horizontal")
                }
                .toggleStyle(.switch)

                if s.useGradient {
                    LabeledContent {
                        Picker("", selection: $s.gradientDirection) {
                            ForEach(GradientDirection.allCases) { d in
                                Label(t(d.labelKey), systemImage: d.icon).tag(d)
                            }
                        }
                        .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 420)
                    } label: { Label(t("look.direction"), systemImage: "arrow.up.and.down.and.arrow.left.and.right") }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // 色彩預覽條
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(s.theme.gradient)
                    .frame(height: 44)
                    .overlay(Text("TubeGrab").font(.app(.headline)).foregroundStyle(.white).shadow(radius: 2))
                    .animation(.easeOut(duration: 0.25), value: s.customColorA + s.customColorB + s.gradientDirection.rawValue + "\(s.useGradient)")

                Picker(selection: $s.fontChoice) {
                    ForEach(FontChoice.allCases) { f in
                        Text(t(f.labelKey)).font(.system(size: 13, design: f.design)).tag(f)
                    }
                } label: { Label(t("look.font"), systemImage: "textformat") }

                LabeledContent {
                    Picker("", selection: $s.textSize) {
                        ForEach(TextSize.allCases) { Text(t($0.labelKey)).tag($0) }
                    }
                    .pickerStyle(.segmented).labelsHidden().frame(maxWidth: 320)
                } label: { Label(t("look.size"), systemImage: "textformat.size") }

                Toggle(isOn: $s.boldText) { Label(t("look.bold"), systemImage: "bold") }
                    .toggleStyle(.switch)

                // 即時預覽
                HStack(spacing: 12) {
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(s.theme.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TubeGrab").font(.app(.title3).weight(.bold))
                        Text(t("look.preview")).font(.app(.body)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    GradientProgressBar(value: 0.62, height: 8, showsPercent: true).frame(width: 170)
                }
                .padding(.vertical, 4)
            } header: { Text(t("look.section")) }
        }
        .formStyle(.grouped)
    }
}
