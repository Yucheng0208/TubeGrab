import SwiftUI
import Observation

enum SidebarItem: String, Hashable, CaseIterable {
    case new, search, batch, queue, appearance, settings, help, about

    var titleKey: String {
        switch self {
        case .new: return "nav.new"
        case .search: return "nav.search"
        case .batch: return "nav.batch"
        case .queue: return "nav.queue"
        case .appearance: return "nav.appearance"
        case .settings: return "nav.prefs"
        case .help: return "nav.help"
        case .about: return "nav.about"
        }
    }
}

/// 側欄頁面切換，以及頁面之間互相轉交工作
/// （例如在「新增下載」貼上歌單網址 → 自動跳到「歌單批次下載」並開始讀取）
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()

    var section: SidebarItem = .new

    /// 交給「新增下載」讀取的網址
    var pendingDownloadURL: String?
    /// 交給「搜尋歌曲」的關鍵字
    var pendingSearch: String?
    /// 交給「歌單批次下載」的網址 / 文字清單 / 已讀好的清單
    var pendingBatchURL: String?
    var pendingBatchText: String?
    var pendingBatchList: (name: String, tracks: [PlaylistTrack])?
    var openListSheet = false

    func openDownload(_ url: String) {
        pendingDownloadURL = url
        section = .new
    }

    func openSearch(_ query: String) {
        pendingSearch = query
        section = .search
    }

    func openBatch(url: String? = nil, text: String? = nil,
                   list: (name: String, tracks: [PlaylistTrack])? = nil, showListSheet: Bool = false) {
        pendingBatchURL = url
        pendingBatchText = text
        pendingBatchList = list
        openListSheet = showListSheet
        section = .batch
    }

    func go(_ item: SidebarItem) {
        section = item
    }
}
