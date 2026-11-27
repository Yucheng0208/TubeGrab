import SwiftUI
import Observation

/// 各頁面的內容存在這裡（而不是頁面自己的 @State），
/// 切換側欄時頁面可以真的移除，回來時內容仍在。
@MainActor @Observable final class NewDownloadStore {
    var urlText = ""
    var loading = false
    var errorText: String?
    var info: MediaInfo?
    var options = DownloadOptions()
    var metadata = TrackMetadata()
}

enum SearchMode: String, CaseIterable { case song, lyrics }

@MainActor @Observable final class SearchStore {
    var mode: SearchMode = .song
    var query = ""
    var results: [YTDLP.SearchResult] = []
    var lastQuery = ""
    var loading = false
    var errorText: String?
}

@MainActor @Observable final class BatchStore {
    var urlText = ""
    var loading = false
    var errorText: String?
    var name = ""
    var tracks: [PlaylistTrack] = []
    var options: DownloadOptions = { var o = DownloadOptions(); o.kind = .audio; return o }()
    var listText = ""
}

@MainActor enum PageStores {
    static let newDownload = NewDownloadStore()
    static let search = SearchStore()
    static let batch = BatchStore()
}
