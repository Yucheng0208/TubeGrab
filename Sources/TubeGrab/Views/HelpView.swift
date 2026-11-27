import SwiftUI

/// 說明主題。文字順序：繁中、简中、English、日本語、한국어
struct HelpTopic: Identifiable {
    let id: String
    let icon: String
    let page: SidebarItem?
    let title: [String]
    let steps: [[String]]

    func localizedTitle(_ i: Int) -> String { title[min(i, title.count - 1)] }
    func localizedSteps(_ i: Int) -> [String] { steps.map { $0[min(i, $0.count - 1)] } }
}

enum HelpContent {
    static let topics: [HelpTopic] = [
        HelpTopic(id: "quick", icon: "sparkles", page: .new,
                  title: ["快速開始", "快速开始", "Quick start", "はじめに", "빠른 시작"],
                  steps: [
                    ["第一次打開若看到「需要安裝下載工具」，按「一鍵安裝」，等 1～3 分鐘。", "第一次打开若看到「需要安装下载工具」，点「一键安装」，等 1～3 分钟。", "If you see “download tools are needed” on first launch, click Install and wait 1–3 minutes.", "初回に「ツールが必要です」と表示されたら「インストール」を押し、1〜3分待ちます。", "처음 실행 시 ‘도구가 필요합니다’가 보이면 ‘설치’를 누르고 1~3분 기다리세요."],
                    ["在 YouTube 複製影片網址，回到「新增下載」按「貼上」。", "在 YouTube 复制视频链接，回到「新建下载」点「粘贴」。", "Copy a video link from YouTube, then click Paste on New Download.", "YouTube で URL をコピーし、「新規ダウンロード」で「貼り付け」を押します。", "YouTube에서 주소를 복사한 뒤 ‘새 다운로드’에서 ‘붙여넣기’를 누르세요."],
                    ["選「影片」或「音樂」，挑格式與品質。", "选「视频」或「音乐」，挑格式与质量。", "Choose Video or Music, then a format and quality.", "「動画」か「音楽」を選び、形式と品質を選びます。", "‘영상’ 또는 ‘음악’을 고르고 형식과 품질을 선택하세요."],
                    ["按「加入下載」，到「下載清單」看進度，完成後按「打開」。", "点「加入下载」，到「下载列表」看进度，完成后点「打开」。", "Click Add to Downloads, watch progress in Downloads, then click Open when done.", "「ダウンロードに追加」を押し、一覧で進行状況を確認、完了後「開く」。", "‘다운로드에 추가’를 누르고 목록에서 진행률을 본 뒤 완료되면 ‘열기’."],
                  ]),
        HelpTopic(id: "single", icon: "link", page: .new,
                  title: ["下載單一影片或音樂", "下载单个视频或音乐", "Download one video or song", "動画・曲を1つダウンロード", "영상/곡 하나 다운로드"],
                  steps: [
                    ["支援 YouTube 以及 yt-dlp 支援的上千個網站；網址沒有 https:// 也可以。", "支持 YouTube 以及 yt-dlp 支持的上千个网站；链接没有 https:// 也可以。", "Works with YouTube and the thousands of sites yt-dlp supports; https:// is optional.", "YouTube と yt-dlp が対応する数千のサイトに対応。https:// は省略可。", "YouTube 및 yt-dlp가 지원하는 수천 개 사이트 지원, https:// 생략 가능."],
                    ["影片可選 MP4 / MOV / MKV / WEBM 與 360p～4K；在 Mac、iPhone 播放建議 MP4。", "视频可选 MP4 / MOV / MKV / WEBM 与 360p～4K；在 Mac、iPhone 播放建议 MP4。", "Video: MP4 / MOV / MKV / WEBM at 360p–4K. MP4 is best for Mac and iPhone.", "動画は MP4 / MOV / MKV / WEBM、360p〜4K。Mac・iPhone なら MP4 がおすすめ。", "영상: MP4 / MOV / MKV / WEBM, 360p~4K. Mac·iPhone은 MP4 권장."],
                    ["音樂可選 MP3、M4A、FLAC、ALAC、WAV 等；一般聽歌選 MP3 320k 即可。", "音乐可选 MP3、M4A、FLAC、ALAC、WAV 等；一般听歌选 MP3 320k 即可。", "Music: MP3, M4A, FLAC, ALAC, WAV and more. MP3 320k is fine for everyday listening.", "音楽は MP3・M4A・FLAC・ALAC・WAV など。普段使いは MP3 320k で十分。", "음악: MP3, M4A, FLAC, ALAC, WAV 등. 일반 감상은 MP3 320k면 충분."],
                    ["貼上播放清單或 Spotify 等歌單網址時，會自動跳到「歌單批次下載」。", "粘贴播放列表或 Spotify 等歌单链接时，会自动跳到「歌单批量下载」。", "Pasting a playlist (YouTube, Spotify…) jumps to Batch Download automatically.", "プレイリストの URL を貼ると自動で「一括ダウンロード」へ移動します。", "재생목록 주소를 붙여넣으면 ‘일괄 다운로드’로 자동 이동합니다."],
                  ]),
        HelpTopic(id: "search", icon: "magnifyingglass", page: .search,
                  title: ["用歌名搜尋", "用歌名搜索", "Search by song name", "曲名で検索", "곡명으로 검색"],
                  steps: [
                    ["到「搜尋歌曲」輸入「歌手 歌名」，例如「周杰倫 晴天」；在「新增下載」直接打字也會跳過來。", "到「搜索歌曲」输入「歌手 歌名」，例如「周杰伦 晴天」；在「新建下载」直接打字也会跳过来。", "Type “artist title” in Search; typing text on New Download also jumps here.", "「曲を検索」で「アーティスト 曲名」を入力。「新規ダウンロード」で文字を入れてもここに移動します。", "‘곡 검색’에 ‘가수 곡명’을 입력하세요. ‘새 다운로드’에 글자를 입력해도 이동합니다."],
                    ["標「官方」的是唱片公司或歌手頻道；標「推薦」的是程式建議的最佳版本。", "标「官方」的是唱片公司或歌手频道；标「推荐」的是程序建议的最佳版本。", "“Official” means a label or artist channel; “Recommended” is the app’s best pick.", "「公式」はレーベルやアーティストのチャンネル、「おすすめ」はアプリの推奨です。", "‘공식’은 음반사/가수 채널, ‘추천’은 앱이 고른 최적 버전입니다."],
                    ["「選這首」可以設定格式、預覽、修改資訊；「直接下載音樂」會用預設值馬上下載。", "「选这首」可以设置格式、预览、修改信息；「直接下载音乐」会用默认值马上下载。", "“Choose” lets you set options and preview; “Download as music” starts right away with defaults.", "「これを選ぶ」で設定やプレビュー、「音楽として保存」は既定値ですぐ保存します。", "‘선택’은 설정·미리보기 가능, ‘음악으로 바로 받기’는 기본값으로 즉시 저장."],
                  ]),
        HelpTopic(id: "batch", icon: "music.note.list", page: .batch,
                  title: ["歌單批次下載", "歌单批量下载", "Batch download playlists", "プレイリスト一括ダウンロード", "재생목록 일괄 다운로드"],
                  steps: [
                    ["貼上 YouTube 播放清單、Spotify、Apple Music 或 KKBOX 的公開歌單／專輯網址，按「讀取」。", "粘贴 YouTube 播放列表、Spotify、Apple Music 或 KKBOX 的公开歌单／专辑链接，点「读取」。", "Paste a public YouTube playlist, Spotify, Apple Music or KKBOX playlist/album link and click Load.", "YouTube・Spotify・Apple Music・KKBOX の公開リスト/アルバムの URL を貼り「読み込む」。", "YouTube·Spotify·Apple Music·KKBOX 공개 재생목록/앨범 주소를 붙여넣고 ‘불러오기’."],
                    ["其他 App 的歌單：複製成「每行一首」的文字（例如「周杰倫 - 晴天」），按「貼上歌單文字」。", "其他 App 的歌单：复制成「每行一首」的文字（例如「周杰伦 - 晴天」），点「粘贴歌单文字」。", "From other apps: copy one song per line (e.g. “Artist - Title”) and use Paste song list.", "他のアプリのリストは「1行1曲」でコピーし「曲リストを貼り付け」へ。", "다른 앱 목록은 ‘한 줄에 한 곡’으로 복사해 ‘곡 목록 붙여넣기’를 사용하세요."],
                    ["勾選要的歌，選格式，按「全部自動下載」或「下載勾選的歌曲」。", "勾选要的歌，选格式，点「全部自动下载」或「下载勾选的歌曲」。", "Tick the songs you want, pick a format, then Download all or Download selected.", "曲にチェックを付け、形式を選んで「すべて自動ダウンロード」か「選択した曲」。", "원하는 곡을 체크하고 형식을 고른 뒤 ‘모두 자동 다운로드’ 또는 ‘선택한 곡’."],
                    ["每首歌會優先找唱片公司／官方版本，找不到才選觀看次數最高的。", "每首歌会优先找唱片公司／官方版本，找不到才选播放次数最高的。", "Each song prefers the label/official upload, otherwise the most-viewed video.", "各曲はレーベル/公式を優先し、無ければ再生回数が最多の動画を選びます。", "각 곡은 음반사/공식 영상을 우선하고, 없으면 조회수가 가장 높은 영상을 고릅니다."],
                  ]),
        HelpTopic(id: "meta", icon: "tag.fill", page: .new,
                  title: ["修改檔名與歌曲資訊", "修改文件名与歌曲信息", "Edit file name & tags", "ファイル名と曲情報の編集", "파일 이름·곡 정보 편집"],
                  steps: [
                    ["檔名、歌名、歌手、專輯、年份、類型預設用 YouTube 的資訊，都可以直接修改。", "文件名、歌名、歌手、专辑、年份、流派默认用 YouTube 的信息，都可以直接修改。", "File name, title, artist, album, year and genre start from YouTube and can all be edited.", "ファイル名・曲名・アーティスト・アルバム・年・ジャンルは YouTube の情報が初期値で、編集できます。", "파일 이름·곡명·가수·앨범·연도·장르는 YouTube 정보가 기본값이며 수정 가능합니다."],
                    ["下方「網路上的歌曲資訊」會自動查詢，按「套用」才會填入。", "下方「网络上的歌曲信息」会自动查询，点「套用」才会填入。", "“Song info from the web” below is looked up automatically; nothing changes until you click Apply.", "下の「ネット上の曲情報」は自動検索され、「適用」を押すと反映されます。", "아래 ‘웹에서 찾은 곡 정보’는 자동 검색되며 ‘적용’을 눌러야 반영됩니다."],
                    ["改錯了可以按「還原成 YouTube 提供的資訊」。", "改错了可以点「还原为 YouTube 提供的信息」。", "Made a mistake? Click Reset to info from YouTube.", "間違えたら「YouTube の情報に戻す」。", "잘못 고쳤다면 ‘YouTube 정보로 되돌리기’."],
                  ]),
        HelpTopic(id: "preview", icon: "play.rectangle.fill", page: .new,
                  title: ["預覽、修剪與套用後預覽", "预览、剪辑与应用后预览", "Preview, trim & preview with settings", "プレビュー・トリミング・適用後プレビュー", "미리보기·자르기·적용 후 미리보기"],
                  steps: [
                    ["打開「只下載其中一段」，拖動開始／結束，或在播放時按「把目前位置設為開始／結束」。", "打开「只下载其中一段」，拖动开始／结束，或在播放时点「将当前位置设为开始／结束」。", "Turn on “Download only a section”, drag Start/End, or set them from the current position while playing.", "「一部分だけ」をオンにし、開始/終了をドラッグ、または再生中に現在位置を設定。", "‘일부 구간만’을 켜고 시작/끝을 드래그하거나 재생 중 현재 위치로 지정하세요."],
                    ["切到「套用設定後」會實際產生一小段，聽／看得到格式、音訊工具、畫質與比例的效果。", "切到「应用设置后」会实际生成一小段，听／看得到格式、音频工具、画质与比例的效果。", "Switch to “With settings” to render a short clip showing format, audio tools, upscale and ratio.", "「設定適用後」に切り替えると、形式・オーディオ・画質・比率を反映した短い区間を生成します。", "‘설정 적용 후’로 바꾸면 형식·오디오·화질·비율이 반영된 짧은 구간을 만듭니다."],
                    ["勾選「自動更新預覽」時，改設定後會自動重算。", "勾选「自动更新预览」时，改设置后会自动重算。", "With Auto-update on, the preview refreshes after you change a setting.", "「自動で更新」がオンなら設定変更後に自動で作り直します。", "‘자동 갱신’이 켜져 있으면 설정 변경 후 자동으로 다시 만듭니다."],
                  ]),
        HelpTopic(id: "audio", icon: "waveform", page: .new,
                  title: ["音訊工具（聲道、去人聲…）", "音频工具（声道、去人声…）", "Audio tools (channels, vocals…)", "オーディオツール（チャンネル・ボーカル除去…）", "오디오 도구 (채널·보컬 제거…)"],
                  steps: [
                    ["聲道可選只用左／右聲道、左右互換、單聲道，也可以調左右平衡。", "声道可选只用左／右声道、左右互换、单声道，也可以调左右平衡。", "Channels: left only, right only, swap, mono, plus a balance slider.", "チャンネル：左のみ・右のみ・入れ替え・モノラル、バランス調整も可能。", "채널: 왼쪽만·오른쪽만·좌우 바꾸기·모노, 밸런스 조절 가능."],
                    ["「去除人聲」適合做卡拉 OK 伴奏，錄音室版效果最好。", "「去除人声」适合做卡拉 OK 伴奏，录音室版效果最好。", "Remove vocals makes karaoke tracks; works best on studio recordings.", "「ボーカル除去」はカラオケ用。スタジオ音源で最も効果的です。", "‘보컬 제거’는 노래방 반주용이며 스튜디오 음원에서 가장 잘 됩니다."],
                    ["還有音量、音量標準化、升降 Key、速度（音樂）、淡入淡出。", "还有音量、音量标准化、升降调、速度（音乐）、淡入淡出。", "Also volume, loudness normalization, key change, speed (music) and fades.", "音量・音量均一化・キー変更・速度（音楽）・フェードもあります。", "볼륨·음량 평준화·키 변경·속도(음악)·페이드도 있습니다."],
                  ]),
        HelpTopic(id: "lyrics", icon: "quote.bubble.fill", page: .new,
                  title: ["下載歌詞", "下载歌词", "Download lyrics", "歌詞のダウンロード", "가사 다운로드"],
                  steps: [
                    ["選「音樂」後打開「一併下載歌詞」；歌單批次下載也可以一次幫每首歌找歌詞。", "选「音乐」后打开「一并下载歌词」；歌单批量下载也可以一次帮每首歌找歌词。", "Choose Music and turn on “Also download lyrics” — batch downloads can fetch lyrics for every song too.", "「音楽」を選び「歌詞もダウンロード」をオン。一括ダウンロードでも全曲の歌詞を取得できます。", "‘음악’을 고르고 ‘가사도 다운로드’를 켜세요. 일괄 다운로드도 곡마다 가사를 찾습니다."],
                    ["「.lrc 同步歌詞檔」會和歌曲放在一起，IINA 等播放器會一句一句顯示；「寫入歌曲檔案」可在 Apple Music 看到歌詞。", "「.lrc 同步歌词文件」会和歌曲放在一起，IINA 等播放器会一句一句显示；「写入歌曲文件」可在 Apple Music 看到歌词。", "The synced .lrc file sits next to the song so players like IINA show it line by line; embedding shows lyrics in Apple Music.", "同期歌詞 .lrc は曲と同じ場所に保存され、IINA などで1行ずつ表示されます。埋め込むとミュージックで表示されます。", "동기화 .lrc 파일은 곡 옆에 저장되어 IINA 등에서 한 줄씩 표시되고, 파일에 넣으면 Apple Music에서 보입니다."],
                    ["歌名或歌手不正確會找不到；先在「歌曲資訊」修正，或按「找歌詞」預覽確認。", "歌名或歌手不正确会找不到；先在「歌曲信息」修正，或点「找歌词」预览确认。", "Wrong title/artist means no match — fix them in the song info, or click Find lyrics to preview.", "曲名やアーティストが違うと見つかりません。曲情報で直すか「歌詞を探す」で確認してください。", "곡명이나 가수가 틀리면 찾지 못합니다. 곡 정보에서 고치거나 ‘가사 찾기’로 미리 확인하세요."],
                  ]),
        HelpTopic(id: "video", icon: "rectangle.expand.vertical", page: .new,
                  title: ["畫質提升與畫面比例", "画质提升与画面比例", "Upscale & aspect ratio", "画質向上とアスペクト比", "화질 개선·화면 비율"],
                  steps: [
                    ["「畫質提升」把 360p／720p／1080p 放大到 1080p～4K，並降噪、銳化（不是 AI 還原）。", "「画质提升」把 360p／720p／1080p 放大到 1080p～4K，并降噪、锐化（不是 AI 还原）。", "Upscale enlarges 360p/720p/1080p to 1080p–4K with denoise and sharpening (not AI restoration).", "「画質向上」は 360p/720p/1080p を 1080p〜4K に拡大し、ノイズ除去とシャープ化（AI 復元ではありません）。", "‘화질 개선’은 360p/720p/1080p를 1080p~4K로 키우고 노이즈 제거·선명화 (AI 복원 아님)."],
                    ["「畫面比例」可改成 16:9、9:16（手機直式）、1:1 等；比例不同時會補邊。", "「画面比例」可改成 16:9、9:16（手机竖屏）、1:1 等；比例不同时会补边。", "Aspect ratio can be 16:9, 9:16 (vertical), 1:1 and more; a different ratio adds borders.", "比率は 16:9・9:16（縦）・1:1 など。比率が違うと余白が付きます。", "비율은 16:9·9:16(세로)·1:1 등. 비율이 다르면 여백이 생깁니다."],
                    ["空白處可選黑邊、白邊、模糊背景、霧化封面，或裁切填滿（會裁掉邊緣）。", "空白处可选黑边、白边、模糊背景、雾化封面，或裁切填满（会裁掉边缘）。", "Fill with black, white, blurred video, blurred cover, or crop to fill (cuts the edges).", "余白は黒・白・ぼかし背景・ぼかしカバー、または切り抜き（端が切れます）。", "여백: 검정·흰색·흐린 배경·흐린 커버, 또는 잘라서 채우기(가장자리 잘림)."],
                  ]),
        HelpTopic(id: "queue", icon: "arrow.down.circle.fill", page: .queue,
                  title: ["下載清單與進度", "下载列表与进度", "Downloads & progress", "ダウンロード一覧と進行状況", "다운로드 목록·진행률"],
                  steps: [
                    ["上方圓環是整體進度；每一項有百分比、目前步驟、速度與剩餘時間。", "上方圆环是整体进度；每一项有百分比、当前步骤、速度与剩余时间。", "The ring shows overall progress; each item shows percent, current step, speed and time left.", "上の円は全体の進行状況。各項目に割合・段階・速度・残り時間が表示されます。", "위쪽 원은 전체 진행률, 각 항목에 퍼센트·단계·속도·남은 시간이 표시됩니다."],
                    ["可以「取消」「重試」「移除」，完成後可「打開」或在 Finder 中顯示。", "可以「取消」「重试」「移除」，完成后可「打开」或在访达中显示。", "Cancel, Retry or Remove; when done, Open or Show in Finder.", "「キャンセル」「再試行」「削除」、完了後は「開く」や Finder で表示。", "‘취소’·‘다시 시도’·‘제거’, 완료 후 ‘열기’ 또는 Finder에서 보기."],
                    ["檔案預設存在「下載項目」資料夾，可在「偏好設定」更改。", "文件默认存在「下载」文件夹，可在「偏好设置」更改。", "Files go to your Downloads folder by default; change it in Preferences.", "既定の保存先は「ダウンロード」。「環境設定」で変更できます。", "기본 저장 위치는 ‘다운로드’ 폴더이며 ‘환경설정’에서 바꿀 수 있습니다."],
                  ]),
        HelpTopic(id: "look", icon: "paintpalette.fill", page: .appearance,
                  title: ["外觀與語言", "外观与语言", "Appearance & language", "外観と言語", "모양·언어"],
                  steps: [
                    ["「外觀」可切換深色／淺色／跟隨系統、主題配色、字型、字體大小與粗體。", "「外观」可切换深色／浅色／跟随系统、主题配色、字体、字体大小与粗体。", "Appearance: dark / light / system, color theme, font, text size and bold.", "「外観」でダーク/ライト/システム、テーマ色、フォント、文字サイズ、太字を変更。", "‘모양’에서 다크/라이트/시스템, 테마 색, 글꼴, 글자 크기, 굵게를 바꿉니다."],
                    ["字太小看不清楚？把「字體大小」調成「大」或「特大」。", "字太小看不清楚？把「字体大小」调成「大」或「特大」。", "Text too small? Set Text size to Large or Extra large.", "文字が小さい場合は「文字サイズ」を「大」か「特大」に。", "글자가 작으면 ‘글자 크기’를 ‘크게’ 또는 ‘아주 크게’로."],
                    ["介面語言在「偏好設定」選擇：繁中、简中、English、日本語、한국어。", "界面语言在「偏好设置」选择：繁中、简中、English、日本語、한국어。", "Pick the interface language in Preferences.", "表示言語は「環境設定」で選べます。", "인터페이스 언어는 ‘환경설정’에서 선택합니다."],
                  ]),
        HelpTopic(id: "tools", icon: "wrench.and.screwdriver.fill", page: .settings,
                  title: ["外部工具與更新", "外部工具与更新", "Tools & updates", "外部ツールと更新", "외부 도구·업데이트"],
                  steps: [
                    ["本程式用 yt-dlp 下載、ffmpeg 轉檔；「偏好設定」按「自動偵測」，找不到會自動安裝。", "本程序用 yt-dlp 下载、ffmpeg 转码；「偏好设置」点「自动检测」，找不到会自动安装。", "The app uses yt-dlp and ffmpeg; Auto-detect in Preferences installs them if missing.", "yt-dlp と ffmpeg を使用。「環境設定」の「自動検出」で無ければインストールします。", "yt-dlp와 ffmpeg를 사용하며, ‘환경설정’의 ‘자동 감지’로 없으면 설치합니다."],
                    ["YouTube 常改版；突然下載失敗時，先按「更新 yt-dlp」。", "YouTube 常改版；突然下载失败时，先点「更新 yt-dlp」。", "YouTube changes often; if downloads suddenly fail, click Update yt-dlp first.", "YouTube は頻繁に変わります。急に失敗したらまず「yt-dlp を更新」。", "YouTube는 자주 바뀝니다. 갑자기 실패하면 먼저 ‘yt-dlp 업데이트’."],
                    ["Spotify（超過 100 首）與 KKBOX 歌單需要在「偏好設定」填入 API 金鑰（免費申請）。", "Spotify（超过 100 首）与 KKBOX 歌单需要在「偏好设置」填入 API 密钥（免费申请）。", "Spotify (over 100 songs) and KKBOX need free API keys in Preferences.", "Spotify（100曲超）と KKBOX は「環境設定」に無料の API キーが必要です。", "Spotify(100곡 초과)와 KKBOX는 ‘환경설정’에 무료 API 키가 필요합니다."],
                  ]),
        HelpTopic(id: "faq", icon: "questionmark.bubble.fill", page: nil,
                  title: ["常見問題", "常见问题", "FAQ", "よくある質問", "자주 묻는 질문"],
                  steps: [
                    ["出現「Sign in to confirm」或 403：更新 yt-dlp 後再試。", "出现「Sign in to confirm」或 403：更新 yt-dlp 后再试。", "“Sign in to confirm” or 403 errors: update yt-dlp and try again.", "「Sign in to confirm」や 403 は yt-dlp を更新して再試行。", "‘Sign in to confirm’ 또는 403: yt-dlp를 업데이트한 뒤 다시 시도."],
                    ["MP4 在 QuickTime 打不開：選 1080p 以下，或改用 MKV 搭配 IINA 播放。", "MP4 在 QuickTime 打不开：选 1080p 以下，或改用 MKV 搭配 IINA 播放。", "MP4 won’t open in QuickTime: choose 1080p or lower, or use MKV with IINA.", "QuickTime で MP4 が開けない：1080p 以下にするか、MKV と IINA を使用。", "QuickTime에서 MP4가 안 열리면 1080p 이하로, 또는 MKV + IINA 사용."],
                    ["讀不到 Spotify／Apple Music 歌單：歌單必須是公開的。", "读不到 Spotify／Apple Music 歌单：歌单必须是公开的。", "Spotify / Apple Music list not found: the playlist must be public.", "Spotify / Apple Music が読めない：公開プレイリストである必要があります。", "Spotify / Apple Music 목록이 안 읽히면 공개 재생목록이어야 합니다."],
                    ["請只下載你有權利或已獲授權的內容，並遵守各平台條款與著作權法。", "请只下载你有权利或已获授权的内容，并遵守各平台条款与著作权法。", "Only download content you own or are authorized to, and follow each platform’s terms and copyright law.", "権利を持つ、または許可されたコンテンツのみ保存し、規約と著作権法を守ってください。", "권리가 있거나 허가받은 콘텐츠만 받고 약관과 저작권법을 지키세요."],
                  ]),
    ]
}

/// 側欄「說明」
struct HelpView: View {
    @State private var query = ""
    @State private var expanded: Set<String> = ["quick"]
    private var theme: AccentTheme { AppSettings.shared.theme }

    private var langIndex: Int {
        switch AppSettings.shared.language.resolved {
        case .zhHant, .system: return 0
        case .zhHans: return 1
        case .en: return 2
        case .ja: return 3
        case .ko: return 4
        }
    }

    private var filtered: [HelpTopic] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return HelpContent.topics }
        return HelpContent.topics.filter { tp in
            tp.localizedTitle(langIndex).localizedCaseInsensitiveContains(q)
                || tp.localizedSteps(langIndex).contains { $0.localizedCaseInsensitiveContains(q) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeader(icon: "questionmark.circle.fill", title: t("nav.help"), subtitle: t("help.subtitle"))

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(t("help.search"), text: $query).textFieldStyle(.plain).font(.app(.body))
                    if !query.isEmpty {
                        Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                            .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.1)))

                HStack {
                    Button(t("help.expandAll")) { withAnimation(.snappy(duration: 0.3)) { expanded = Set(HelpContent.topics.map(\.id)) } }
                    Button(t("help.collapseAll")) { withAnimation(.snappy(duration: 0.3)) { expanded = [] } }
                    Spacer()
                }
                .buttonStyle(.link).font(.app(.callout))

                ForEach(filtered) { topic in
                    topicCard(topic)
                }
                if filtered.isEmpty {
                    Text(t("help.none")).font(.app(.body)).foregroundStyle(.secondary)
                }

                Card {
                    HStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.exclamationmark.bubble.right.fill")
                            .font(.system(size: 22)).foregroundStyle(theme.color)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t("fb.helpTitle")).font(.app(.headline))
                            Text(t("fb.desc")).font(.app(.caption)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { Feedback.open(.bug) } label: { Label(t("fb.bug"), systemImage: "ladybug.fill") }
                            .buttonStyle(GradientButtonStyle())
                        Button { Feedback.open(.idea) } label: { Label(t("fb.idea"), systemImage: "lightbulb.fill") }
                    }
                }
                Card {
                    Label(t("set.disclaimer"), systemImage: "exclamationmark.shield.fill")
                        .font(.app(.caption)).foregroundStyle(.secondary)
                }
            }
            .padding(36)
            .frame(maxWidth: 1040, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func topicCard(_ topic: HelpTopic) -> some View {
        let isOpen = expanded.contains(topic.id) || !query.isEmpty
        return Card {
            Button {
                withAnimation(.snappy(duration: 0.3)) {
                    if expanded.contains(topic.id) { expanded.remove(topic.id) } else { expanded.insert(topic.id) }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: topic.icon)
                        .foregroundStyle(.white).frame(width: 30, height: 30)
                        .background(theme.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(topic.localizedTitle(langIndex)).font(.app(.headline))
                    Spacer()
                    Image(systemName: "chevron.down").foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isOpen ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(topic.localizedSteps(langIndex).enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)").font(.app(.caption).weight(.bold)).foregroundStyle(.white)
                                .frame(width: 22, height: 22).background(theme.color, in: Circle())
                            Text(step).font(.app(.body)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let page = topic.page {
                        HStack {
                            Spacer()
                            Button { AppRouter.shared.go(page) } label: {
                                Label(t("help.goto"), systemImage: "arrow.right.circle.fill")
                            }
                        }
                    }
                }
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
