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
        "about.notice": ["使用聲明", "使用声明", "Notice", "ご利用にあたって", "이용 안내"],
        "about.credits": ["使用的開源專案", "使用的开源项目", "Open-source credits", "使用しているオープンソース", "사용한 오픈소스"],
        "about.feedback": ["回報問題 / 建議", "反馈问题 / 建议", "Report an issue", "不具合・要望を報告", "문제 신고 / 제안"],
        "about.repoSoon": ["GitHub 頁面即將公開", "GitHub 页面即将公开", "GitHub page coming soon", "GitHub ページは近日公開", "GitHub 페이지 곧 공개"],

        // 新增下載
        "new.placeholder": ["貼上網址，或輸入歌名 / 歌手搜尋", "粘贴链接，或输入歌名 / 歌手搜索", "Paste a link, or type a song / artist to search", "URL を貼るか、曲名・アーティストで検索", "주소를 붙여넣거나 곡명 / 가수로 검색"],
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
        "set.disclaimer": ["本程式僅供教學與範例用途。請只下載你擁有權利或已獲授權的內容，並遵守各平台服務條款與著作權法。", "本程序仅供教学与示例用途。请只下载你拥有权利或已获授权的内容，并遵守各平台服务条款与著作权法。", "For educational / demonstration purposes only. Only download content you own or are authorized to download, and follow each platform's terms and copyright law.", "本アプリは教育・サンプル目的専用です。権利を持つ、または許可されたコンテンツのみをダウンロードし、各サービスの規約と著作権法を守ってください。", "이 앱은 교육 및 예제 용도로만 제공됩니다. 권리가 있거나 허가받은 콘텐츠만 다운로드하고 각 플랫폼 약관과 저작권법을 준수하세요."],

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
        "fx.vocalsHint": ["適合人聲在正中央的錄音室歌曲；現場版或單聲道歌曲效果較差。", "适合人声在正中央的录音室歌曲；现场版或单声道歌曲效果较差。", "Works best on studio tracks with centered vocals; less effective on live or mono recordings.", "ボーカルが中央にあるスタジオ音源向け。ライブやモノラルは効果が弱めです。", "보컬이 중앙에 있는 스튜디오 음원에 적합하며, 라이브/모노 음원은 효과가 약합니다."],
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
