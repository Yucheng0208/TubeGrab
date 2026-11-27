# TubeGrab

**繁體中文** | [简体中文](README.zh-Hans.md) | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

TubeGrab 是一個用 Swift 與 SwiftUI 製作的 macOS 影片與音樂下載工具。介面設計得很簡單：貼上網址或輸入歌名，選一選就能下載。這是一個教學範例專案，示範如何把 yt-dlp、ffmpeg 等開源工具包裝成好用的 Mac App。

> **免責聲明**
>
> 本專案僅供教學與程式範例用途。請只下載你本人擁有著作權、已取得授權，或明確允許下載的內容（例如創用 CC、公有領域、你自己上傳的影片）。下載 YouTube、Spotify、Apple Music、KKBOX 等平台的內容可能違反其服務條款及當地著作權法。
>
> 本程式依「現狀」提供，不提供任何保證；使用本程式所產生的一切後果由使用者自行承擔，作者不負任何責任。本程式不會繞過任何 DRM：Spotify、Apple Music、KKBOX 只讀取「歌名與歌手」清單，再到 YouTube 搜尋公開影片。

## 目錄

- [功能總覽](#功能總覽)
- [下載與安裝](#下載與安裝)
- [第一次使用](#第一次使用)
- [使用方式](#使用方式)
- [常見問題](#常見問題)
- [給開發者](#給開發者)
- [使用的開源專案](#使用的開源專案)
- [授權](#授權)

## 功能總覽

| 功能 | 說明 |
|---|---|
| 下載影片或音樂 | 支援 YouTube 與 yt-dlp 支援的上千個網站。影片：MP4、MOV、MKV、WEBM（360p 到 4K）；音樂：MP3、M4A、AAC、FLAC、ALAC、WAV、OPUS、OGG |
| 搜尋歌曲 | 用歌名、歌手，或只記得的一句歌詞找歌；結果標示「官方」「推薦」，並可先試聽 |
| 歌單批次下載 | YouTube 播放清單、Spotify、Apple Music、KKBOX 歌單或專輯，或匯入 CSV、TXT、XLSX 檔案 |
| 自動選最佳版本 | 優先選唱片公司或官方頻道的版本，找不到才選觀看次數最高的 |
| 歌曲資訊 | 自動帶入檔名、歌名、歌手、專輯、年份、類型，全部可修改；並可參考網路上的歌曲資訊 |
| 歌詞 | 下載同步歌詞（.lrc）、寫入歌曲檔案、匯出完整歌詞、繁簡轉換 |
| 預覽與修剪 | 預覽影片、只下載其中一段，並可預覽「套用設定後」的實際效果 |
| 音訊工具 | 左右聲道、左右平衡、去除人聲、音量、音量標準化、升降 Key、變速、淡入淡出 |
| 影片處理 | 畫質提升（放大到 1080p 至 4K）、改變畫面比例（黑邊、白邊、模糊背景、霧化封面、裁切） |
| 找譜 | 一鍵搜尋吉他譜、和弦、五線譜、簡譜、鋼琴譜 |
| 下載清單 | 整體進度與每項進度百分比、速度、剩餘時間；可取消、重試、移除、直接打開檔案 |
| 介面 | 繁體中文、简体中文、English、日本語、한국어；深色、淺色、跟隨系統；自訂主題色與漸層；字型、字體大小、按鈕大小、介面比例 |
| 任何視窗大小 | 視窗可任意縮放或全螢幕，文字與按鈕會跟著調整；視窗太窄時自動改成直排版面 |
| 自動安裝工具 | 找不到 yt-dlp 或 ffmpeg 時一鍵自動安裝 |
| 檢查更新 | 自動檢查 GitHub 上是否有新版本 |

## 下載與安裝

1. 到本專案的 [Releases](../../releases) 頁面下載 `TubeGrab-版本-macOS.dmg`（或 `.zip`）。
2. 打開 `.dmg`，把 **TubeGrab** 拖到 **Applications（應用程式）** 資料夾。
3. 第一次打開：在「應用程式」資料夾對 TubeGrab **按右鍵，選「打開」，再按一次「打開」**。
   本程式沒有經過 Apple 公證，所以 macOS 第一次會詢問，之後就能直接雙擊開啟。
4. 如果出現「已損毀，無法打開」，請打開「終端機」執行：

   ```bash
   xattr -dr com.apple.quarantine /Applications/TubeGrab.app
   ```

**系統需求**：macOS 14 Sonoma 以上，Apple Silicon 與 Intel Mac 皆可使用。

**更新版本**：下載新版 `.dmg` 後，把 TubeGrab 拖到「應用程式」取代舊版即可，設定會保留。

## 第一次使用

1. 打開 TubeGrab。若畫面上方出現「需要安裝下載工具」，按 **一鍵安裝**，等待 1 到 3 分鐘。
   - 有 Homebrew 的電腦會自動執行 `brew install yt-dlp ffmpeg deno`。
   - 沒有 Homebrew 時，會從官方發佈頁下載執行檔到 `~/Library/Application Support/TubeGrab/bin`。
2. 到 **外觀** 選擇喜歡的顯示模式、配色與字體大小。
3. 到 **偏好設定** 選擇介面語言與下載儲存位置（預設為「下載項目」資料夾）。

## 使用方式

側欄分成三組：

| 群組 | 頁面 | 用途 |
|---|---|---|
| 下載 | 新增下載 | 貼上單一影片網址，設定格式、預覽、修剪、修改資訊後下載 |
| | 搜尋歌曲 | 用歌名或歌手找歌 |
| | 用歌詞找歌 | 只記得一句歌詞時用 |
| | 歌單批次下載 | 一次下載整份歌單 |
| | 下載清單 | 查看進度與完成的檔案 |
| 設定 | 外觀 | 顯示模式、配色、字型、大小 |
| | 偏好設定 | 語言、儲存位置、外部工具、YouTube 登入、API 金鑰 |
| 支援 | 說明 | 每個功能的操作步驟（可搜尋） |
| | 關於 | 版本、檢查更新、回報問題、免責聲明 |

在任何輸入框貼上內容時，App 會自動送到對的頁面：單一影片到「新增下載」，歌單網址到「歌單批次下載」，文字到「搜尋歌曲」。

### 新增下載（單一影片或音樂）

1. 在 YouTube 等網站複製影片網址，到 **新增下載** 按 **貼上**（或直接貼進輸入框按 **讀取**）。網址不用加 `https://`。
2. 選 **影片** 或 **音樂**。
3. 選格式與品質：
   - 影片：MP4、MOV、MKV、WEBM；品質從 360p 到 4K。要在 Mac 或 iPhone 播放建議選 MP4。
   - 音樂：MP3、M4A、FLAC、ALAC、WAV 等；一般聽歌選 MP3 320k 即可。
4. 視需要調整下方的音訊工具、修剪、歌曲資訊。
5. 按 **加入下載**，到「下載清單」看進度。

如果輸入的是文字而不是網址，輸入框下方會出現 **用歌名／歌手** 與 **用歌詞** 兩個按鈕，按下就會開始搜尋。

### 預覽、修剪與套用後預覽

- 讀取影片後會自動載入預覽播放器。
- 打開 **只下載其中一段**，拖動「開始」「結束」，或在播放時按 **把目前位置設為開始／結束**。
- 播放器上方切到 **套用設定後**，App 會用和正式下載相同的處理方式產生一小段（修剪範圍最多 30 秒，否則從目前位置起 20 秒），聽得到、看得到格式、音訊工具、畫質提升與畫面比例的實際效果。勾選 **自動更新預覽** 時，改設定後會自動重算。
- 預覽下方會顯示「將儲存為」的檔名與歌曲資訊。

### 修改檔名、歌曲資訊與歌詞預覽

- 檔名、歌名、歌手、專輯、專輯演出者、年份、類型預設使用 YouTube 提供的資訊，都可以直接修改，會寫入檔案標籤。
- **網路上的歌曲資訊**：自動到 Apple Music 目錄查詢，列出候選結果（含封面、專輯、年份、曲序），按 **套用** 才會填入。改錯了可按 **還原成 YouTube 提供的資訊**。
- **歌詞**：按 **找歌詞** 預覽，可切換同步歌詞或純文字，並可 **複製歌詞**、**匯出 .lrc**、**匯出完整歌詞 .txt**。
- **找譜**：開啟吉他譜／和弦（Ultimate Guitar、91譜）、五線譜（MuseScore）、簡譜、鋼琴譜的搜尋結果。只開啟網頁，不會下載樂譜。

### 搜尋歌曲與用歌詞找歌

1. 到 **搜尋歌曲** 輸入「歌手 歌名」，例如「周杰倫 晴天」；或到 **用歌詞找歌** 輸入記得的一兩句歌詞，例如「故事的小黃花 從出生那年就飄著」。
2. 結果中標示「官方」的是唱片公司或歌手頻道，標示「推薦」的是程式建議的最佳版本。
3. 按縮圖上的播放鍵可以先試聽，下方會出現播放列。
4. 按 **選這首** 進入「新增下載」設定格式與預覽，或按 **直接下載音樂** 用預設值馬上下載。

### 歌單批次下載

1. 到 **歌單批次下載**，貼上歌單或專輯網址並按 **讀取**：

   | 來源 | 說明 |
   |---|---|
   | YouTube 播放清單 | `youtube.com/playlist?list=...`；`watch?v=...&list=RD...` 這類自動合輯會當成單一影片 |
   | Spotify | 公開歌單或專輯；沒填 API 金鑰時最多約 50 到 100 首 |
   | Apple Music | 公開歌單或專輯 |
   | KKBOX | 需在「偏好設定」填入 KKBOX Open API 金鑰（免費申請），或改用貼上歌單文字 |

2. 也可以按 **貼上歌單文字**，每行一首，例如：

   ```text
   周杰倫 - 晴天
   告白氣球 / 周杰倫
   1. 五月天 - 倔強 4:22
   ```

3. 或按 **匯入檔案**（也可以直接把檔案拖進頁面），支援 CSV、TXT、XLSX。會自動找「歌名、歌手、專輯、長度」欄位，中英文欄名都可以（例如 Spotify 匯出的 `Track Name`、`Artist Name(s)`）；沒有表頭時，第一欄當歌名、第二欄當歌手。
4. 勾選要下載的歌，選格式，按 **全部自動下載** 或 **下載勾選的歌曲**。

每首歌會自動到 YouTube 找最適合的版本：先排除翻唱、伴奏、Remix 等，優先選「歌手 - Topic」頻道、VEVO、唱片公司或歌手官方頻道，都沒有才選觀看次數最高的。

### 下載清單

- 上方圓環顯示整體進度；每一項顯示百分比、目前步驟、已下載大小、速度、剩餘時間。
- 進行中可 **取消**；失敗可 **重試** 或 **回報**；完成後點縮圖、標題，或在該列點兩下即可打開。
- App 會自動用能播放的程式打開：macOS 內建可播放的格式用預設程式，MKV、WEBM、OPUS 等會改用 IINA 或 VLC（若已安裝）。
- 檔案預設存在「下載項目」資料夾，可在「偏好設定」更改。

### 音訊工具

在「新增下載」或「歌單批次下載」展開 **音訊工具**：

- **聲道**：立體聲、只用左聲道、只用右聲道、左右互換、單聲道，以及左右平衡。
- **去除人聲**：消除正中央的人聲做成卡拉 OK 伴奏，並保留低音、自動補回音量。適合立體聲的錄音室版本；現場版或接近單聲道的錄音效果有限，預覽時會提醒。
- **音量**、**音量標準化**、**升降 Key**（正負 6 個半音）、**速度**（僅音樂）、**淡入**、**淡出**。

### 畫質提升與畫面比例（影片）

- **畫質提升**：把 360p、720p、1080p 放大到 1080p、1440p 或 4K，並降噪、銳化。這是傳統影像處理，不是 AI 還原，無法生出原本沒有的細節。使用 Mac 硬體 HEVC 編碼，處理時間約為影片長度的 0.5 到 1 倍。
- **畫面比例**：原始、16:9、9:16、1:1、4:3、4:5、21:9。比例和原影片不同時，畫面不會變形，空白處可選 **黑邊**、**白邊**、**模糊背景**、**霧化封面**；或選 **裁切填滿**（沒有邊框，但會裁掉邊緣）。

### 歌詞下載

1. 選 **音樂** 後，打開 **一併下載歌詞**。
2. 選擇 **存成 .lrc 同步歌詞檔**（與歌曲放在一起，IINA 等播放器會一句一句顯示）與 **寫入歌曲檔案**（Apple Music 可顯示）。
3. **繁簡轉換** 可選依介面語言、不轉換、轉成繁體或轉成簡體。

歌詞來自開放的 LRCLIB 資料庫，會同時用繁體與簡體比對；修剪時同步歌詞的時間會跟著調整。找不到歌詞時下載仍會完成，下載清單會標示「找不到歌詞」。

### 外觀與介面大小

- **顯示模式**：跟隨系統、淺色、深色。
- **主題配色**：7 種預設配色，或選 **自訂顏色** 挑兩個顏色；可開關 **使用漸層** 並選漸層方向。
- **字型**、**字體大小**、**按鈕大小**、**粗體字**。
- **介面比例**：80% 到 150%，也可用快捷鍵 `Command +`、`Command -`、`Command 0`。
- **跟著視窗大小縮放**：視窗拉大時文字與按鈕一起變大。
- 側欄可用工具列按鈕或 `Control Command S` 收合與展開。

### 偏好設定

- **介面語言**：繁體中文、简体中文、English、日本語、한국어，或跟隨系統。
- **下載儲存位置**、**同時下載數量**（預設不限制；遇到 YouTube 要求驗證時可改成 2 到 3）。
- **外部工具**：yt-dlp 與 ffmpeg 的路徑；按 **自動偵測**，找不到會自動安裝；**更新 yt-dlp**。
- **YouTube 登入**：遇到「Sign in to confirm you're not a bot」時，打開 **使用瀏覽器的 YouTube 登入**。
  - 若顯示「macOS 不允許 TubeGrab 讀取這個瀏覽器的資料」，按 **打開系統設定**，在「完全取用磁碟」加入 TubeGrab 並打開開關，再重新打開 App。
  - 或選 **cookies.txt 檔案**，用瀏覽器擴充功能匯出後選擇該檔案（這個檔案等同你的登入狀態，請勿分享）。
- **KKBOX Open API**、**Spotify API**（選填）。

### 檢查更新與回報問題

- App 啟動時每天自動檢查一次 GitHub 是否有新版本；也可以到 **關於** 按 **檢查更新**。有新版本時會顯示更新內容與 **下載更新** 按鈕。
- 到 **關於** 按 **回報問題** 或 **功能建議**，會開啟 GitHub 並自動填好版本與環境資訊；下載失敗時也可以在該項目按 **回報**。送出前可以先檢查、修改，不會帶出你的使用者名稱。

## 常見問題

**出現「Sign in to confirm you're not a bot」或 HTTP 403**
YouTube 暫時要求驗證（短時間內使用太多次）。請等幾分鐘、到「偏好設定」按 **更新 yt-dlp**，或打開 **使用瀏覽器的 YouTube 登入**。

**出現「could not find chrome cookies database」**
macOS 不允許 TubeGrab 讀取瀏覽器資料。請依「偏好設定」中的步驟允許「完全取用磁碟」，或改用 cookies.txt 檔案。

**MP4 在 QuickTime 打不開**
4K 影片通常只有 VP9 或 AV1 編碼。請選 1080p 以下，或改用 MKV 搭配 [IINA](https://iina.io) 播放。

**讀不到 Spotify 或 Apple Music 歌單**
歌單必須是公開的；網站改版也可能造成解析失敗。

**中文歌找不到歌詞**
請確認歌名與歌手正確（可先在歌曲資訊修正），再按 **找歌詞** 預覽。部分冷門歌曲在 LRCLIB 上可能沒有資料。

**去除人聲沒有效果**
去除人聲需要立體聲錄音；現場版或接近單聲道的錄音效果有限。可改用搜尋找「歌手 - Topic」的官方音源。

## 給開發者

### 需求

| 項目 | 用途 | 必要性 |
|---|---|---|
| macOS 14 以上 | 執行 App | 必要 |
| Xcode 15 以上或 Command Line Tools（Swift 5.10 以上） | 編譯 | 必要 |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | 解析與下載影片 | 必要（App 可自動安裝） |
| [ffmpeg](https://ffmpeg.org/)（含 ffprobe） | 合併、轉檔、修剪、封面、音訊與影片處理 | 必要（App 可自動安裝） |
| [deno](https://deno.com/) | 新版 yt-dlp 完整支援 YouTube 需要的 JavaScript 執行環境 | 建議 |

Swift 程式沒有使用任何第三方套件，只用 Apple 內建框架：SwiftUI、AVKit、AVFoundation、AppKit、Foundation。

手動安裝外部工具：

```bash
brew install yt-dlp ffmpeg deno
```

### 編譯與執行

```bash
swift run
```

打包成 `build/TubeGrab.app`：

```bash
./scripts/build-app.sh
```

同時支援 Apple Silicon 與 Intel：

```bash
./scripts/build-app.sh --universal
```

用 Xcode 開啟：

```bash
open Package.swift
```

### 打包發佈

```bash
./scripts/package.sh 1.1
```

會在 `dist/` 產生 `TubeGrab-1.1-macOS.dmg`、`TubeGrab-1.1-macOS.zip` 與 `SHA256SUMS.txt`（`dist/` 已加入 `.gitignore`）。每次發佈請使用更大的版本號，App 的檢查更新才會通知使用者。

### 更換 App 圖示

把新圖片存成 `assets/logo-source.png`（任何背景都可以，會自動找出圓角方塊並去除背景與光暈），然後執行：

```bash
swift scripts/make-icon.swift
```

會產生 `assets/AppIcon.png` 與 `assets/AppIcon.icns`，下次打包時自動使用。

### 專案結構

```text
Package.swift
assets/                         App 圖示原圖與產生的圖示
scripts/
  build-app.sh                  打包成 .app（--universal 同時支援 Intel）
  package.sh                    產生發佈用的 .dmg、.zip
  make-icon.swift               由原圖產生 App 圖示
Sources/TubeGrab/
  App.swift                     App 進入點、側欄、外觀套用
  Router.swift                  側欄頁面與頁面之間的轉交
  PageStores.swift              各頁面的內容（切換頁面時保留）
  Layout.swift                  依視窗大小縮放與窄畫面排版
  Models.swift                  設定、下載選項、歌曲資訊
  Localization.swift            五種語言翻譯
  Theme.swift                   主題色、字型、卡片與按鈕樣式
  Components.swift              共用元件（按鈕樣式、橫幅輸入列）
  ProcessRunner.swift           執行外部指令並逐行讀取輸出
  ToolInstaller.swift           自動偵測與安裝 yt-dlp、ffmpeg、deno
  YTDLPService.swift            呼叫 yt-dlp：讀資訊、預覽、搜尋、下載參數
  DownloadManager.swift         下載佇列與進度計算
  PlaylistImporter.swift        Spotify、Apple Music、KKBOX、文字歌單與選歌規則
  PlaylistFileImporter.swift    匯入 CSV、TXT、XLSX
  AudioTools.swift              音訊效果、畫質提升、畫面比例（ffmpeg 濾鏡）
  PreviewRenderer.swift         「套用設定後」預覽片段
  AudioPreviewPlayer.swift      搜尋結果試聽
  MetadataLookup.swift          網路歌曲資訊（iTunes Search API）
  LyricsService.swift           歌詞查詢、.lrc、寫入歌詞標籤
  ScoreFinder.swift             找譜、歌詞匯出
  FileOpener.swift              用能播放的程式打開檔案
  Feedback.swift                回報問題（GitHub issue）
  UpdateChecker.swift           檢查 GitHub Releases 新版本
  Views/                        各頁面畫面
```

### 運作原理

- 用 `yt-dlp -J` 取得影片資訊，把修改後的歌名、歌手寫成 `meta_title`、`meta_artist` 等欄位，再用 `--load-info-json` 下載；`--embed-metadata` 會寫入檔案。
- 進度：`--progress-template` 輸出固定格式的百分比；修剪時改由 ffmpeg 下載，用 `-progress pipe:2` 的 `out_time_us` 計算。影片的視訊、音訊、合併會換算成一條連續的整體進度。
- 音訊工具、畫質提升與畫面比例在下載後用一次 ffmpeg 處理完成；「套用設定後」預覽使用相同的處理流程。
- MP3 的歌詞寫入 ID3 的 USLT 欄位（ffmpeg 只能寫成 Apple Music 不讀取的 TXXX 欄位，所以由 App 直接寫入）；其他格式使用 lyrics 標籤。
- Spotify 與 Apple Music 只讀取公開頁面上的歌名與歌手，KKBOX 使用官方 Open API，再到 YouTube 搜尋公開影片。

## 使用的開源專案

| 專案 | 授權 | 用途 |
|---|---|---|
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Unlicense | 影片解析與下載 |
| [FFmpeg](https://ffmpeg.org/) | LGPL / GPL | 影音處理 |
| [Deno](https://deno.com/) | MIT | yt-dlp 的 JavaScript 執行環境 |
| [LRCLIB](https://lrclib.net/) | 開放資料 | 歌詞資料庫 |
| iTunes Search API | Apple | 歌曲資訊參考 |

## 授權

本專案程式碼以 [MIT License](LICENSE) 授權。外部工具與資料來源依其各自的授權條款使用。

再次提醒：本專案僅供教學用途，請尊重創作者與著作權。
