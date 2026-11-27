# TubeGrab

[繁體中文](README.md) | **简体中文** | [English](README.en.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

TubeGrab 是一个用 Swift 与 SwiftUI 制作的 macOS 视频与音乐下载工具。介面设计得很简单：粘贴链接或输入歌名，选一选就能下载。这是一个教学范例项目，示范如何把 yt-dlp、ffmpeg 等开源工具包装成好用的 Mac App。

> **免责声明**
>
> 本项目仅供教学与程序范例用途。请只下载你本人拥有著作权、已取得授权，或明确允许下载的内容（例如创用 CC、公有领域、你自己上传的视频）。下载 YouTube、Spotify、Apple Music、KKBOX 等平台的内容可能违反其服务条款及当地著作权法。
>
> 本程序依「现状」提供，不提供任何保证；使用本程序所产生的一切后果由使用者自行承担，作者不负任何责任。本程序不会绕过任何 DRM：Spotify、Apple Music、KKBOX 只读取「歌名与歌手」列表，再到 YouTube 搜索公开视频。

## 目录

- [功能总览](#功能总览)
- [下载与安装](#下载与安装)
- [第一次使用](#第一次使用)
- [使用方式](#使用方式)
- [常见问题](#常见问题)
- [给开发者](#给开发者)
- [使用的开源项目](#使用的开源项目)
- [授权](#授权)

## 功能总览

| 功能 | 帮助 |
|---|---|
| 下载视频或音乐 | 支持 YouTube 与 yt-dlp 支持的上千个网站。视频：MP4、MOV、MKV、WEBM（360p 到 4K）；音乐：MP3、M4A、AAC、FLAC、ALAC、WAV、OPUS、OGG |
| 搜索歌曲 | 用歌名、歌手，或只记得的一句歌词找歌；结果标示「官方」「推荐」，并可先试听 |
| 歌单批量下载 | YouTube 播放列表、Spotify、Apple Music、KKBOX 歌单或专辑，或导入 CSV、TXT、XLSX 文件 |
| 自动选最佳版本 | 优先选唱片公司或官方频道的版本，找不到才选播放次数最高的 |
| 歌曲信息 | 自动带入文件名、歌名、歌手、专辑、年份、流派，全部可修改；并可参考网路上的歌曲信息 |
| 歌词 | 下载同步歌词（.lrc）、写入歌曲文件、导出完整歌词、繁简转换 |
| 预览与剪辑 | 预览视频、只下载其中一段，并可预览「应用设置后」的实际效果 |
| 音频工具 | 左右声道、左右平衡、去除人声、音量、音量标准化、升降调、变速、淡入淡出 |
| 视频处理 | 画质提升（放大到 1080p 至 4K）、改变画面比例（黑边、白边、模糊背景、雾化封面、裁切） |
| 找谱 | 一键搜索吉他谱、和弦、五线谱、简谱、钢琴谱 |
| 下载列表 | 整体进度与每项进度百分比、速度、剩余时间；可取消、重试、移除、直接打开文件 |
| 介面 | 繁體中文、简体中文、English、日本語、한국어；深色、浅色、跟随系统；自订主题色与渐层；字体、字体大小、按钮大小、界面比例 |
| 任何窗口大小 | 窗口可任意缩放或全荧幕，文字与按钮会跟着调整；窗口太窄时自动改成直排版面 |
| 自动安装工具 | 找不到 yt-dlp 或 ffmpeg 时一键自动安装 |
| 检查更新 | 自动检查 GitHub 上是否有新版本 |

## 下载与安装

1. 到本项目的 [Releases](../../releases) 页面下载 `TubeGrab-版本-macOS.dmg`（或 `.zip`）。
2. 打开 `.dmg`，把 **TubeGrab** 拖到 **Applications（应用程序）** 文件夹。
3. 第一次打开：在「应用程序」文件夹对 TubeGrab **按右键，选「打开」，再按一次「打开」**。
   本程序没有经过 Apple 公证，所以 macOS 第一次会询问，之后就能直接双击开启。
4. 如果出现「已损毁，无法打开」，请打开「终端」执行：

   ```bash
   xattr -dr com.apple.quarantine /Applications/TubeGrab.app
   ```

**系统需求**：macOS 14 Sonoma 以上，Apple Silicon 与 Intel Mac 皆可使用。

**更新版本**：下载新版 `.dmg` 后，把 TubeGrab 拖到「应用程序」取代旧版即可，设置会保留。

## 第一次使用

1. 打开 TubeGrab。若画面上方出现「需要安装下载工具」，按 **一键安装**，等待 1 到 3 分钟。
   - 有 Homebrew 的电脑会自动执行 `brew install yt-dlp ffmpeg deno`。
   - 没有 Homebrew 时，会从官方发布页下载可执行文件到 `~/Library/Application Support/TubeGrab/bin`。
2. 到 **外观** 选择喜欢的显示模式、配色与字体大小。
3. 到 **偏好设置** 选择界面语言与下载保存位置（默认为「下载项目」文件夹）。

## 使用方式

侧栏分成三组：

| 群组 | 页面 | 用途 |
|---|---|---|
| 下载 | 新建下载 | 粘贴单一视频链接，设置格式、预览、修剪、修改信息后下载 |
| | 搜索歌曲 | 用歌名或歌手找歌 |
| | 用歌词找歌 | 只记得一句歌词时用 |
| | 歌单批量下载 | 一次下载整份歌单 |
| | 下载列表 | 查看进度与完成的文件 |
| 设置 | 外观 | 显示模式、配色、字体、大小 |
| | 偏好设置 | 语言、储存位置、外部工具、YouTube 登录、API 金钥 |
| 支持 | 帮助 | 每个功能的操作步骤（可搜索） |
| | 关于 | 版本、检查更新、反馈问题、免责声明 |

在任何输入框粘贴内容时，App 会自动送到对的页面：单一视频到「新建下载」，歌单链接到「歌单批量下载」，文字到「搜索歌曲」。

### 新建下载（单一视频或音乐）

1. 在 YouTube 等网站复制视频链接，到 **新建下载** 按 **粘贴**（或直接贴进输入框按 **读取**）。链接不用加 `https://`。
2. 选 **视频** 或 **音乐**。
3. 选格式与质量：
   - 视频：MP4、MOV、MKV、WEBM；质量从 360p 到 4K。要在 Mac 或 iPhone 播放建议选 MP4。
   - 音乐：MP3、M4A、FLAC、ALAC、WAV 等；一般听歌选 MP3 320k 即可。
4. 视需要调整下方的音频工具、修剪、歌曲信息。
5. 按 **加入下载**，到「下载列表」看进度。

如果输入的是文字而不是链接，输入框下方会出现 **用歌名／歌手** 与 **用歌词** 两个按钮，按下就会开始搜索。

### 预览、修剪与套用后预览

- 读取视频后会自动加载预览播放器。
- 打开 **只下载其中一段**，拖动「开始」「结束」，或在播放时按 **将当前位置设为开始／结束**。
- 播放器上方切到 **应用设置后**，App 会用和正式下载相同的处理方式产生一小段（修剪范围最多 30 秒，否则从目前位置起 20 秒），听得到、看得到格式、音频工具、画质提升与画面比例的实际效果。勾选 **自动更新预览** 时，改设置后会自动重算。
- 预览下方会显示「将保存为」的文件名与歌曲信息。

### 修改文件名、歌曲信息与歌词预览

- 文件名、歌名、歌手、专辑、专辑艺人、年份、流派默认使用 YouTube 提供的信息，都可以直接修改，会写入文件标签。
- **网路上的歌曲信息**：自动到 Apple Music 目录查询，列出候选结果（含封面、专辑、年份、曲序），按 **套用** 才会填入。改错了可按 **还原为 YouTube 提供的信息**。
- **歌词**：按 **找歌词** 预览，可切换同步歌词或纯文字，并可 **复制歌词**、**导出 .lrc**、**导出完整歌词 .txt**。
- **找谱**：开启吉他谱／和弦（Ultimate Guitar、91谱）、五线谱（MuseScore）、简谱、钢琴谱的搜索结果。只开启网页，不会下载乐谱。

### 搜索歌曲与用歌词找歌

1. 到 **搜索歌曲** 输入「歌手 歌名」，例如「周杰伦 晴天」；或到 **用歌词找歌** 输入记得的一两句歌词，例如「故事的小黄花 从出生那年就飘着」。
2. 结果中标示「官方」的是唱片公司或歌手频道，标示「推荐」的是程序建议的最佳版本。
3. 按缩图上的播放键可以先试听，下方会出现播放列。
4. 按 **选这首** 进入「新建下载」设置格式与预览，或按 **直接下载音乐** 用默认值马上下载。

### 歌单批量下载

1. 到 **歌单批量下载**，粘贴歌单或专辑链接并按 **读取**：

   | 来源 | 帮助 |
   |---|---|
   | YouTube 播放列表 | `youtube.com/playlist?list=...`；`watch?v=...&list=RD...` 这类自动合辑会当成单一视频 |
   | Spotify | 公开歌单或专辑；没填 API 金钥时最多约 50 到 100 首 |
   | Apple Music | 公开歌单或专辑 |
   | KKBOX | 需在「偏好设置」填入 KKBOX Open API 金钥（免费申请），或改用粘贴歌单文字 |

2. 也可以按 **粘贴歌单文字**，每行一首，例如：

   ```text
   周杰伦 - 晴天
   告白气球 / 周杰伦
   1. 五月天 - 倔强 4:22
   ```

3. 或按 **导入文件**（也可以直接把文件拖进页面），支持 CSV、TXT、XLSX。会自动找「歌名、歌手、专辑、时长」栏位，中英文栏名都可以（例如 Spotify 导出的 `Track Name`、`Artist Name(s)`）；没有表头时，第一栏当歌名、第二栏当歌手。
4. 勾选要下载的歌，选格式，按 **全部自动下载** 或 **下载勾选的歌曲**。

每首歌会自动到 YouTube 找最适合的版本：先排除翻唱、伴奏、Remix 等，优先选「歌手 - Topic」频道、VEVO、唱片公司或歌手官方频道，都没有才选播放次数最高的。

### 下载列表

- 上方圆环显示整体进度；每一项显示百分比、目前步骤、已下载大小、速度、剩余时间。
- 进行中可 **取消**；失败可 **重试** 或 **反馈**；完成后点缩图、标题，或在该列点两下即可打开。
- App 会自动用能播放的程序打开：macOS 内建可播放的格式用默认程序，MKV、WEBM、OPUS 等会改用 IINA 或 VLC（若已安装）。
- 文件默认存在「下载项目」文件夹，可在「偏好设置」更改。

### 音频工具

在「新建下载」或「歌单批量下载」展开 **音频工具**：

- **声道**：立体声、只用左声道、只用右声道、左右互换、单声道，以及左右平衡。
- **去除人声**：消除正中央的人声做成卡拉 OK 伴奏，并保留低音、自动补回音量。适合立体声的录音室版本；现场版或接近单声道的录音效果有限，预览时会提醒。
- **音量**、**音量标准化**、**升降调**（正负 6 个半音）、**速度**（仅音乐）、**淡入**、**淡出**。

### 画质提升与画面比例（视频）

- **画质提升**：把 360p、720p、1080p 放大到 1080p、1440p 或 4K，并降噪、锐化。这是传统影像处理，不是 AI 还原，无法生出原本没有的细节。使用 Mac 硬件 HEVC 编码，处理时间约为视频时长的 0.5 到 1 倍。
- **画面比例**：原始、16:9、9:16、1:1、4:3、4:5、21:9。比例和原视频不同时，画面不会变形，空白处可选 **黑边**、**白边**、**模糊背景**、**雾化封面**；或选 **裁切填满**（没有边框，但会裁掉边缘）。

### 歌词下载

1. 选 **音乐** 后，打开 **一并下载歌词**。
2. 选择 **存成 .lrc 同步歌词文件**（与歌曲放在一起，IINA 等播放器会一句一句显示）与 **写入歌曲文件**（Apple Music 可显示）。
3. **繁简转换** 可选依界面语言、不转换、转成繁体或转成简体。

歌词来自开放的 LRCLIB 数据库，会同时用繁体与简体比对；修剪时同步歌词的时间会跟着调整。找不到歌词时下载仍会完成，下载列表会标示「找不到歌词」。

### 外观与介面大小

- **显示模式**：跟随系统、浅色、深色。
- **主题配色**：7 种默认配色，或选 **自定义颜色** 挑两个颜色；可开关 **使用渐变** 并选渐变方向。
- **字体**、**字体大小**、**按钮大小**、**粗体字**。
- **界面比例**：80% 到 150%，也可用快捷键 `Command +`、`Command -`、`Command 0`。
- **跟着窗口大小缩放**：窗口拉大时文字与按钮一起变大。
- 侧栏可用工具列按钮或 `Control Command S` 收合与展开。

### 偏好设置

- **界面语言**：繁體中文、简体中文、English、日本語、한국어，或跟随系统。
- **下载保存位置**、**同时下载数量**（默认不限制；遇到 YouTube 要求验证时可改成 2 到 3）。
- **外部工具**：yt-dlp 与 ffmpeg 的路径；按 **自动检测**，找不到会自动安装；**更新 yt-dlp**。
- **YouTube 登录**：遇到「Sign in to confirm you're not a bot」时，打开 **使用浏览器的 YouTube 登录**。
  - 若显示「macOS 不允许 TubeGrab 读取这个浏览器的数据」，按 **打开系统设置**，在「完全磁盘访问权限」加入 TubeGrab 并打开开关，再重新打开 App。
  - 或选 **cookies.txt 文件**，用浏览器扩展导出后选择该文件（这个文件等同你的登录状态，请勿分享）。
- **KKBOX Open API**、**Spotify API**（选填）。

### 检查更新与反馈问题

- App 启动时每天自动检查一次 GitHub 是否有新版本；也可以到 **关于** 按 **检查更新**。有新版本时会显示更新内容与 **下载更新** 按钮。
- 到 **关于** 按 **反馈问题** 或 **功能建议**，会开启 GitHub 并自动填好版本与环境信息；下载失败时也可以在该项目按 **反馈**。送出前可以先检查、修改，不会带出你的使用者名称。

## 常见问题

**出现「Sign in to confirm you're not a bot」或 HTTP 403**
YouTube 暂时要求验证（短时间内使用太多次）。请等几分钟、到「偏好设置」按 **更新 yt-dlp**，或打开 **使用浏览器的 YouTube 登录**。

**出现「could not find chrome cookies database」**
macOS 不允许 TubeGrab 读取浏览器数据。请依「偏好设置」中的步骤允许「完全磁盘访问权限」，或改用 cookies.txt 文件。

**MP4 在 QuickTime 打不开**
4K 视频通常只有 VP9 或 AV1 编码。请选 1080p 以下，或改用 MKV 搭配 [IINA](https://iina.io) 播放。

**读不到 Spotify 或 Apple Music 歌单**
歌单必须是公开的；网站改版也可能造成解析失败。

**中文歌找不到歌词**
请确认歌名与歌手正确（可先在歌曲信息修正），再按 **找歌词** 预览。部分冷门歌曲在 LRCLIB 上可能没有数据。

**去除人声没有效果**
去除人声需要立体声录音；现场版或接近单声道的录音效果有限。可改用搜索找「歌手 - Topic」的官方音源。

## 给开发者

### 需求

| 项目 | 用途 | 必要性 |
|---|---|---|
| macOS 14 以上 | 执行 App | 必要 |
| Xcode 15 以上或 Command Line Tools（Swift 5.10 以上） | 编译 | 必要 |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | 解析与下载视频 | 必要（App 可自动安装） |
| [ffmpeg](https://ffmpeg.org/)（含 ffprobe） | 合并、转档、修剪、封面、音讯与视频处理 | 必要（App 可自动安装） |
| [deno](https://deno.com/) | 新版 yt-dlp 完整支持 YouTube 需要的 JavaScript 执行环境 | 建议 |

Swift 程序没有使用任何第三方套件，只用 Apple 内建框架：SwiftUI、AVKit、AVFoundation、AppKit、Foundation。

手动安装外部工具：

```bash
brew install yt-dlp ffmpeg deno
```

### 编译与执行

```bash
swift run
```

打包成 `build/TubeGrab.app`：

```bash
./scripts/build-app.sh
```

同时支持 Apple Silicon 与 Intel：

```bash
./scripts/build-app.sh --universal
```

用 Xcode 开启：

```bash
open Package.swift
```

### 打包发布

```bash
./scripts/package.sh 1.1
```

会在 `dist/` 产生 `TubeGrab-1.1-macOS.dmg`、`TubeGrab-1.1-macOS.zip` 与 `SHA256SUMS.txt`（`dist/` 已加入 `.gitignore`）。每次发布请使用更大的版本号，App 的检查更新才会通知使用者。

### 更换 App 图示

把新图片存成 `assets/logo-source.png`（任何背景都可以，会自动找出圆角方块并去除背景与光晕），然后执行：

```bash
swift scripts/make-icon.swift
```

会产生 `assets/AppIcon.png` 与 `assets/AppIcon.icns`，下次打包时自动使用。

### 项目结构

```text
Package.swift
assets/                         App 图示原图与产生的图示
scripts/
  build-app.sh                  打包成 .app（--universal 同时支持 Intel）
  package.sh                    产生发布用的 .dmg、.zip
  make-icon.swift               由原图产生 App 图示
Sources/TubeGrab/
  App.swift                     App 进入点、侧栏、外观套用
  Router.swift                  侧栏页面与页面之间的转交
  PageStores.swift              各页面的内容（切换页面时保留）
  Layout.swift                  依窗口大小缩放与窄画面排版
  Models.swift                  设置、下载选项、歌曲信息
  Localization.swift            五种语言翻译
  Theme.swift                   主题色、字体、卡片与按钮样式
  Components.swift              共用元件（按钮样式、横幅输入列）
  ProcessRunner.swift           执行外部指令并逐行读取输出
  ToolInstaller.swift           自动检测与安装 yt-dlp、ffmpeg、deno
  YTDLPService.swift            呼叫 yt-dlp：读信息、预览、搜索、下载参数
  DownloadManager.swift         下载伫列与进度计算
  PlaylistImporter.swift        Spotify、Apple Music、KKBOX、文字歌单与选歌规则
  PlaylistFileImporter.swift    导入 CSV、TXT、XLSX
  AudioTools.swift              音讯效果、画质提升、画面比例（ffmpeg 滤镜）
  PreviewRenderer.swift         「应用设置后」预览片段
  AudioPreviewPlayer.swift      搜索结果试听
  MetadataLookup.swift          网路歌曲信息（iTunes Search API）
  LyricsService.swift           歌词查询、.lrc、写入歌词标签
  ScoreFinder.swift             找谱、歌词导出
  FileOpener.swift              用能播放的程序打开文件
  Feedback.swift                反馈问题（GitHub issue）
  UpdateChecker.swift           检查 GitHub Releases 新版本
  Views/                        各页面画面
```

### 运作原理

- 用 `yt-dlp -J` 取得视频信息，把修改后的歌名、歌手写成 `meta_title`、`meta_artist` 等栏位，再用 `--load-info-json` 下载；`--embed-metadata` 会写入文件。
- 进度：`--progress-template` 输出固定格式的百分比；修剪时改由 ffmpeg 下载，用 `-progress pipe:2` 的 `out_time_us` 计算。视频的视讯、音讯、合并会换算成一条连续的整体进度。
- 音频工具、画质提升与画面比例在下载后用一次 ffmpeg 处理完成；「应用设置后」预览使用相同的处理流程。
- MP3 的歌词写入 ID3 的 USLT 栏位（ffmpeg 只能写成 Apple Music 不读取的 TXXX 栏位，所以由 App 直接写入）；其他格式使用 lyrics 标签。
- Spotify 与 Apple Music 只读取公开页面上的歌名与歌手，KKBOX 使用官方 Open API，再到 YouTube 搜索公开视频。

## 使用的开源项目

| 项目 | 授权 | 用途 |
|---|---|---|
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Unlicense | 视频解析与下载 |
| [FFmpeg](https://ffmpeg.org/) | LGPL / GPL | 影音处理 |
| [Deno](https://deno.com/) | MIT | yt-dlp 的 JavaScript 执行环境 |
| [LRCLIB](https://lrclib.net/) | 开放数据 | 歌词数据库 |
| iTunes Search API | Apple | 歌曲信息参考 |

## 授权

本项目代码以 [MIT License](LICENSE) 授权。外部工具与数据来源依其各自的授权条款使用。

再次提醒：本项目仅供教学用途，请尊重创作者与著作权。
