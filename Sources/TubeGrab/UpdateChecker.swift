import SwiftUI
import Observation

/// 檢查 GitHub Releases 是否有新版本
@MainActor
@Observable
final class UpdateChecker {
    static let shared = UpdateChecker()

    struct Release: Equatable {
        var version: String
        var title: String
        var notes: String
        var pageURL: URL
        var downloadURL: URL?   // .dmg（沒有就用 .zip）
        var published: Date?
    }

    enum State: Equatable {
        case idle, checking
        case upToDate
        case available(Release)
        case noReleases
        case failed(String)
    }

    var state: State = .idle
    /// 有新版本時顯示提示視窗
    var showSheet = false

    private let d = UserDefaults.standard
    private var apiURL: URL? {
        // https://github.com/<owner>/<repo> → https://api.github.com/repos/<owner>/<repo>/releases/latest
        guard let u = URL(string: AppInfo.repoURL), u.pathComponents.count >= 3 else { return nil }
        return URL(string: "https://api.github.com/repos/\(u.pathComponents[1])/\(u.pathComponents[2])/releases/latest")
    }

    var availableRelease: Release? {
        if case .available(let r) = state { return r }
        return nil
    }

    /// 啟動時：一天最多自動檢查一次
    func checkOnLaunch() {
        guard AppSettings.shared.autoCheckUpdates, AppInfo.hasRepo else { return }
        if let last = d.object(forKey: "lastUpdateCheck") as? Date, Date().timeIntervalSince(last) < 24 * 3600 { return }
        Task { await check(manual: false) }
    }

    func check(manual: Bool) async {
        guard let api = apiURL else { return }
        state = .checking
        d.set(Date(), forKey: "lastUpdateCheck")
        var req = URLRequest(url: api, timeoutInterval: 15)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("TubeGrab/\(AppInfo.shortVersion)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if code == 404 { state = .noReleases; return }
            guard code == 200, let r = Self.parse(data) else { state = .failed("HTTP \(code)"); return }
            if Self.isNewer(r.version, than: AppInfo.shortVersion) {
                state = .available(r)
                // 自動檢查時，略過的版本不再提示
                if manual || d.string(forKey: "skippedVersion") != r.version { showSheet = true }
            } else {
                state = .upToDate
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func skip(_ r: Release) {
        d.set(r.version, forKey: "skippedVersion")
        showSheet = false
    }

    // MARK: 解析與比較

    nonisolated static func parse(_ data: Data) -> Release? {
        guard let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = j["tag_name"] as? String,
              let page = (j["html_url"] as? String).flatMap(URL.init(string:)) else { return nil }
        let assets = (j["assets"] as? [[String: Any]]) ?? []
        func asset(_ ext: String) -> URL? {
            assets.first { (($0["name"] as? String) ?? "").lowercased().hasSuffix(ext) }
                .flatMap { ($0["browser_download_url"] as? String).flatMap(URL.init(string:)) }
        }
        let date = (j["published_at"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) }
        return Release(version: normalize(tag), title: (j["name"] as? String) ?? tag,
                       notes: (j["body"] as? String) ?? "", pageURL: page,
                       downloadURL: asset(".dmg") ?? asset(".zip"), published: date)
    }

    /// "v1.2.0" → "1.2.0"
    nonisolated static func normalize(_ v: String) -> String {
        var s = v.trimmingCharacters(in: .whitespaces)
        if s.lowercased().hasPrefix("v") { s.removeFirst() }
        return s
    }

    /// 版本比較：1.10 > 1.9、1.0.1 > 1.0、1.2 == 1.2.0
    nonisolated static func isNewer(_ a: String, than b: String) -> Bool {
        func parts(_ v: String) -> [Int] {
            normalize(v).split(whereSeparator: { $0 == "." || $0 == "-" }).map { Int($0.prefix { $0.isNumber }) ?? 0 }
        }
        let x = parts(a), y = parts(b)
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }
}

/// 有新版本時的提示視窗
struct UpdateSheet: View {
    var release: UpdateChecker.Release
    private var checker = UpdateChecker.shared

    init(release: UpdateChecker.Release) { self.release = release }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AppLogo(size: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("up2.available")).font(.app(.title2))
                    Text("\(AppInfo.shortVersion) → \(release.version)")
                        .font(.app(.headline).monospacedDigit()).foregroundStyle(AppSettings.shared.theme.color)
                    if let d = release.published {
                        Text(d.formatted(date: .long, time: .omitted)).font(.app(.caption)).foregroundStyle(.secondary)
                    }
                }
            }
            if !release.notes.isEmpty {
                Text(t("up2.notes")).font(.app(.headline))
                ScrollView {
                    Text((try? AttributedString(markdown: release.notes,
                                                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(release.notes))
                        .font(.app(.callout))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 260)
                .padding(10)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            }
            Label(t("up2.howto"), systemImage: "info.circle").font(.app(.caption)).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button(t("up2.skip")) { checker.skip(release) }
                Spacer()
                Button(t("up2.later")) { checker.showSheet = false }
                Button {
                    NSWorkspace.shared.open(release.downloadURL ?? release.pageURL)
                    checker.showSheet = false
                } label: { Label(t("up2.download"), systemImage: "arrow.down.circle.fill") }
                .buttonStyle(GradientButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 520)
        .buttonStyle(SoftButtonStyle())
    }
}
