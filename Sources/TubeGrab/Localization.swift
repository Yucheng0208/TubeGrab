import Foundation

/// 介面語言。可在「設定」中即時切換，不需重新啟動。
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case en
    case ja
    case ko

    var id: String { rawValue }

    /// 顯示在選單上的名稱（永遠以該語言本身顯示）
    var displayName: String {
        switch self {
        case .system: return "System / 系統"
        case .zhHant: return "繁體中文"
        case .zhHans: return "简体中文"
        case .en: return "English"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    /// 將「跟隨系統」解析為實際語言
    var resolved: AppLanguage {
        guard self == .system else { return self }
        for pref in Locale.preferredLanguages {
            let p = pref.lowercased()
            if p.hasPrefix("zh-hant") || p.hasPrefix("zh-tw") || p.hasPrefix("zh-hk") || p.hasPrefix("zh-mo") { return .zhHant }
            if p.hasPrefix("zh") { return .zhHans }
            if p.hasPrefix("ja") { return .ja }
            if p.hasPrefix("ko") { return .ko }
            if p.hasPrefix("en") { return .en }
        }
        return .en
    }
}

/// 簡單的字典式翻譯表。key 找不到時退回英文，再退回 key 本身。
enum L10n {
    // 順序：繁中, 简中, English, 日本語, 한국어
    private static let table: [String: [String]] = [
        // 導覽
        "nav.new": ["新增下載", "新建下载", "New Download", "新規ダウンロード", "새 다운로드"],
        "nav.queue": ["下載清單", "下载列表", "Downloads", "ダウンロード一覧", "다운로드 목록"],
        "nav.settings": ["設定", "设置", "Settings", "設定", "설정"],
        "nav.about": ["關於", "关于", "About", "このアプリについて", "정보"],
        "about.version": ["版本", "版本", "Version", "バージョン", "버전"],
        "about.desc": ["簡單好用的 macOS 影片與音樂下載工具：貼上網址或輸入歌名，選一選就能下載。這是一個 SwiftUI 教學範例專案。", "简单好用的 macOS 视频与音乐下载工具：粘贴链接或输入歌名，选一选就能下载。这是一个 SwiftUI 教学示例项目。", "A simple macOS video & music downloader — paste a link or type a song, pick, and download. A SwiftUI teaching sample.", "URL を貼るか曲名を入力して選ぶだけの、シンプルな macOS 動画・音楽ダウンローダー。SwiftUI の学習用サンプルです。", "주소를 붙여넣거나 곡명을 입력하고 고르기만 하면 되는 간단한 macOS 다운로더. SwiftUI 학습용 예제입니다."],
        "about.notice": ["免責聲明", "免责声明", "Disclaimer", "免責事項", "면책 조항"],
        "about.credits": ["使用的開源專案", "使用的开源项目", "Open-source credits", "使用しているオープンソース", "사용한 오픈소스"],
        "about.feedback": ["回報問題 / 建議", "反馈问题 / 建议", "Report an issue", "不具合・要望を報告", "문제 신고 / 제안"],
        "about.repoSoon": ["GitHub 頁面即將公開", "GitHub 页面即将公开", "GitHub page coming soon", "GitHub ページは近日公開", "GitHub 페이지 곧 공개"],

        "nav.search": ["搜尋歌曲", "搜索歌曲", "Search Songs", "曲を検索", "곡 검색"],
        "nav.batch": ["歌單批次下載", "歌单批量下载", "Batch Download", "一括ダウンロード", "일괄 다운로드"],
        "nav.appearance": ["外觀", "外观", "Appearance", "外観", "모양"],
        "nav.prefs": ["偏好設定", "偏好设置", "Preferences", "環境設定", "환경설정"],
        "nav.help": ["說明", "帮助", "Help", "ヘルプ", "도움말"],
        "side.download": ["下載", "下载", "Download", "ダウンロード", "다운로드"],
        "side.settings": ["設定", "设置", "Settings", "設定", "설정"],
        "side.support": ["支援", "支持", "Support", "サポート", "지원"],
        "search.subtitle": ["輸入歌名或歌手，到 YouTube 找最適合的版本", "输入歌名或歌手，到 YouTube 找最合适的版本", "Type a song or artist to find the best version on YouTube", "曲名やアーティストで YouTube から最適な動画を探します", "곡명이나 가수로 YouTube에서 가장 알맞은 영상을 찾습니다"],
        "search.placeholder": ["例如：周杰倫 晴天", "例如：周杰伦 晴天", "e.g. Jay Chou Sunny Day", "例：YOASOBI アイドル", "예: 아이유 좋은 날"],
        "search.tipsTitle": ["搜尋小技巧", "搜索小技巧", "Search tips", "検索のコツ", "검색 팁"],
        "search.tips": ["同時輸入「歌手＋歌名」最準確；想要現場版可以加上「Live」，想要伴奏可以加上「伴奏」或「Instrumental」。", "同时输入「歌手＋歌名」最准确；想要现场版可以加上「Live」，想要伴奏可以加上「伴奏」或「Instrumental」。", "Artist + title works best. Add “Live” for live versions or “Instrumental” for backing tracks.", "「アーティスト＋曲名」が最も正確。ライブ版は「Live」、伴奏は「Instrumental」を追加。", "‘가수+곡명’이 가장 정확합니다. 라이브는 ‘Live’, 반주는 ‘Instrumental’을 추가하세요."],
        "batch.subtitle": ["一次下載整份歌單：YouTube、Spotify、Apple Music、KKBOX 或任何文字清單", "一次下载整份歌单：YouTube、Spotify、Apple Music、KKBOX 或任何文字列表", "Download whole playlists: YouTube, Spotify, Apple Music, KKBOX or any text list", "プレイリストをまとめて保存：YouTube・Spotify・Apple Music・KKBOX・テキスト", "재생목록 전체 다운로드: YouTube·Spotify·Apple Music·KKBOX·텍스트 목록"],
        "batch.placeholder": ["貼上歌單或專輯網址", "粘贴歌单或专辑链接", "Paste a playlist or album link", "プレイリスト/アルバムの URL を貼り付け", "재생목록 또는 앨범 주소 붙여넣기"],
        "batch.src.youtube": ["播放清單網址（youtube.com/playlist?list=…）", "播放列表链接（youtube.com/playlist?list=…）", "Playlist links (youtube.com/playlist?list=…)", "プレイリスト URL（youtube.com/playlist?list=…）", "재생목록 주소 (youtube.com/playlist?list=…)"],
        "batch.src.spotify": ["公開歌單或專輯；超過 100 首請在偏好設定填 API 金鑰", "公开歌单或专辑；超过 100 首请在偏好设置填 API 密钥", "Public playlists/albums; add an API key in Preferences for 100+ songs", "公開リスト/アルバム。100曲超は環境設定で API キー", "공개 재생목록/앨범, 100곡 초과는 환경설정에 API 키"],
        "batch.src.apple": ["公開歌單或專輯網址", "公开歌单或专辑链接", "Public playlist or album links", "公開プレイリスト/アルバムの URL", "공개 재생목록/앨범 주소"],
        "batch.src.kkbox": ["需要 KKBOX Open API 金鑰，或改用貼上歌單文字", "需要 KKBOX Open API 密钥，或改用粘贴歌单文字", "Needs a KKBOX Open API key, or use Paste song list", "KKBOX Open API キーが必要、または曲リストを貼り付け", "KKBOX Open API 키 필요, 또는 곡 목록 붙여넣기"],
        "batch.src.text": ["從任何 App 複製「每行一首」的清單", "从任何 App 复制「每行一首」的列表", "Copy a one-song-per-line list from any app", "どのアプリからでも「1行1曲」でコピー", "어느 앱에서든 ‘한 줄에 한 곡’ 목록 복사"],
        "batch.ruleTitle": ["自動選最佳版本", "自动选最佳版本", "Best version picked automatically", "最適な動画を自動選択", "최적 버전 자동 선택"],
        "help.subtitle": ["每一步怎麼用，看這裡就對了", "每一步怎么用，看这里就对了", "How to use every feature, step by step", "各機能の使い方をステップごとに", "모든 기능 사용법을 단계별로"],
        "help.search": ["搜尋說明，例如「去人聲」「比例」", "搜索帮助，例如「去人声」「比例」", "Search help, e.g. “vocals”, “ratio”", "ヘルプを検索（例：ボーカル、比率）", "도움말 검색 (예: 보컬, 비율)"],
        "help.expandAll": ["全部展開", "全部展开", "Expand all", "すべて展開", "모두 펼치기"],
        "help.collapseAll": ["全部收合", "全部收起", "Collapse all", "すべて折りたたむ", "모두 접기"],
        "help.goto": ["前往這個功能", "前往这个功能", "Go to this feature", "この機能へ移動", "이 기능으로 이동"],
        "help.none": ["找不到相關說明", "找不到相关帮助", "No matching help topics", "該当するヘルプがありません", "관련 도움말이 없습니다"],

        "side.hide": ["隱藏側欄（⌃⌘S）", "隐藏侧栏（⌃⌘S）", "Hide sidebar (⌃⌘S)", "サイドバーを隠す（⌃⌘S）", "사이드바 숨기기 (⌃⌘S)"],
        "side.show": ["顯示側欄（⌃⌘S）", "显示侧栏（⌃⌘S）", "Show sidebar (⌃⌘S)", "サイドバーを表示（⌃⌘S）", "사이드바 보기 (⌃⌘S)"],

        "nav.lyrics": ["用歌詞找歌", "用歌词找歌", "Find by Lyrics", "歌詞で探す", "가사로 찾기"],
        "new.searchAs": ["要怎麼搜尋？", "要怎么搜索？", "Search by:", "検索方法：", "검색 방법:"],

        // 新增下載
        "new.placeholder": ["貼上網址，或輸入歌名、歌手、歌詞來搜尋", "粘贴链接，或输入歌名、歌手、歌词来搜索", "Paste a link, or type a song, artist or lyrics to search", "URL を貼るか、曲名・アーティスト・歌詞で検索", "주소를 붙여넣거나 곡명·가수·가사로 검색"],
        "new.paste": ["貼上", "粘贴", "Paste", "貼り付け", "붙여넣기"],
        "new.analyze": ["讀取", "读取", "Load", "読み込む", "불러오기"],
        "new.loading": ["讀取中…", "读取中…", "Loading…", "読み込み中…", "불러오는 중…"],
        "new.hint": ["1. 貼上網址 → 2. 按「讀取」→ 3. 選擇影片或音樂與品質 → 4. 按「加入下載」", "1. 粘贴链接 → 2. 点「读取」→ 3. 选择视频或音乐与质量 → 4. 点「加入下载」", "1. Paste a link → 2. Click Load → 3. Pick video or music and quality → 4. Click Add to Downloads", "1. URL を貼り付け → 2.「読み込む」→ 3. 動画/音楽と画質を選択 → 4.「ダウンロードに追加」", "1. 주소 붙여넣기 → 2. ‘불러오기’ → 3. 영상/음악과 품질 선택 → 4. ‘다운로드에 추가’"],
        "new.add": ["加入下載", "加入下载", "Add to Downloads", "ダウンロードに追加", "다운로드에 추가"],
        "new.added": ["已加入下載清單", "已加入下载列表", "Added to downloads", "ダウンロード一覧に追加しました", "다운로드 목록에 추가됨"],
        "new.duration": ["長度", "时长", "Duration", "長さ", "길이"],
        "new.views": ["觀看次數", "播放次数", "Views", "再生回数", "조회수"],
        "new.channel": ["頻道", "频道", "Channel", "チャンネル", "채널"],

        // 類型與品質
        "opt.kind": ["下載類型", "下载类型", "Type", "種類", "유형"],
        "opt.video": ["影片", "视频", "Video", "動画", "영상"],
        "opt.audio": ["音樂（只要聲音）", "音乐（仅音频）", "Music (audio only)", "音楽（音声のみ）", "음악 (오디오만)"],
        "opt.format": ["檔案格式", "文件格式", "Format", "ファイル形式", "파일 형식"],
        "opt.quality": ["品質", "质量", "Quality", "品質", "품질"],
        "opt.best": ["最佳", "最佳", "Best", "最高", "최고"],
        "opt.thumbnail": ["嵌入封面", "嵌入封面", "Embed cover art", "カバー画像を埋め込む", "커버 이미지 삽입"],
        "opt.subtitles": ["下載字幕", "下载字幕", "Download subtitles", "字幕をダウンロード", "자막 다운로드"],

        // 中繼資料
        "meta.title": ["檔案與歌曲資訊（可修改）", "文件与歌曲信息（可修改）", "File & track info (editable)", "ファイルと曲の情報（編集可）", "파일 및 곡 정보 (수정 가능)"],
        "meta.filename": ["檔案名稱", "文件名", "File name", "ファイル名", "파일 이름"],
        "meta.songTitle": ["標題 / 歌名", "标题 / 歌名", "Title", "タイトル / 曲名", "제목 / 곡명"],
        "meta.artist": ["歌手 / 演出者", "歌手 / 艺人", "Artist", "アーティスト", "아티스트"],
        "meta.album": ["專輯", "专辑", "Album", "アルバム", "앨범"],
        "meta.albumArtist": ["專輯演出者", "专辑艺人", "Album artist", "アルバムアーティスト", "앨범 아티스트"],
        "meta.year": ["年份", "年份", "Year", "年", "연도"],
        "meta.genre": ["類型", "流派", "Genre", "ジャンル", "장르"],
        "meta.reset": ["還原成 YouTube 提供的資訊", "还原为 YouTube 提供的信息", "Reset to info from YouTube", "YouTube の情報に戻す", "YouTube 정보로 되돌리기"],

        // 預覽 / 修剪
        "trim.title": ["預覽與修剪", "预览与剪辑", "Preview & Trim", "プレビューとトリミング", "미리보기 및 자르기"],
        "trim.enable": ["只下載其中一段", "只下载其中一段", "Download only a section", "一部分だけダウンロード", "일부 구간만 다운로드"],
        "trim.start": ["開始", "开始", "Start", "開始", "시작"],
        "trim.end": ["結束", "结束", "End", "終了", "끝"],
        "trim.setStart": ["把目前位置設為開始", "将当前位置设为开始", "Set start to current", "現在位置を開始に", "현재 위치를 시작으로"],
        "trim.setEnd": ["把目前位置設為結束", "将当前位置设为结束", "Set end to current", "現在位置を終了に", "현재 위치를 끝으로"],
        "trim.playSection": ["播放這一段", "播放这一段", "Play section", "区間を再生", "구간 재생"],
        "trim.loadPreview": ["載入預覽", "加载预览", "Load preview", "プレビューを読み込む", "미리보기 불러오기"],
        "trim.previewFailed": ["無法載入預覽（仍可正常下載）", "无法加载预览（仍可正常下载）", "Preview unavailable (download still works)", "プレビューを読み込めません（ダウンロードは可能）", "미리보기를 불러올 수 없음 (다운로드는 가능)"],

        // 播放清單
        "pl.title": ["播放清單", "播放列表", "Playlist", "プレイリスト", "재생목록"],
        "pl.tracks": ["首歌曲", "首歌曲", "tracks", "曲", "곡"],
        "pl.downloadAll": ["全部自動下載", "全部自动下载", "Download all automatically", "すべて自動ダウンロード", "모두 자동 다운로드"],
        "pl.downloadSelected": ["下載勾選的歌曲", "下载勾选的歌曲", "Download selected", "選択した曲をダウンロード", "선택한 곡 다운로드"],
        "pl.selectAll": ["全選", "全选", "Select all", "すべて選択", "전체 선택"],
        "pl.selectNone": ["全不選", "全不选", "Select none", "選択解除", "선택 해제"],
        "pl.rule": ["會優先選唱片公司 / 官方頻道的版本；找不到時選觀看次數最高的。", "会优先选择唱片公司 / 官方频道的版本；找不到时选播放次数最高的。", "Prefers record-label / official channel uploads; otherwise picks the most-viewed video.", "レーベル／公式チャンネルを優先し、見つからない場合は再生回数が最も多い動画を選びます。", "음반사/공식 채널 영상을 우선 선택하고, 없으면 조회수가 가장 높은 영상을 선택합니다."],
        "pl.searching": ["正在 YouTube 尋找", "正在 YouTube 搜索", "Searching YouTube", "YouTube で検索中", "YouTube에서 검색 중"],

        // 下載清單
        "q.empty": ["目前沒有下載項目", "当前没有下载项目", "No downloads yet", "ダウンロードはありません", "다운로드 항목이 없습니다"],
        "q.remove": ["移除", "移除", "Remove", "削除", "제거"],
        "q.clearFinished": ["清除已完成", "清除已完成", "Clear finished", "完了したものを消去", "완료 항목 지우기"],
        "q.reveal": ["在 Finder 中顯示", "在访达中显示", "Show in Finder", "Finder で表示", "Finder에서 보기"],
        "q.retry": ["重試", "重试", "Retry", "再試行", "다시 시도"],
        "q.cancel": ["取消", "取消", "Cancel", "キャンセル", "취소"],
        "q.openHint": ["點縮圖或標題、或在這一列點兩下就能打開", "点缩略图或标题、或在这一行双击就能打开", "Click the thumbnail or title, or double-click the row, to open", "サムネイルかタイトルをクリック、または行をダブルクリックで開きます", "썸네일이나 제목을 클릭하거나 행을 두 번 클릭하면 열립니다"],
        "q.open": ["打開", "打开", "Open", "開く", "열기"],
        "status.waiting": ["等待中", "等待中", "Waiting", "待機中", "대기 중"],
        "status.searching": ["尋找最佳來源中", "寻找最佳来源中", "Finding best source", "最適なソースを検索中", "최적 소스 찾는 중"],
        "status.downloading": ["下載中", "下载中", "Downloading", "ダウンロード中", "다운로드 중"],
        "status.processing": ["轉檔 / 寫入資訊中", "转码 / 写入信息中", "Converting / tagging", "変換・タグ書き込み中", "변환 / 태그 기록 중"],
        "status.done": ["完成", "完成", "Done", "完了", "완료"],
        "status.failed": ["失敗", "失败", "Failed", "失敗", "실패"],
        "status.cancelled": ["已取消", "已取消", "Cancelled", "キャンセル済み", "취소됨"],

        "stage.video": ["正在下載影片畫面", "正在下载视频画面", "Downloading video", "映像をダウンロード中", "영상 다운로드 중"],
        "stage.audio": ["正在下載聲音", "正在下载音频", "Downloading audio", "音声をダウンロード中", "오디오 다운로드 중"],
        "stage.merge": ["正在合併影像與聲音", "正在合并视频与音频", "Merging video & audio", "映像と音声を結合中", "영상과 오디오 합치는 중"],
        "stage.convert": ["正在轉換格式", "正在转换格式", "Converting", "変換中", "변환 중"],
        "stage.cover": ["正在嵌入封面", "正在嵌入封面", "Embedding cover", "カバーを埋め込み中", "커버 삽입 중"],
        "stage.tags": ["正在寫入歌曲資訊", "正在写入歌曲信息", "Writing tags", "タグを書き込み中", "태그 기록 중"],
        "q.total": ["整體進度", "整体进度", "Overall progress", "全体の進行状況", "전체 진행률"],
        "q.active": ["個下載中", "个下载中", "in progress", "件ダウンロード中", "개 다운로드 중"],
        "q.doneCount": ["個已完成", "个已完成", "done", "件完了", "개 완료"],

        "q.emptyTitle": ["暫無下載內容", "暂无下载内容", "Nothing here yet", "まだダウンロードはありません", "아직 다운로드가 없습니다"],
        "q.emptyBody": ["加入下載後，會在這裡看到進度與完成的檔案。", "加入下载后，会在这里看到进度与完成的文件。", "Once you add a download, its progress and finished files appear here.", "ダウンロードを追加すると、進行状況と完了したファイルがここに表示されます。", "다운로드를 추가하면 진행 상황과 완료된 파일이 여기에 표시됩니다."],
        "q.openFolder": ["打開下載資料夾", "打开下载文件夹", "Open download folder", "保存フォルダを開く", "다운로드 폴더 열기"],

        // 設定
        "set.language": ["介面語言", "界面语言", "Language", "表示言語", "언어"],
        "set.output": ["下載儲存位置", "下载保存位置", "Save downloads to", "保存先", "저장 위치"],
        "set.choose": ["選擇…", "选择…", "Choose…", "選択…", "선택…"],
        "set.tools": ["外部工具", "外部工具", "External tools", "外部ツール", "외부 도구"],
        "set.ytdlp": ["yt-dlp 路徑", "yt-dlp 路径", "yt-dlp path", "yt-dlp のパス", "yt-dlp 경로"],
        "set.ffmpeg": ["ffmpeg 路徑", "ffmpeg 路径", "ffmpeg path", "ffmpeg のパス", "ffmpeg 경로"],
        "set.autoDetect": ["自動偵測", "自动检测", "Auto-detect", "自動検出", "자동 감지"],
        "set.found": ["已找到", "已找到", "Found", "検出済み", "찾음"],
        "set.missing": ["找不到，請參考 README 安裝", "找不到，请参考 README 安装", "Not found – see README to install", "見つかりません（README を参照）", "찾을 수 없음 – README 참고"],
        "set.concurrent": ["同時下載數量", "同时下载数量", "Simultaneous downloads", "同時ダウンロード数", "동시 다운로드 수"],
        "set.spotify": ["Spotify API（選填，可讀取超過 100 首的清單）", "Spotify API（选填，可读取超过 100 首的列表）", "Spotify API (optional, for playlists over 100 tracks)", "Spotify API（任意・100 曲超のリスト用）", "Spotify API (선택, 100곡 초과 재생목록용)"],
        "set.updateYtdlp": ["更新 yt-dlp", "更新 yt-dlp", "Update yt-dlp", "yt-dlp を更新", "yt-dlp 업데이트"],
        "set.disclaimer": ["本程式僅供教學與範例用途。請只下載你擁有權利或已獲授權的內容，並遵守各平台服務條款與著作權法。本程式依「現狀」提供，不提供任何保證；使用本程式所產生的一切後果由使用者自行承擔，作者不負任何責任。", "本程序仅供教学与示例用途。请只下载你拥有权利或已获授权的内容，并遵守各平台服务条款与著作权法。本程序按「现状」提供，不提供任何保证；使用本程序所产生的一切后果由使用者自行承担，作者不负任何责任。", "For educational / demonstration purposes only. Only download content you own or are authorized to download, and follow each platform’s terms and copyright law. This software is provided “as is” without any warranty; you use it at your own risk and the author accepts no liability.", "本アプリは教育・サンプル目的専用です。権利を持つ、または許可されたコンテンツのみをダウンロードし、各サービスの規約と著作権法を守ってください。本アプリは現状のまま提供され、いかなる保証もありません。使用によって生じた結果はすべて利用者の責任であり、作者は一切の責任を負いません。", "이 앱은 교육 및 예제 용도로만 제공됩니다. 권리가 있거나 허가받은 콘텐츠만 다운로드하고 각 플랫폼 약관과 저작권법을 준수하세요. 이 앱은 ‘있는 그대로’ 제공되며 어떠한 보증도 하지 않습니다. 사용으로 인한 모든 결과는 사용자 본인의 책임이며 작성자는 어떠한 책임도 지지 않습니다."],

        // 外觀
        "look.section": ["外觀", "外观", "Appearance", "外観", "모양"],
        "look.mode": ["顯示模式", "显示模式", "Mode", "表示モード", "화면 모드"],
        "look.mode.system": ["跟隨系統", "跟随系统", "System", "システム", "시스템"],
        "look.mode.light": ["淺色", "浅色", "Light", "ライト", "라이트"],
        "look.mode.dark": ["深色", "深色", "Dark", "ダーク", "다크"],
        "look.theme": ["主題配色", "主题配色", "Color theme", "テーマカラー", "테마 색상"],
        "look.theme.ruby": ["紅寶石", "红宝石", "Ruby", "ルビー", "루비"],
        "look.theme.ocean": ["海洋藍", "海洋蓝", "Ocean", "オーシャン", "오션"],
        "look.theme.violet": ["紫羅蘭", "紫罗兰", "Violet", "バイオレット", "바이올렛"],
        "look.theme.forest": ["森林綠", "森林绿", "Forest", "フォレスト", "포레스트"],
        "look.theme.sunset": ["夕陽橘", "夕阳橘", "Sunset", "サンセット", "선셋"],
        "look.theme.sakura": ["櫻花粉", "樱花粉", "Sakura", "さくら", "벚꽃"],
        "look.theme.graphite": ["石墨灰", "石墨灰", "Graphite", "グラファイト", "그래파이트"],
        "look.font": ["字型", "字体", "Font", "フォント", "글꼴"],
        "look.font.standard": ["標準", "标准", "Standard", "標準", "표준"],
        "look.font.rounded": ["圓體", "圆体", "Rounded", "丸ゴシック", "둥근체"],
        "look.font.serif": ["明體（襯線）", "宋体（衬线）", "Serif", "明朝（セリフ）", "명조(세리프)"],
        "look.font.mono": ["等寬", "等宽", "Monospaced", "等幅", "고정폭"],
        "look.size": ["字體大小", "字体大小", "Text size", "文字サイズ", "글자 크기"],
        "look.size.small": ["小", "小", "Small", "小", "작게"],
        "look.size.medium": ["中", "中", "Medium", "中", "보통"],
        "look.size.large": ["大", "大", "Large", "大", "크게"],
        "look.size.xlarge": ["特大", "特大", "Extra large", "特大", "아주 크게"],
        "look.bold": ["粗體字", "粗体字", "Bold text", "太字", "굵은 글씨"],
        "look.preview": ["預覽：快速下載你喜歡的音樂與影片", "预览：快速下载你喜欢的音乐与视频", "Preview: grab your favorite music and videos", "プレビュー：好きな音楽と動画をすばやく保存", "미리보기: 좋아하는 음악과 영상을 빠르게 저장"],
        "app.tagline": ["貼上網址，選一選，就能下載", "粘贴链接，选一选，就能下载", "Paste a link, pick, and download", "URL を貼って選ぶだけでダウンロード", "주소를 붙여넣고 고르면 다운로드 끝"],
        "pl.import": ["從 Spotify / Apple Music 匯入", "从 Spotify / Apple Music 导入", "Import from Spotify / Apple Music", "Spotify / Apple Music から読み込み", "Spotify / Apple Music에서 가져오기"],

        // 搜尋
        "search.title": ["搜尋結果", "搜索结果", "Search results", "検索結果", "검색 결과"],
        "search.button": ["搜尋", "搜索", "Search", "検索", "검색"],
        "search.pick": ["選這首", "选这首", "Choose", "これを選ぶ", "선택"],
        "search.quickAudio": ["直接下載音樂", "直接下载音乐", "Download as music", "音楽として保存", "음악으로 바로 받기"],
        "search.official": ["官方", "官方", "Official", "公式", "공식"],
        "search.recommended": ["推薦", "推荐", "Recommended", "おすすめ", "추천"],
        "search.none": ["找不到相關影片", "找不到相关视频", "No results found", "見つかりませんでした", "결과가 없습니다"],
        // 音訊工具
        "fx.title": ["音訊工具", "音频工具", "Audio tools", "オーディオツール", "오디오 도구"],
        "fx.reset": ["全部還原", "全部还原", "Reset all", "すべてリセット", "모두 초기화"],
        "fx.channel": ["聲道", "声道", "Channels", "チャンネル", "채널"],
        "fx.ch.stereo": ["立體聲", "立体声", "Stereo", "ステレオ", "스테레오"],
        "fx.ch.leftOnly": ["只用左聲道", "只用左声道", "Left only", "左のみ", "왼쪽만"],
        "fx.ch.rightOnly": ["只用右聲道", "只用右声道", "Right only", "右のみ", "오른쪽만"],
        "fx.ch.swap": ["左右互換", "左右互换", "Swap L/R", "左右入れ替え", "좌우 바꾸기"],
        "fx.ch.mono": ["單聲道", "单声道", "Mono", "モノラル", "모노"],
        "fx.balance": ["左右平衡", "左右平衡", "Balance", "左右バランス", "좌우 밸런스"],
        "fx.left": ["左", "左", "L", "左", "왼쪽"],
        "fx.right": ["右", "右", "R", "右", "오른쪽"],
        "fx.vocals": ["去除人聲（卡拉 OK 伴奏）", "去除人声（卡拉 OK 伴奏）", "Remove vocals (karaoke)", "ボーカル除去（カラオケ）", "보컬 제거 (노래방)"],
        "fx.vocalsHint": ["把正中央的人聲抵消、保留兩側的樂器和低音，並自動補回音量。適合立體聲的錄音室版本；現場版或單聲道錄音效果有限。", "把正中央的人声抵消、保留两侧的乐器和低音，并自动补回音量。适合立体声的录音室版本；现场版或单声道录音效果有限。", "Cancels centered vocals, keeps side instruments and bass, and restores the volume. Best on stereo studio tracks; limited on live or mono recordings.", "ボーカルが中央にあるスタジオ音源向け。ライブやモノラルは効果が弱めです。", "보컬이 중앙에 있는 스튜디오 음원에 적합하며, 라이브/모노 음원은 효과가 약합니다."],
        "fx.volume": ["音量", "音量", "Volume", "音量", "볼륨"],
        "fx.normalize": ["音量標準化（每首一樣大聲）", "音量标准化（每首一样响）", "Normalize loudness", "音量を均一化", "음량 평준화"],
        "fx.speed": ["速度", "速度", "Speed", "速度", "속도"],
        "fx.pitch": ["升降 Key", "升降调", "Key / pitch", "キー変更", "키 변경"],
        "fx.fadeIn": ["淡入", "淡入", "Fade in", "フェードイン", "페이드 인"],
        "fx.fadeOut": ["淡出", "淡出", "Fade out", "フェードアウト", "페이드 아웃"],
        "fx.sec": ["秒", "秒", "s", "秒", "초"],
        "fx.videoNote": ["影片不支援變速，其他效果只會改變聲音。", "视频不支持变速，其他效果只会改变声音。", "Speed isn't available for video; other effects change the audio only.", "動画では速度変更は使えません（他は音声のみ変更）。", "영상은 속도 변경을 지원하지 않으며, 다른 효과는 소리만 바뀝니다."],
        "stage.effects": ["正在套用音訊效果", "正在应用音频效果", "Applying audio effects", "エフェクトを適用中", "오디오 효과 적용 중"],

        "err.kkboxKey": ["KKBOX 需要先在「設定」填入 KKBOX Open API 金鑰；或改用「貼上歌單文字」。", "KKBOX 需要先在「设置」填入 KKBOX Open API 密钥；或改用「粘贴歌单文字」。", "KKBOX needs an Open API key in Settings — or use “Paste song list” instead.", "KKBOX は設定で Open API キーが必要です。または「曲リストを貼り付け」を使ってください。", "KKBOX는 설정에서 Open API 키가 필요합니다. 또는 ‘곡 목록 붙여넣기’를 사용하세요."],
        "list.button": ["貼上歌單文字", "粘贴歌单文字", "Paste song list", "曲リストを貼り付け", "곡 목록 붙여넣기"],
        "list.title": ["貼上歌單（任何平台都可以）", "粘贴歌单（任何平台都可以）", "Paste a song list (from any app)", "曲リストを貼り付け（どのアプリでも可）", "곡 목록 붙여넣기 (어느 앱이든 가능)"],
        "list.hint": ["從 KKBOX、LINE MUSIC、YouTube Music、Excel… 複製歌單貼在下面，每行一首，例如：\n周杰倫 - 晴天\n告白氣球 / 周杰倫", "从 KKBOX、QQ 音乐、网易云、Excel… 复制歌单粘贴在下面，每行一首，例如：\n周杰伦 - 晴天\n告白气球 / 周杰伦", "Copy a list from KKBOX, LINE MUSIC, YouTube Music, Excel… and paste it below, one song per line, e.g.\nJay Chou - Sunny Day\nLove Confession / Jay Chou", "KKBOX・LINE MUSIC・Excel などから曲リストをコピーして貼り付け（1 行 1 曲）\n例：周杰倫 - 晴天", "KKBOX, 멜론, 엑셀 등에서 곡 목록을 복사해 붙여넣으세요 (한 줄에 한 곡)\n예: 아이유 - 좋은 날"],
        "list.parse": ["讀取這些歌", "读取这些歌", "Load these songs", "この曲を読み込む", "이 곡들 불러오기"],
        "list.cancel": ["取消", "取消", "Cancel", "キャンセル", "취소"],
        "list.name": ["我貼上的歌單", "我粘贴的歌单", "My pasted list", "貼り付けたリスト", "붙여넣은 목록"],
        "set.kkbox": ["KKBOX Open API（選填，讀取 KKBOX 歌單用；到 developer.kkbox.com 免費申請）", "KKBOX Open API（选填，读取 KKBOX 歌单用；到 developer.kkbox.com 免费申请）", "KKBOX Open API (optional, free at developer.kkbox.com)", "KKBOX Open API（任意・developer.kkbox.com で無料取得）", "KKBOX Open API (선택, developer.kkbox.com에서 무료 발급)"],

        "tools.missingTitle": ["第一次使用：需要安裝下載工具", "首次使用：需要安装下载工具", "First run: download tools are needed", "初回：ダウンロードツールが必要です", "처음 사용: 다운로드 도구가 필요합니다"],
        "tools.missingBody": ["按下「一鍵安裝」會自動下載 yt-dlp、ffmpeg（約 1～3 分鐘）。", "点击「一键安装」会自动下载 yt-dlp、ffmpeg（约 1～3 分钟）。", "Click “Install” to download yt-dlp and ffmpeg automatically (about 1–3 minutes).", "「インストール」で yt-dlp と ffmpeg を自動ダウンロードします（約1〜3分）。", "‘설치’를 누르면 yt-dlp와 ffmpeg를 자동으로 내려받습니다 (약 1~3분)."],
        "tools.install": ["一鍵安裝", "一键安装", "Install", "インストール", "설치"],
        "tools.installing": ["安裝中…", "安装中…", "Installing…", "インストール中…", "설치 중…"],
        "tools.detectInstall": ["自動偵測（找不到會自動安裝）", "自动检测（找不到会自动安装）", "Auto-detect (installs if missing)", "自動検出（無ければインストール）", "자동 감지 (없으면 설치)"],

        "up.title": ["畫質提升（低解析放大）", "画质提升（低分辨率放大）", "Enhance quality (upscale)", "画質向上（アップスケール）", "화질 개선 (업스케일)"],
        "up.off": ["不處理", "不处理", "Off", "しない", "끄기"],
        "up.hint": ["把 360p / 720p / 1080p 放大成更高解析度，並降噪、銳化，在大螢幕上看起來更清楚。這是傳統影像處理，不是 AI 還原，無法生出原本沒有的細節；處理時間約為影片長度的 1/2～1 倍。", "把 360p / 720p / 1080p 放大成更高分辨率，并降噪、锐化，在大屏幕上看起来更清楚。这是传统图像处理，不是 AI 还原，无法生出原本没有的细节；处理时间约为视频长度的 1/2～1 倍。", "Upscales 360p / 720p / 1080p with denoising and sharpening so it looks cleaner on big screens. This is classic image processing, not AI restoration — it can't recreate lost detail. Takes about 0.5–1× the video length.", "360p / 720p / 1080p を拡大し、ノイズ除去とシャープ化で大画面でも見やすくします。AI 復元ではないため失われた細部は戻りません。処理時間は動画の長さの約 0.5〜1 倍です。", "360p / 720p / 1080p를 업스케일하고 노이즈 제거·선명화를 적용합니다. AI 복원이 아니므로 사라진 디테일은 복구되지 않으며, 처리 시간은 영상 길이의 약 0.5~1배입니다."],
        "stage.upscale": ["正在提升畫質", "正在提升画质", "Enhancing video", "画質を向上中", "화질 개선 중"],

        "ar.title": ["畫面比例", "画面比例", "Aspect ratio", "アスペクト比", "화면 비율"],
        "ar.original": ["原始", "原始", "Original", "オリジナル", "원본"],
        "ar.fill": ["空白處", "空白处", "Fill", "余白", "여백"],
        "ar.fill.black": ["黑邊", "黑边", "Black bars", "黒帯", "검은 여백"],
        "ar.fill.white": ["白邊", "白边", "White bars", "白帯", "흰 여백"],
        "ar.fill.blur": ["模糊背景", "模糊背景", "Blurred", "ぼかし背景", "흐린 배경"],
        "ar.fill.coverBlur": ["霧化封面", "雾化封面", "Blurred cover", "ぼかしカバー", "흐린 커버"],
        "ar.fill.crop": ["裁切填滿", "裁切填满", "Crop to fill", "切り抜き", "잘라서 채우기"],
        "ar.warnPad": ["⚠️ 選的比例和原影片不同時，畫面不會變形，多出來的地方會用「%@」補齊。", "⚠️ 选的比例和原视频不同时，画面不会变形，多出来的地方会用「%@」补齐。", "⚠️ If the ratio differs from the original, the picture won't be stretched — the extra space is filled with “%@”.", "⚠️ 元の動画と比率が違う場合、映像は歪まず、余った部分は「%@」で埋められます。", "⚠️ 원본과 비율이 다르면 화면이 늘어나지 않고 남는 부분은 ‘%@’(으)로 채워집니다."],
        "ar.warnCrop": ["⚠️ 「裁切填滿」不會有邊框，但畫面上下或左右的內容會被裁掉。", "⚠️ 「裁切填满」不会有边框，但画面上下或左右的内容会被裁掉。", "⚠️ “Crop to fill” has no bars, but the top/bottom or sides of the picture are cut off.", "⚠️「切り抜き」は帯なしですが、上下または左右が切り取られます。", "⚠️ ‘잘라서 채우기’는 여백이 없지만 위아래 또는 좌우가 잘립니다."],
        "pv.original": ["原始", "原始", "Original", "オリジナル", "원본"],
        "pv.applied": ["套用設定後", "应用设置后", "With settings", "設定適用後", "설정 적용 후"],
        "pv.render": ["預覽套用後的效果", "预览应用后的效果", "Preview with settings", "設定を適用してプレビュー", "설정 적용 미리보기"],
        "pv.update": ["設定已變更，更新預覽", "设置已变更，更新预览", "Settings changed — update preview", "設定が変更されました（更新）", "설정 변경됨 — 미리보기 갱신"],
        "pv.fetching": ["正在抓取預覽片段…", "正在获取预览片段…", "Fetching preview clip…", "プレビュー用の区間を取得中…", "미리보기 구간 가져오는 중…"],
        "pv.rendering": ["正在套用設定…", "正在应用设置…", "Applying settings…", "設定を適用中…", "설정 적용 중…"],
        "pv.range": ["預覽範圍", "预览范围", "Preview range", "プレビュー範囲", "미리보기 범위"],
        "pv.hint": ["會依照上面選的格式、品質、音訊工具、畫質提升與比例，產生一小段實際效果（修剪時用修剪範圍，最多 30 秒；否則從目前播放位置起 20 秒）。", "会按照上面选的格式、质量、音频工具、画质提升与比例，生成一小段实际效果（剪辑时用剪辑范围，最多 30 秒；否则从当前播放位置起 20 秒）。", "Renders a short clip with your format, quality, audio tools, upscale and aspect ratio (trim range up to 30 s, otherwise 20 s from the current position).", "選択した形式・品質・オーディオツール・画質向上・比率で短い区間を実際に生成します（トリミング範囲は最大30秒、それ以外は現在位置から20秒）。", "선택한 형식·품질·오디오 도구·화질 개선·비율로 짧은 구간을 실제로 만듭니다 (자르기 범위 최대 30초, 아니면 현재 위치부터 20초)."],
        "pv.file": ["將儲存為", "将保存为", "Will be saved as", "保存名", "저장 이름"],
        "pv.autoUpdate": ["自動更新預覽", "自动更新预览", "Auto-update preview", "自動で更新", "자동 갱신"],

        "ml.title": ["網路上的歌曲資訊（參考）", "网络上的歌曲信息（参考）", "Song info from the web (reference)", "ネット上の曲情報（参考）", "웹에서 찾은 곡 정보 (참고)"],
        "ml.placeholder": ["歌手 歌名", "歌手 歌名", "Artist title", "アーティスト 曲名", "가수 곡명"],
        "ml.hint": ["資料來自 Apple Music 目錄，只供參考；按「套用」才會填入上面的欄位。", "资料来自 Apple Music 目录，仅供参考；点「套用」才会填入上面的栏位。", "From the Apple Music catalog, for reference only — nothing changes until you click Apply.", "Apple Music のカタログより（参考）。「適用」を押すまで変更されません。", "Apple Music 카탈로그 정보(참고용)이며, ‘적용’을 눌러야 반영됩니다."],
        "ml.apply": ["套用", "套用", "Apply", "適用", "적용"],
        "ml.applied": ["已套用", "已套用", "Applied", "適用済み", "적용됨"],
        "ml.none": ["找不到相符的歌曲資訊，可以修改關鍵字再搜尋。", "找不到相符的歌曲信息，可以修改关键字再搜索。", "No matching song info — try different keywords.", "一致する曲情報がありません。キーワードを変えてください。", "일치하는 정보가 없습니다. 검색어를 바꿔 보세요."],

        "search.preview": ["試聽", "试听", "Preview", "試聴", "미리 듣기"],
        "search.previewLoading": ["正在載入試聽…", "正在加载试听…", "Loading preview…", "試聴を読み込み中…", "미리 듣기 불러오는 중…"],
        "search.stopPreview": ["停止試聽", "停止试听", "Stop preview", "試聴を停止", "미리 듣기 중지"],
        "err.botCheck": ["YouTube 暫時要求驗證（短時間內使用太多次）。請等幾分鐘再試，或到「偏好設定」打開「使用瀏覽器的 YouTube 登入」。", "YouTube 暂时要求验证（短时间内使用太多次）。请等几分钟再试，或到「偏好设置」打开「使用浏览器的 YouTube 登录」。", "YouTube is temporarily asking for verification (too many requests). Wait a few minutes, or turn on “Use my browser’s YouTube sign-in” in Preferences.", "YouTube が一時的に確認を求めています（短時間に使いすぎ）。数分待つか、環境設定で yt-dlp を更新してください。", "YouTube가 일시적으로 확인을 요구합니다(요청 과다). 몇 분 후 다시 시도하거나 환경설정에서 yt-dlp를 업데이트하세요."],
        "err.forbidden": ["YouTube 拒絕了這次下載（403）。請到「偏好設定」更新 yt-dlp 後再試。", "YouTube 拒绝了这次下载（403）。请到「偏好设置」更新 yt-dlp 后再试。", "YouTube refused the download (403). Update yt-dlp in Preferences and try again.", "YouTube にダウンロードを拒否されました（403）。yt-dlp を更新して再試行してください。", "YouTube가 다운로드를 거부했습니다(403). yt-dlp를 업데이트한 뒤 다시 시도하세요."],
        "err.private": ["這是私人影片，無法下載。", "这是私人视频，无法下载。", "This video is private.", "非公開の動画です。", "비공개 영상입니다."],
        "err.unavailable": ["這部影片已無法觀看（可能被刪除或有地區限制）。", "这个视频已无法观看（可能被删除或有地区限制）。", "This video is unavailable (removed or region-locked).", "この動画は視聴できません（削除または地域制限）。", "이 영상은 볼 수 없습니다(삭제 또는 지역 제한)."],

        "ck.title": ["YouTube 登入", "YouTube 登录", "YouTube sign-in", "YouTube ログイン", "YouTube 로그인"],
        "ck.toggle": ["使用瀏覽器的 YouTube 登入", "使用浏览器的 YouTube 登录", "Use my browser’s YouTube sign-in", "ブラウザの YouTube ログインを使う", "브라우저의 YouTube 로그인 사용"],
        "ck.desc": ["遇到「請確認你不是機器人」時打開。yt-dlp 會讀取所選瀏覽器在這台 Mac 上的登入資料，只傳給 YouTube，不會上傳到其他地方。請先用該瀏覽器登入 YouTube。", "遇到「请确认你不是机器人」时打开。yt-dlp 会读取所选浏览器在这台 Mac 上的登录数据，只传给 YouTube，不会上传到其他地方。请先用该浏览器登录 YouTube。", "Turn on if YouTube says “confirm you’re not a bot”. yt-dlp reads the chosen browser’s sign-in on this Mac and sends it only to YouTube. Sign in to YouTube in that browser first.", "「ボットではないことを確認」と出る場合にオン。選んだブラウザのログイン情報をこの Mac 上で読み取り、YouTube にのみ送信します。先にそのブラウザで YouTube にログインしてください。", "‘봇이 아님을 확인’이 나오면 켜세요. 선택한 브라우저의 로그인 정보를 이 Mac에서 읽어 YouTube에만 보냅니다. 먼저 그 브라우저로 YouTube에 로그인하세요."],
        "ck.browser": ["瀏覽器", "浏览器", "Browser", "ブラウザ", "브라우저"],
        "ck.notInstalled": ["未安裝", "未安装", "not installed", "未インストール", "미설치"],
        "ck.keychainNote": ["第一次使用時，macOS 會詢問是否允許存取「鑰匙圈」，請按「永遠允許」。", "第一次使用时，macOS 会询问是否允许访问「钥匙串」，请点「始终允许」。", "The first time, macOS asks for Keychain access — click Always Allow.", "初回は macOS がキーチェーンへのアクセスを尋ねるので「常に許可」を押してください。", "처음에는 macOS가 키체인 접근을 묻습니다. ‘항상 허용’을 누르세요."],
        "ck.safariNote": ["Safari 需要在「系統設定 → 隱私權與安全性 → 完全取用磁碟」允許 TubeGrab；也可以改選 Chrome。", "Safari 需要在「系统设置 → 隐私与安全性 → 完全磁盘访问权限」允许 TubeGrab；也可以改选 Chrome。", "Safari requires allowing TubeGrab in System Settings → Privacy & Security → Full Disk Access, or choose Chrome instead.", "Safari は「システム設定 → プライバシーとセキュリティ → フルディスクアクセス」で TubeGrab を許可する必要があります。", "Safari는 ‘시스템 설정 → 개인정보 보호 및 보안 → 전체 디스크 접근’에서 TubeGrab을 허용해야 합니다."],

        "fx.monoWarn": ["這段錄音幾乎是單聲道，人聲和伴奏混在一起，去人聲效果會很有限。可以改用搜尋找其他版本（例如「歌手 - Topic」的官方音源通常是立體聲）。", "这段录音几乎是单声道，人声和伴奏混在一起，去人声效果会很有限。可以改用搜索找其他版本（例如「歌手 - Topic」的官方音源通常是立体声）。", "This recording is almost mono, so vocals and music are mixed together and vocal removal will be weak. Try another version via Search (official “Artist - Topic” uploads are usually stereo).", "この音源はほぼモノラルのため、ボーカル除去の効果は弱くなります。検索で別のバージョン（「アーティスト - Topic」の公式音源は通常ステレオ）を試してください。", "이 녹음은 거의 모노라서 보컬 제거 효과가 약합니다. 검색으로 다른 버전(‘가수 - Topic’ 공식 음원은 보통 스테레오)을 찾아보세요."],

        "ly.title": ["歌詞", "歌词", "Lyrics", "歌詞", "가사"],
        "ly.enable": ["一併下載歌詞", "一并下载歌词", "Also download lyrics", "歌詞もダウンロード", "가사도 다운로드"],
        "ly.saveLRC": ["存成 .lrc 同步歌詞檔", "存成 .lrc 同步歌词文件", "Save synced .lrc file", "同期歌詞 .lrc を保存", "동기화 .lrc 파일 저장"],
        "ly.embed": ["寫入歌曲檔案（Apple Music 可顯示）", "写入歌曲文件（Apple Music 可显示）", "Embed in the song file (shows in Apple Music)", "曲ファイルに埋め込む（ミュージックで表示）", "곡 파일에 넣기 (Apple Music 표시)"],
        "ly.script": ["繁簡轉換", "繁简转换", "Chinese script", "中国語の字体", "중국어 글자체"],
        "ly.script.auto": ["依介面語言", "依界面语言", "Match interface", "表示言語に合わせる", "인터페이스에 맞춤"],
        "ly.script.keep": ["不轉換", "不转换", "Keep as is", "変換しない", "변환 안 함"],
        "ly.script.traditional": ["轉成繁體", "转成繁体", "Traditional", "繁体字に", "번체로"],
        "ly.script.simplified": ["轉成简体", "转成简体", "Simplified", "簡体字に", "간체로"],
        "ly.hint": ["歌詞來自開放的 LRCLIB 資料庫，以歌名與歌手比對；找不到時下載仍會完成。歌詞有著作權，僅供個人使用。", "歌词来自开放的 LRCLIB 数据库，以歌名与歌手比对；找不到时下载仍会完成。歌词有著作权，仅供个人使用。", "Lyrics come from the open LRCLIB database, matched by title and artist; the download still finishes if none are found. Lyrics are copyrighted — personal use only.", "歌詞はオープンな LRCLIB から曲名とアーティストで検索します。見つからなくても保存は完了します。歌詞には著作権があり、個人利用に限ります。", "가사는 공개 LRCLIB 데이터베이스에서 곡명·가수로 찾으며, 없어도 다운로드는 완료됩니다. 가사는 저작권이 있으니 개인적으로만 사용하세요."],
        "ly.preview": ["歌詞", "歌词", "Lyrics", "歌詞", "가사"],
        "ly.find": ["找歌詞", "找歌词", "Find lyrics", "歌詞を探す", "가사 찾기"],
        "ly.findAgain": ["重新找", "重新找", "Search again", "再検索", "다시 찾기"],
        "ly.synced": ["同步", "同步", "Synced", "同期", "동기화"],
        "ly.plain": ["純文字", "纯文字", "Plain", "テキスト", "텍스트"],
        "ly.none": ["找不到這首歌的歌詞；可以先修改上面的歌名／歌手再找一次。", "找不到这首歌的歌词；可以先修改上面的歌名／歌手再找一次。", "No lyrics found — fix the title/artist above and try again.", "歌詞が見つかりません。上の曲名・アーティストを直して再検索してください。", "가사를 찾지 못했습니다. 위의 곡명/가수를 고친 뒤 다시 찾아보세요."],
        "ly.pillFound": ["有歌詞", "有歌词", "Lyrics", "歌詞あり", "가사 있음"],
        "ly.pillNone": ["找不到歌詞", "找不到歌词", "No lyrics", "歌詞なし", "가사 없음"],
        "stage.lyrics": ["正在下載歌詞", "正在下载歌词", "Fetching lyrics", "歌詞を取得中", "가사 가져오는 중"],

        "ck.fileOption": ["cookies.txt 檔案", "cookies.txt 文件", "cookies.txt file", "cookies.txt ファイル", "cookies.txt 파일"],
        "ck.noFile": ["尚未選擇檔案", "尚未选择文件", "No file chosen", "ファイル未選択", "파일을 선택하지 않음"],
        "ck.fileHint": ["用瀏覽器擴充功能（例如「Get cookies.txt LOCALLY」）在登入 YouTube 後匯出 cookies.txt，再在這裡選擇。不需要特別權限，但登入過期後要重新匯出。這個檔案等同你的登入狀態，請勿分享給別人。", "用浏览器扩展（例如「Get cookies.txt LOCALLY」）在登录 YouTube 后导出 cookies.txt，再在这里选择。不需要特别权限，但登录过期后要重新导出。这个文件等同你的登录状态，请勿分享给别人。", "Export cookies.txt with a browser extension (e.g. “Get cookies.txt LOCALLY”) while signed in to YouTube, then choose it here. No special permission needed, but re-export when the sign-in expires. Treat this file like your login — don’t share it.", "YouTube にログインした状態で拡張機能（例：Get cookies.txt LOCALLY）で cookies.txt を書き出し、ここで選択します。特別な権限は不要ですが、期限切れ時は再書き出しが必要です。ログイン情報と同じなので共有しないでください。", "YouTube에 로그인한 상태에서 확장 프로그램(예: Get cookies.txt LOCALLY)으로 cookies.txt를 내보낸 뒤 여기서 선택하세요. 특별한 권한은 필요 없지만 만료되면 다시 내보내야 합니다. 로그인 정보와 같으니 공유하지 마세요."],
        "ck.statusOK": ["可以讀取這個瀏覽器的登入資料", "可以读取这个浏览器的登录数据", "Can read this browser’s sign-in", "このブラウザのログイン情報を読み取れます", "이 브라우저의 로그인 정보를 읽을 수 있습니다"],
        "ck.statusDenied": ["macOS 不允許 TubeGrab 讀取這個瀏覽器的資料（目前不會使用登入，下載照常進行）", "macOS 不允许 TubeGrab 读取这个浏览器的数据（目前不会使用登录，下载照常进行）", "macOS isn’t letting TubeGrab read this browser’s data (sign-in is skipped; downloads still work)", "macOS が TubeGrab にこのブラウザのデータの読み取りを許可していません（ログインは使わずにダウンロードします）", "macOS가 TubeGrab의 브라우저 데이터 읽기를 허용하지 않습니다 (로그인 없이 다운로드는 계속됩니다)"],
        "ck.fdaSteps": ["1. 按「打開系統設定」→「完全取用磁碟」。\n2. 按「＋」，選「應用程式」裡的 TubeGrab（或按「在 Finder 中顯示 App」再拖進去），打開開關。\n3. 結束並重新打開 TubeGrab，再按「重新檢查」。\n※ 重新安裝新版 TubeGrab 後可能要再授權一次。", "1. 点「打开系统设置」→「完全磁盘访问权限」。\n2. 点「＋」，选「应用程序」里的 TubeGrab（或点「在访达中显示 App」再拖进去），打开开关。\n3. 退出并重新打开 TubeGrab，再点「重新检查」。\n※ 重新安装新版后可能要再授权一次。", "1. Click Open System Settings → Full Disk Access.\n2. Click +, pick TubeGrab in Applications (or drag it in from Show app in Finder), and turn it on.\n3. Quit and reopen TubeGrab, then click Check again.\nYou may need to grant it again after installing a new version.", "1.「システム設定を開く」→「フルディスクアクセス」。\n2.「＋」で「アプリケーション」の TubeGrab を選び（または Finder から ドラッグ）、オンにします。\n3. TubeGrab を終了して再度開き、「再確認」を押します。\n※ 新しいバージョンを入れた後は再度許可が必要な場合があります。", "1. ‘시스템 설정 열기’ → ‘전체 디스크 접근 권한’.\n2. ‘+’로 ‘응용 프로그램’의 TubeGrab을 선택(또는 Finder에서 드래그)하고 켜세요.\n3. TubeGrab을 종료 후 다시 열고 ‘다시 확인’을 누르세요.\n※ 새 버전 설치 후 다시 허용해야 할 수 있습니다."],
        "ck.openFDA": ["打開系統設定", "打开系统设置", "Open System Settings", "システム設定を開く", "시스템 설정 열기"],
        "ck.showApp": ["在 Finder 中顯示 App", "在访达中显示 App", "Show app in Finder", "Finder で App を表示", "Finder에서 앱 보기"],
        "ck.recheck": ["重新檢查", "重新检查", "Check again", "再確認", "다시 확인"],
        "ck.statusMissing": ["找不到這個瀏覽器的資料，請確認已安裝並用它登入過 YouTube，或改選其他瀏覽器。", "找不到这个浏览器的数据，请确认已安装并用它登录过 YouTube，或改选其他浏览器。", "No data found for this browser — make sure it’s installed and signed in to YouTube, or pick another.", "このブラウザのデータが見つかりません。インストールして YouTube にログインしたか確認するか、別のブラウザを選んでください。", "이 브라우저 데이터를 찾을 수 없습니다. 설치 후 YouTube에 로그인했는지 확인하거나 다른 브라우저를 고르세요."],
        "err.cookiePerm": ["macOS 不允許 TubeGrab 讀取瀏覽器的登入資料。請到「偏好設定 → YouTube 登入」照步驟開啟「完全取用磁碟」，或改用 cookies.txt 檔案。", "macOS 不允许 TubeGrab 读取浏览器的登录数据。请到「偏好设置 → YouTube 登录」按步骤开启「完全磁盘访问权限」，或改用 cookies.txt 文件。", "macOS isn’t letting TubeGrab read your browser’s sign-in. Follow the Full Disk Access steps in Preferences → YouTube sign-in, or use a cookies.txt file.", "macOS がブラウザのログイン情報の読み取りを許可していません。環境設定 → YouTube ログインの手順でフルディスクアクセスを許可するか、cookies.txt を使ってください。", "macOS가 브라우저 로그인 정보 읽기를 허용하지 않습니다. 환경설정 → YouTube 로그인에서 전체 디스크 접근 권한을 허용하거나 cookies.txt를 사용하세요."],
        "err.cookieMissing": ["找不到瀏覽器的登入資料。請確認已用該瀏覽器登入 YouTube，或到「偏好設定」改選其他瀏覽器。", "找不到浏览器的登录数据。请确认已用该浏览器登录 YouTube，或到「偏好设置」改选其他浏览器。", "Couldn’t find the browser’s sign-in. Make sure you’re signed in to YouTube in that browser, or pick another in Preferences.", "ブラウザのログイン情報が見つかりません。そのブラウザで YouTube にログインしているか確認してください。", "브라우저 로그인 정보를 찾을 수 없습니다. 그 브라우저로 YouTube에 로그인했는지 확인하세요."],
        "err.cookieKeychain": ["無法解開瀏覽器的登入資料：macOS 詢問「鑰匙圈」時請按「永遠允許」，然後再試一次。", "无法解开浏览器的登录数据：macOS 询问「钥匙串」时请点「始终允许」，然后再试一次。", "Couldn’t decrypt the browser sign-in — when macOS asks about the Keychain, click Always Allow, then retry.", "ブラウザのログイン情報を復号できません。キーチェーンの確認で「常に許可」を押して再試行してください。", "브라우저 로그인 정보를 해독할 수 없습니다. 키체인 요청에서 ‘항상 허용’을 누른 뒤 다시 시도하세요."],

        "fb.title": ["回報與建議", "反馈与建议", "Feedback", "フィードバック", "피드백"],
        "fb.desc": ["會打開 GitHub 並自動填好版本與環境資訊；送出前你可以看過、修改。不會帶出你的使用者名稱。", "会打开 GitHub 并自动填好版本与环境信息；提交前你可以查看、修改。不会带出你的用户名。", "Opens GitHub with version and system info filled in — you can review and edit before submitting. Your user name is never included.", "GitHub を開き、バージョンと環境情報を自動入力します。送信前に確認・編集できます。ユーザー名は含まれません。", "GitHub을 열고 버전·환경 정보를 자동으로 채웁니다. 보내기 전에 확인·수정할 수 있으며 사용자 이름은 포함되지 않습니다."],
        "fb.bug": ["回報問題", "反馈问题", "Report a problem", "不具合を報告", "문제 신고"],
        "fb.idea": ["功能建議", "功能建议", "Suggest a feature", "機能の提案", "기능 제안"],
        "fb.existing": ["看看別人回報的", "看看别人反馈的", "See existing reports", "既存の報告を見る", "기존 신고 보기"],
        "fb.report": ["回報", "反馈", "Report", "報告", "신고"],
        "fb.reportHint": ["把這個錯誤回報到 GitHub（會附上錯誤訊息與下載設定）", "把这个错误反馈到 GitHub（会附上错误信息与下载设置）", "Report this error on GitHub (includes the error and download settings)", "このエラーを GitHub に報告（エラー内容と設定を添付）", "이 오류를 GitHub에 신고 (오류 내용과 설정 포함)"],
        "fb.helpTitle": ["還是有問題？", "还是有问题？", "Still stuck?", "解決しませんか？", "아직 해결되지 않았나요?"],

        "set.unlimited": ["不限制", "不限制", "Unlimited", "無制限", "제한 없음"],
        "set.concurrentWarn": ["一次下載很多首時，YouTube 可能暫時要求驗證；遇到時可以改成 2～3 首。", "一次下载很多首时，YouTube 可能暂时要求验证；遇到时可以改成 2～3 首。", "Downloading many at once can make YouTube ask for verification; if that happens, try 2–3.", "一度に多数ダウンロードすると YouTube が確認を求めることがあります。その場合は 2〜3 に。", "한 번에 많이 받으면 YouTube가 확인을 요구할 수 있습니다. 그럴 땐 2~3개로 줄이세요."],

        "look.theme.custom": ["自訂顏色", "自定义颜色", "Custom colors", "カスタムカラー", "사용자 지정 색상"],
        "look.colorA": ["起始色", "起始色", "Start", "開始色", "시작 색"],
        "look.colorB": ["結束色", "结束色", "End", "終了色", "끝 색"],
        "look.swap": ["交換兩個顏色", "交换两个颜色", "Swap colors", "色を入れ替え", "색 바꾸기"],
        "look.gradient": ["使用漸層", "使用渐变", "Use gradient", "グラデーションを使う", "그라데이션 사용"],
        "look.direction": ["漸層方向", "渐变方向", "Gradient direction", "グラデーションの方向", "그라데이션 방향"],
        "look.dir.diagonal": ["斜向", "斜向", "Diagonal", "斜め", "대각선"],
        "look.dir.diagonalUp": ["反斜向", "反斜向", "Diagonal up", "逆斜め", "역대각선"],
        "look.dir.horizontal": ["水平", "水平", "Horizontal", "横", "가로"],
        "look.dir.vertical": ["垂直", "垂直", "Vertical", "縦", "세로"],

        "search.modeSong": ["用歌名／歌手", "用歌名／歌手", "By title / artist", "曲名・アーティスト", "곡명/가수"],
        "search.modeLyrics": ["用歌詞", "用歌词", "By lyrics", "歌詞で", "가사로"],
        "search.lyricsSubtitle": ["只記得一句歌詞？輸入那一句就能找到歌", "只记得一句歌词？输入那一句就能找到歌", "Only remember a line? Type it to find the song", "歌詞の一節だけでも曲を探せます", "가사 한 줄만 기억나도 곡을 찾을 수 있어요"],
        "search.lyricsPlaceholder": ["例如：故事的小黃花 從出生那年就飄著", "例如：故事的小黄花 从出生那年就飘着", "e.g. a line you remember from the song", "例：覚えている歌詞の一節", "예: 기억나는 가사 한 줄"],
        "search.lyricsTips": ["輸入連續的一兩句最準確；錯字或只有一兩個字比較難找到。找到後可以先按 ▶ 試聽確認。", "输入连续的一两句最准确；错字或只有一两个字比较难找到。找到后可以先点 ▶ 试听确认。", "One or two consecutive lines work best; typos or very short phrases are harder. Press ▶ to preview and confirm.", "連続した1〜2行が最も正確です。見つかったら ▶ で試聴して確認できます。", "연속된 한두 줄이 가장 정확합니다. 찾으면 ▶로 미리 들어 확인하세요."],

        "ly.copy": ["複製歌詞", "复制歌词", "Copy lyrics", "歌詞をコピー", "가사 복사"],
        "ly.copied": ["已複製", "已复制", "Copied", "コピーしました", "복사됨"],
        "ly.exportLRC": ["匯出 .lrc", "导出 .lrc", "Export .lrc", ".lrc を書き出す", ".lrc 내보내기"],
        "ly.exportTXT": ["匯出完整歌詞 .txt", "导出完整歌词 .txt", "Export full lyrics .txt", "全歌詞を .txt で書き出す", "전체 가사 .txt 내보내기"],
        "score.find": ["找譜", "找谱", "Find sheet music", "楽譜を探す", "악보 찾기"],
        "score.hint": ["在瀏覽器打開樂譜網站的搜尋結果（只開網頁，不會下載樂譜）", "在浏览器打开乐谱网站的搜索结果（只开网页，不会下载乐谱）", "Opens sheet-music search results in your browser (pages only, nothing is downloaded)", "楽譜サイトの検索結果をブラウザで開きます（ダウンロードはしません）", "브라우저에서 악보 사이트 검색 결과를 엽니다 (다운로드하지 않음)"],
        "score.guitar": ["吉他譜／和弦（Ultimate Guitar）", "吉他谱／和弦（Ultimate Guitar）", "Guitar tabs / chords (Ultimate Guitar)", "ギターTAB・コード（Ultimate Guitar）", "기타 타브/코드 (Ultimate Guitar)"],
        "score.91pu": ["中文吉他譜（91譜）", "中文吉他谱（91谱）", "Chinese guitar tabs (91pu)", "中国語ギター譜（91譜）", "중국어 기타 악보 (91譜)"],
        "score.staff": ["五線譜（MuseScore）", "五线谱（MuseScore）", "Sheet music (MuseScore)", "五線譜（MuseScore）", "오선보 (MuseScore)"],
        "score.jianpu": ["簡譜", "简谱", "Numbered notation (jianpu)", "数字譜（簡譜）", "숫자보 (간보)"],
        "score.piano": ["鋼琴譜", "钢琴谱", "Piano sheet", "ピアノ譜", "피아노 악보"],

        "imp.button": ["匯入檔案（CSV / TXT / XLSX）", "导入文件（CSV / TXT / XLSX）", "Import file (CSV / TXT / XLSX)", "ファイルを読み込む（CSV / TXT / XLSX）", "파일 가져오기 (CSV / TXT / XLSX)"],
        "imp.src": ["Excel、Numbers、Google 試算表匯出的 CSV / XLSX，或每行一首的 TXT；會自動找歌名、歌手、專輯欄位", "Excel、Numbers、Google 表格导出的 CSV / XLSX，或每行一首的 TXT；会自动找歌名、歌手、专辑栏位", "CSV / XLSX from Excel, Numbers or Google Sheets, or a one-song-per-line TXT; title, artist and album columns are detected", "Excel・Numbers・Google スプレッドシートの CSV / XLSX、または1行1曲の TXT。曲名・アーティスト・アルバム列を自動検出", "Excel·Numbers·Google 시트의 CSV / XLSX 또는 한 줄에 한 곡인 TXT. 곡명·가수·앨범 열 자동 인식"],
        "imp.dropHint": ["也可以把檔案拖進來", "也可以把文件拖进来", "You can also drop a file here", "ファイルをドロップしても OK", "파일을 끌어다 놓아도 됩니다"],
        "imp.dropNow": ["放開以匯入歌單", "松开以导入歌单", "Drop to import the list", "ドロップして読み込む", "놓으면 가져옵니다"],
        "imp.empty": ["這個檔案裡找不到歌曲", "这个文件里找不到歌曲", "No songs found in this file", "このファイルに曲が見つかりません", "이 파일에서 곡을 찾지 못했습니다"],
        "imp.badFile": ["無法讀取這個檔案", "无法读取这个文件", "Couldn’t read this file", "ファイルを読み込めません", "파일을 읽을 수 없습니다"],

        "look.buttonSize": ["按鈕大小", "按钮大小", "Button size", "ボタンの大きさ", "버튼 크기"],
        "look.zoom": ["介面比例", "界面比例", "Interface scale", "表示倍率", "화면 배율"],
        "look.autoScale": ["跟著視窗大小縮放", "跟着窗口大小缩放", "Scale with window size", "ウインドウに合わせて拡大縮小", "창 크기에 맞춰 확대/축소"],
        "look.autoScaleHint": ["視窗拉大時文字、按鈕一起變大；縮小時一起變小", "窗口拉大时文字、按钮一起变大；缩小时一起变小", "Text and buttons grow and shrink with the window", "ウインドウの大きさに合わせて文字とボタンも変わります", "창 크기에 따라 글자와 버튼 크기도 바뀝니다"],
        "zoom.in": ["放大介面", "放大界面", "Zoom In", "拡大", "확대"],
        "zoom.out": ["縮小介面", "缩小界面", "Zoom Out", "縮小", "축소"],
        "zoom.reset": ["實際大小", "实际大小", "Actual Size", "実際のサイズ", "실제 크기"],

        "up2.title": ["檢查更新", "检查更新", "Updates", "アップデート", "업데이트"],
        "up2.lastChecked": ["上次檢查：", "上次检查：", "Last checked", "前回の確認：", "마지막 확인:"],
        "up2.idle": ["尚未檢查", "尚未检查", "Not checked yet", "未確認", "아직 확인 안 함"],
        "up2.checking": ["正在檢查…", "正在检查…", "Checking…", "確認中…", "확인 중…"],
        "up2.latest": ["已經是最新版本", "已经是最新版本", "You’re up to date", "最新バージョンです", "최신 버전입니다"],
        "up2.noReleases": ["GitHub 上還沒有發佈版本", "GitHub 上还没有发布版本", "No releases on GitHub yet", "GitHub にまだリリースがありません", "GitHub에 아직 릴리스가 없습니다"],
        "up2.newVersion": ["有新版本 %@", "有新版本 %@", "Version %@ is available", "新しいバージョン %@ があります", "새 버전 %@ 이(가) 있습니다"],
        "up2.failed": ["檢查失敗：", "检查失败：", "Check failed:", "確認に失敗：", "확인 실패:"],
        "up2.checkNow": ["檢查更新", "检查更新", "Check now", "今すぐ確認", "지금 확인"],
        "up2.view": ["查看更新", "查看更新", "View update", "更新を見る", "업데이트 보기"],
        "up2.auto": ["啟動時自動檢查（一天一次）", "启动时自动检查（一天一次）", "Check automatically at launch (once a day)", "起動時に自動確認（1日1回）", "실행 시 자동 확인 (하루 한 번)"],
        "up2.available": ["有新版本可以更新", "有新版本可以更新", "A new version is available", "新しいバージョンがあります", "새 버전이 있습니다"],
        "up2.notes": ["更新內容", "更新内容", "What’s new", "更新内容", "새로운 기능"],
        "up2.howto": ["按「下載更新」會用瀏覽器下載新版 .dmg；打開後把 TubeGrab 拖到「應用程式」取代舊版即可，設定會保留。", "点「下载更新」会用浏览器下载新版 .dmg；打开后把 TubeGrab 拖到「应用程序」替换旧版即可，设置会保留。", "Download update opens the new .dmg in your browser; drag TubeGrab to Applications to replace the old one. Your settings are kept.", "「アップデートをダウンロード」で新しい .dmg を取得し、TubeGrab を「アプリケーション」にドラッグして置き換えてください。設定は保持されます。", "‘업데이트 다운로드’로 새 .dmg를 받은 뒤 TubeGrab을 ‘응용 프로그램’으로 끌어 교체하세요. 설정은 유지됩니다."],
        "up2.skip": ["略過這個版本", "跳过这个版本", "Skip this version", "このバージョンをスキップ", "이 버전 건너뛰기"],
        "up2.later": ["稍後提醒", "稍后提醒", "Remind me later", "後で通知", "나중에 알림"],
        "up2.download": ["下載更新", "下载更新", "Download update", "アップデートをダウンロード", "업데이트 다운로드"],

        // 錯誤
        "err.noYtdlp": ["找不到 yt-dlp。請先在「終端機」執行：brew install yt-dlp ffmpeg", "找不到 yt-dlp。请先在「终端」执行：brew install yt-dlp ffmpeg", "yt-dlp not found. In Terminal run: brew install yt-dlp ffmpeg", "yt-dlp が見つかりません。ターミナルで brew install yt-dlp ffmpeg を実行してください", "yt-dlp를 찾을 수 없습니다. 터미널에서 brew install yt-dlp ffmpeg 를 실행하세요"],
        "err.badURL": ["網址看起來不正確", "链接看起来不正确", "That link doesn't look right", "URL が正しくないようです", "주소가 올바르지 않습니다"],
        "err.noTracks": ["這個清單裡讀不到歌曲（可能是私人清單）", "这个列表里读不到歌曲（可能是私人列表）", "No tracks found (the playlist may be private)", "曲が見つかりません（非公開の可能性）", "곡을 찾을 수 없습니다 (비공개일 수 있음)"],
        "err.noMatch": ["在 YouTube 找不到相符的歌曲", "在 YouTube 找不到相符的歌曲", "No matching video found on YouTube", "YouTube で一致する動画が見つかりません", "YouTube에서 일치하는 영상을 찾지 못했습니다"],
    ]

    private static func index(for lang: AppLanguage) -> Int {
        switch lang.resolved {
        case .zhHant, .system: return 0
        case .zhHans: return 1
        case .en: return 2
        case .ja: return 3
        case .ko: return 4
        }
    }

    static func string(_ key: String, _ lang: AppLanguage) -> String {
        guard let row = table[key] else { return key }
        let i = index(for: lang)
        return i < row.count ? row[i] : (row.count > 2 ? row[2] : key)
    }
}
