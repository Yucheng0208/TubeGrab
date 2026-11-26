# TubeGrab — macOS 影片／音樂下載工具（SwiftUI 範例專案）

> [!WARNING]
> **本專案僅供教學與程式範例用途。**
> 請只下載你本人擁有著作權、已取得授權，或明確允許下載的內容（例如創用 CC、公有領域、你自己上傳的影片）。
> 下載 YouTube、Spotify、Apple Music、KKBOX 等平台的內容可能違反其服務條款及當地著作權法，使用者須自行承擔一切責任。
> 作者不提供任何保證，也不鼓勵任何侵權行為。本程式不會繞過任何 DRM（Spotify / Apple Music / KKBOX 只讀取「歌名與歌手」清單，再到 YouTube 搜尋公開影片）。

這是一個用 **Swift + SwiftUI** 寫的 macOS App，介面盡量簡單：**貼上網址（或打歌名）→ 選一選 → 下載**。
底層使用開源工具 [yt-dlp](https://github.com/yt-dlp/yt-dlp) 與 [ffmpeg](https://ffmpeg.org/)。

---

## 功能一覽

| 功能 | 說明 |
|---|---|
| 影片 / 音樂 | 一鍵切換。影片：MP4、MOV、MKV、WEBM；音樂：MP3、M4A、AAC、FLAC、ALAC、WAV、OPUS、OGG |
| 品質選擇 | 影片：最佳 / 4K / 1440p / 1080p / 720p / 480p / 360p；音樂：最佳 / 320k / 256k / 192k / 128k |
| 打歌名搜尋 | 不是網址時自動到 YouTube 搜尋，標示「官方」「推薦」，可「選這首」或「直接下載音樂」 |
| 自動命名 + 可修改 | 檔名、歌名、歌手、專輯、專輯演出者、年份、類型預設用 YouTube 提供的資訊，全部可以改，並寫入檔案標籤 |
| 封面 | 自動把縮圖裁成正方形嵌入成專輯封面 |
| 預覽 + 修剪 | 內建播放器預覽，可設定開始／結束時間只下載其中一段 |
| 套用後預覽 | 「原始 / 套用設定後」切換比較：依所選格式、品質、音訊工具、畫質提升、比例實際產生一小段（修剪範圍最多 30 秒，否則 20 秒）；改設定會自動更新 |
| 畫面比例 | 原始 / 16:9 / 9:16 / 1:1 / 4:3 / 4:5 / 21:9；空白處可選黑邊、白邊、模糊背景、霧化封面，或裁切填滿（會提醒） |
| 網路歌曲資訊 | 自動用 Apple Music 目錄查詢歌名、歌手、專輯、年份、類型、曲序供參考，按「套用」才會填入 |
| 下載清單 | 整體進度環 + 每項漸層進度條（百分比、目前階段、已下載大小、速度、剩餘時間），可取消、重試、移除、清除已完成 |
| 播放清單批次下載 | YouTube 播放清單、Spotify / Apple Music / KKBOX 歌單或專輯，列出所有歌曲後勾選、一次自動下載 |
| 貼上歌單文字 | 從任何平台（KKBOX、LINE MUSIC、Excel…）複製「每行一首」的清單也能批次下載 |
| 選歌規則 | 優先選唱片公司 / 官方頻道（`- Topic`、VEVO、唱片公司、歌手官方頻道），找不到才選觀看次數最高的 |
| 音訊工具 | 左/右聲道、左右互換、單聲道、左右平衡、**去除人聲（卡拉 OK）**、音量、音量標準化、升降 Key、變速、淡入淡出 |
| 畫質提升 | 360p / 720p / 1080p 放大為 1080p / 1440p / 4K（降噪 + Lanczos + 銳化，使用 Mac 硬體 HEVC 編碼） |
| 五種語言 | 繁體中文、简体中文、English、日本語、한국어（設定中即時切換） |
| 外觀 | 深色 / 淺色 / 跟隨系統；7 種主題配色；標準 / 圓體 / 明體 / 等寬字型；4 種字體大小；粗體字 |
| 自動安裝工具 | 找不到 yt-dlp / ffmpeg 時，一鍵（或在設定按「自動偵測」）自動下載安裝 |

---

## 需要的套件 / 環境

| 項目 | 用途 | 必要？ |
|---|---|---|
| macOS 14 Sonoma 以上 | 執行 App（使用 SwiftUI `@Observable`） | 必要 |
| Xcode 15+ 或 Command Line Tools（Swift 5.10+） | 編譯 | 必要 |
| **yt-dlp** | 解析與下載影片 | 必要 |
| **ffmpeg**（含 ffprobe） | 合併影音、轉檔、修剪、封面、音訊工具、畫質提升 | 必要 |
| **deno** | 新版 yt-dlp 需要 JavaScript 執行環境才能完整支援 YouTube | 建議 |
| Spotify API Client ID / Secret | 讀取超過約 100 首的 Spotify 歌單 | 選填 |
| KKBOX Open API Client ID / Secret | 讀取 KKBOX 歌單 / 專輯（[developer.kkbox.com](https://developer.kkbox.com) 免費申請） | 選填 |

Swift 程式本身**沒有任何第三方 Swift 套件**，只用到 Apple 內建框架：SwiftUI、AVKit、AVFoundation、AppKit、Foundation。

### 安裝外部工具（擇一）

**方法 A：讓 App 自動安裝（最簡單）**
第一次打開 App，若找不到工具，畫面上方會出現「一鍵安裝」。也可以到「設定 → 外部工具 → 自動偵測」。
- 有 Homebrew：自動執行 `brew install yt-dlp ffmpeg deno`
- 沒有 Homebrew：從官方發佈頁下載執行檔到 `~/Library/Application Support/TubeGrab/bin`
  - yt-dlp：github.com/yt-dlp/yt-dlp releases
  - ffmpeg / ffprobe：ffmpeg.martin-riedl.de（ffmpeg.org 下載頁所列的 macOS 建置）
  - deno：github.com/denoland/deno releases

**方法 B：自己用 Homebrew 安裝**

```bash
brew install yt-dlp ffmpeg deno
```

---

## 編譯與執行

直接執行（開發用）：

```bash
swift run
```

打包成可以雙擊的 `TubeGrab.app`（輸出在 `build/`，可拖到「應用程式」資料夾）：

```bash
./scripts/build-app.sh
```

用 Xcode 開啟：

```bash
open Package.swift
```

> 第一次打開自己編譯的 App 若出現「無法驗證開發者」，請在 Finder 對 App 按右鍵 →「打開」。

---

## 使用方式

1. **貼上網址**（YouTube 影片、YouTube 播放清單、Spotify / Apple Music / KKBOX 歌單或專輯），或直接**打歌名 / 歌手**
2. 按「讀取」（打字時按鈕會變成「搜尋」）
3. 選「影片」或「音樂」、格式、品質；需要的話調整歌曲資訊、修剪片段、音訊工具、畫質提升
4. 按「加入下載」，到「下載清單」看進度

### 批次下載歌單

| 來源 | 怎麼做 |
|---|---|
| YouTube 播放清單 | 貼 `youtube.com/playlist?list=…` 網址。`watch?v=…&list=RD…` 這種 YouTube 自動合輯會當成單一影片 |
| Spotify | 貼公開歌單 / 專輯網址。不填 API 金鑰時最多讀取約 50～100 首 |
| Apple Music | 貼公開歌單 / 專輯網址（讀取頁面上公開顯示的歌曲） |
| KKBOX | 在設定填入 KKBOX Open API 金鑰後貼網址；或使用下面的「貼上歌單文字」 |
| 任何平台 | 按網址列旁的「貼上歌單文字」，或直接複製多行清單後按「貼上」 |

「貼上歌單文字」支援的格式（每行一首）：

```text
周杰倫 - 晴天
告白氣球 / 周杰倫
1. 五月天 – 倔強 4:22
擁抱	五月天          ← 從 Excel / Numbers 複製（Tab 分隔）
```

### 平台 Logo（選用）

網址列上方的 YouTube / Spotify / Apple Music / KKBOX 標籤預設使用系統圖示。若想顯示官方 Logo，
請自行到各平台的品牌資源頁下載（並遵守其商標使用規範），存成以下檔名放在專案的 `logos/` 資料夾，
再執行 `./scripts/build-app.sh`：

```text
logos/kkbox.png   logos/spotify.png   logos/youtube.png   logos/applemusic.png
```

本專案不附帶任何平台 Logo。

### 自動選歌規則（播放清單與搜尋推薦）

1. 先排除翻唱、伴奏、Remix、Live 反應影片、長度差太多的合輯等
2. 依官方程度計分：YouTube 依唱片公司發行資料產生的 `歌手 - Topic` 頻道、VEVO、知名唱片公司頻道、歌手本人頻道、已驗證頻道、長度吻合
3. 有達到官方門檻的 → 選分數最高（同分選觀看次數高的）
4. 沒有官方來源 → 選觀看次數最高的

### 音訊工具小提醒

- **去除人聲**用「左右聲道相減」消除正中央的人聲，並保留低音。適合錄音室版本；現場版、單聲道或人聲不在正中央的歌曲效果有限。若要 AI 等級的人聲分離，可自行整合 [Demucs](https://github.com/facebookresearch/demucs)。
- 影片模式下不提供變速（避免影音不同步），其他效果只改變聲音。
- 效果是下載完成後再用 ffmpeg 處理，預覽播放器聽不到效果。

### 畫面比例小提醒

- 選的比例和原影片不同時，畫面**不會被拉伸變形**，多出來的地方會用你選的方式補齊：**黑邊**、**白邊**、**模糊背景**（影片本身放大模糊）、**霧化封面**（影片封面圖放大霧化）。
- 選「裁切填滿」不會有邊框，但上下或左右的內容會被裁掉。
- 改變比例需要重新編碼影片（使用 Mac 硬體 HEVC），會多花一點處理時間。

### 畫質提升小提醒

- 這是**傳統影像處理**（輕度降噪 → Lanczos 放大 → 對比自適應銳化），**不是 AI 超解析度**，無法還原原本沒有的細節，但在大螢幕上看起來會比較乾淨、清楚。
- 使用 Mac 內建硬體 HEVC（H.265）編碼，速度約為影片長度的 0.5～1 倍。
- 想要 AI 還原可自行整合 [Real-ESRGAN](https://github.com/xinntao/Real-ESRGAN)（`realesrgan-ncnn-vulkan` 有 macOS 版本），但速度會慢非常多。

---

## 專案結構

```text
Package.swift
scripts/build-app.sh            # 打包成 .app
Sources/TubeGrab/
├── App.swift                   # App 進入點、側邊欄、外觀套用
├── Models.swift                # 設定（UserDefaults）、下載選項、歌曲資訊
├── Localization.swift          # 五種語言翻譯表
├── Theme.swift                 # 深淺色、主題色、字型、卡片 / 按鈕樣式
├── ProcessRunner.swift         # 執行外部指令、逐行讀取輸出
├── ToolInstaller.swift         # 自動偵測 / 安裝 yt-dlp、ffmpeg、deno
├── YTDLPService.swift          # 呼叫 yt-dlp：讀資訊、預覽、搜尋、組下載參數
├── PlaylistImporter.swift      # Spotify / Apple Music / KKBOX / 文字歌單、選歌規則
├── AudioTools.swift            # 音訊效果、畫質提升、畫面比例（ffmpeg 濾鏡）
├── PreviewRenderer.swift       # 「套用設定後」預覽片段的產生
├── MetadataLookup.swift        # 網路歌曲資訊查詢（iTunes Search API）
├── DownloadManager.swift       # 下載佇列、進度計算
│   （AboutView.swift 裡的 AppInfo.repoURL：開好 GitHub Repo 後改成你的網址）
└── Views/
    ├── NewDownloadView.swift   # 主畫面：網址/搜尋、選項、歌曲資訊、歌單
    ├── PreviewTrimView.swift   # 預覽播放器 + 修剪
    ├── QueueView.swift         # 下載清單 + 進度條
    ├── SettingsView.swift      # 設定
    └── AboutView.swift         # 關於：版本、聲明、開源致謝、GitHub 連結
```

### 運作原理（給想學習的人）

- 用 `yt-dlp -J` 取得影片資訊（JSON），把使用者修改後的歌名／歌手寫成 `meta_title`、`meta_artist` 等欄位，再用 `--load-info-json` 交給 yt-dlp 下載；`--embed-metadata` 會把這些資訊寫進檔案。
- 進度：`--progress-template` 讓 yt-dlp 輸出固定格式的百分比；修剪時改由 ffmpeg 下載，用 `-progress pipe:2` 的 `out_time_us` 計算百分比。影片的「視訊 → 音訊 → 合併」會換算成一條連續的整體進度。
- 預覽：直接播放 YouTube 提供的 HLS 串流（AVPlayer 原生支援）。
- Spotify / Apple Music 只讀取公開頁面上的歌名與歌手，KKBOX 使用官方 Open API，再到 YouTube 搜尋公開影片。

---

## 常見問題

- **下載失敗、出現 HTTP 403 或 "Sign in to confirm"**：YouTube 經常改版，請到「設定 → 更新 yt-dlp」，或執行：

  ```bash
  brew upgrade yt-dlp
  ```

- **MP4 在 QuickTime 無法播放**：1080p 以下會優先選 H.264；4K 通常只有 VP9/AV1，可改用 MKV 搭配 [IINA](https://iina.io) 播放。
- **Spotify / Apple Music 讀不到歌曲**：歌單必須是公開的；網站改版也可能造成解析失敗（範例程式，未保證長期可用）。
- **KKBOX 網址顯示需要金鑰**：KKBOX 網站有機器人防護，本程式不會繞過；請申請免費 Open API 金鑰或改用「貼上歌單文字」。

---

## 授權

範例程式碼可自由學習、修改。yt-dlp（Unlicense）、ffmpeg（LGPL/GPL）、deno（MIT）各自依其授權條款使用。
再次提醒：**本專案僅供教學用途，請尊重創作者與著作權。**
