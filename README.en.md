# TubeGrab

[繁體中文](README.md) | [简体中文](README.zh-Hans.md) | **English** | [日本語](README.ja.md) | [한국어](README.ko.md)

TubeGrab is a macOS video and music downloader built with Swift and SwiftUI. The interface is kept simple: paste a link or type a song name, pick your options, and download. It is an educational sample project showing how to wrap open-source tools such as yt-dlp and ffmpeg in an easy-to-use Mac app.

> **Disclaimer**
>
> This project is for educational and demonstration purposes only. Only download content you own, are authorized to download, or that is explicitly allowed to be downloaded (for example Creative Commons, public domain, or videos you uploaded yourself). Downloading content from YouTube, Spotify, Apple Music, KKBOX and similar platforms may violate their terms of service and local copyright law.
>
> This software is provided "as is" without any warranty. You use it at your own risk, and the author accepts no liability for any consequences. TubeGrab does not bypass any DRM: for Spotify, Apple Music and KKBOX it only reads the list of song titles and artists, then searches YouTube for public videos.

## Contents

- [Features](#features)
- [Download and install](#download-and-install)
- [First launch](#first-launch)
- [How to use](#how-to-use)
- [FAQ](#faq)
- [For developers](#for-developers)
- [Open-source projects used](#open-source-projects-used)
- [License](#license)

## Features

| Feature | Description |
|---|---|
| Download video or music | YouTube and the thousands of sites supported by yt-dlp. Video: MP4, MOV, MKV, WEBM (360p to 4K). Music: MP3, M4A, AAC, FLAC, ALAC, WAV, OPUS, OGG |
| Search songs | Find songs by title, artist, or a line of lyrics you remember; results are marked Official and Recommended, and can be previewed |
| Batch download | YouTube playlists, Spotify, Apple Music and KKBOX playlists or albums, or import a CSV, TXT or XLSX file |
| Best version picked automatically | Prefers record-label or official channel uploads, otherwise the most-viewed video |
| Song info | File name, title, artist, album, year and genre are filled in automatically and can all be edited; song info from the web is offered for reference |
| Lyrics | Download synced lyrics (.lrc), embed them in the song file, export full lyrics, convert between Traditional and Simplified Chinese |
| Preview and trim | Preview the video, download only a section, and preview the actual result with your settings applied |
| Audio tools | Left/right channels, balance, vocal removal, volume, loudness normalization, key change, speed, fade in/out |
| Video processing | Upscale to 1080p up to 4K, change the aspect ratio (black bars, white bars, blurred video, blurred cover, or crop) |
| Find sheet music | One-click search for guitar tabs, chords, staff notation, numbered notation and piano scores |
| Downloads | Overall and per-item progress with percentage, speed and time left; cancel, retry, remove, or open files directly |
| Interface | 繁體中文, 简体中文, English, 日本語, 한국어; dark, light or system appearance; custom theme colors and gradients; font, text size, button size and interface scale |
| Any window size | Resize freely or go full screen; text and buttons scale with the window, and narrow windows switch to a stacked layout |
| Automatic tool install | Installs yt-dlp and ffmpeg with one click when they are missing |
| Update check | Checks GitHub for new versions |

## Download and install

1. Download `TubeGrab-<version>-macOS.dmg` (or `.zip`) from the [Releases](../../releases) page.
2. Open the `.dmg` and drag **TubeGrab** into **Applications**.
3. First launch: in Applications, **right-click TubeGrab, choose Open, then click Open again**.
   The app is not notarized by Apple, so macOS asks the first time; after that you can simply double-click it.
4. If macOS says the app is damaged and can't be opened, run this in Terminal:

   ```bash
   xattr -dr com.apple.quarantine /Applications/TubeGrab.app
   ```

**Requirements:** macOS 14 Sonoma or later, on Apple Silicon or Intel Macs.

**Updating:** download the new `.dmg` and drag TubeGrab into Applications to replace the old version. Your settings are kept.

## First launch

1. Open TubeGrab. If you see "First run: download tools are needed" at the top, click **Install** and wait 1 to 3 minutes.
   - With Homebrew installed, it runs `brew install yt-dlp ffmpeg deno`.
   - Without Homebrew, it downloads the tools from their official release pages into `~/Library/Application Support/TubeGrab/bin`.
2. In **Appearance**, choose your preferred mode, colors and text size.
3. In **Preferences**, choose the interface language and where downloads are saved (your Downloads folder by default).

## How to use

The sidebar has three groups:

| Group | Page | Purpose |
|---|---|---|
| Download | New Download | Paste a single video link, set the format, preview, trim and edit the info, then download |
| | Search Songs | Find songs by title or artist |
| | Find by Lyrics | For when you only remember a line of the lyrics |
| | Batch Download | Download a whole playlist at once |
| | Downloads | Progress and finished files |
| Settings | Appearance | Mode, colors, font and sizes |
| | Preferences | Language, save location, external tools, YouTube sign-in, API keys |
| Support | Help | Step-by-step instructions for every feature (searchable) |
| | About | Version, update check, problem reports, disclaimer |

Whatever you paste is sent to the right page automatically: a single video goes to New Download, a playlist link to Batch Download, and plain text to Search Songs.

### New Download (a single video or song)

1. Copy a video link from YouTube or another site, then click **Paste** on **New Download** (or paste it into the field and click **Load**). `https://` is optional.
2. Choose **Video** or **Music (audio only)**.
3. Pick a format and quality:
   - Video: MP4, MOV, MKV, WEBM, from 360p to 4K. MP4 is the best choice for playing on a Mac or iPhone.
   - Music: MP3, M4A, FLAC, ALAC, WAV and more. MP3 at 320k is fine for everyday listening.
4. Adjust the audio tools, trimming and song info below if needed.
5. Click **Add to Downloads** and watch the progress in Downloads.

If you type text instead of a link, two buttons appear under the field, **By title / artist** and **By lyrics**, which start a search.

### Preview, trim and preview with settings

- A preview player loads automatically after the video is loaded.
- Turn on **Download only a section** and drag Start and End, or click **Set start to current** / **Set end to current** while playing.
- Switch the player to **With settings** and the app renders a short clip using exactly the same processing as the real download (the trim range up to 30 seconds, otherwise 20 seconds from the current position), so you can hear and see the format, audio tools, upscaling and aspect ratio. With **Auto-update preview** on, the clip is re-rendered after you change a setting.
- The file name and song info that will be saved are shown under the preview.

### File name, song info and lyrics preview

- File name, title, artist, album, album artist, year and genre start from the information YouTube provides. All of them can be edited and are written into the file's tags.
- **Song info from the web (reference)**: the app looks up the Apple Music catalog and lists candidates with cover, album, year and track number. Nothing changes until you click **Apply**. Click **Reset to info from YouTube** to undo your edits.
- **Lyrics**: click **Find lyrics** to preview. Switch between synced and plain text, then **Copy lyrics**, **Export .lrc** or **Export full lyrics .txt**.
- **Find sheet music**: opens search results for guitar tabs and chords (Ultimate Guitar, 91pu), staff notation (MuseScore), numbered notation and piano scores. Only web pages are opened; nothing is downloaded.

### Search Songs and Find by Lyrics

1. In **Search Songs**, type the artist and title, for example "Jay Chou Sunny Day". In **Find by Lyrics**, type one or two lines you remember.
2. Results marked Official come from a record label or the artist's channel; Recommended marks the app's best pick.
3. Click the play button on a thumbnail to preview the song; a player bar appears at the bottom.
4. Click **Choose** to open it in New Download with all options, or **Download as music** to download it immediately with default settings.

### Batch Download

1. In **Batch Download**, paste a playlist or album link and click **Load**:

   | Source | Notes |
   |---|---|
   | YouTube playlist | `youtube.com/playlist?list=...`; auto-generated mixes such as `watch?v=...&list=RD...` are treated as a single video |
   | Spotify | Public playlists or albums; about 50 to 100 songs without an API key |
   | Apple Music | Public playlists or albums |
   | KKBOX | Needs a free KKBOX Open API key in Preferences, or use Paste song list instead |

2. Or click **Paste song list** and enter one song per line, for example:

   ```text
   Jay Chou - Sunny Day
   Love Confession / Jay Chou
   1. Mayday - Stubborn 4:22
   ```

3. Or click **Import file (CSV / TXT / XLSX)**, or drop a file onto the page. Title, artist, album and duration columns are detected automatically, with English or Chinese column names (for example Spotify's `Track Name` and `Artist Name(s)`). Without a header row, the first column is the title and the second the artist.
4. Tick the songs you want, choose a format, then click **Download all automatically** or **Download selected**.

For each song the app searches YouTube for the best version: covers, karaoke, remixes and the like are excluded first; then "Artist - Topic" channels, VEVO, record labels and the artist's official channel are preferred; only if none exist is the most-viewed video chosen.

### Downloads

- The ring at the top shows overall progress. Each item shows its percentage, current step, downloaded size, speed and time left.
- **Cancel** while downloading; **Retry** or **Report** a failure; when done, click the thumbnail or title, or double-click the row, to open the file.
- Files open in a player that can play them: formats macOS supports open in your default app, while MKV, WEBM, OPUS and similar open in IINA or VLC if installed.
- Files are saved to your Downloads folder by default; change this in Preferences.

### Audio tools

Expand **Audio tools** on New Download or Batch Download:

- **Channels**: stereo, left only, right only, swap left/right, mono, plus a balance slider.
- **Remove vocals (karaoke)**: cancels the centered vocal to make a backing track, keeps the bass and restores the volume. Works best on stereo studio recordings; live or near-mono recordings give limited results, and the preview warns you.
- **Volume**, **Normalize loudness**, **Key / pitch** (plus or minus 6 semitones), **Speed** (music only), **Fade in**, **Fade out**.

### Upscaling and aspect ratio (video)

- **Enhance quality (upscale)**: enlarges 360p, 720p or 1080p to 1080p, 1440p or 4K with denoising and sharpening. This is classic image processing, not AI restoration, so it cannot recreate lost detail. It uses the Mac's hardware HEVC encoder and takes about 0.5 to 1 times the video length.
- **Aspect ratio**: original, 16:9, 9:16, 1:1, 4:3, 4:5, 21:9. When the ratio differs from the original, the picture is never stretched; fill the extra space with **Black bars**, **White bars**, **Blurred** (blurred video) or **Blurred cover**, or choose **Crop to fill** (no bars, but the edges are cut off).

### Downloading lyrics

1. Choose **Music**, then turn on **Also download lyrics**.
2. Choose **Save synced .lrc file** (saved next to the song; players like IINA show it line by line) and **Embed in the song file** (shows in Apple Music).
3. **Chinese script** can match the interface, keep the original, or convert to Traditional or Simplified.

Lyrics come from the open LRCLIB database and are matched in both Traditional and Simplified Chinese. When a song is trimmed, the synced lyric times are shifted to match. If no lyrics are found the download still finishes, and the item is marked "No lyrics".

### Appearance and interface size

- **Mode**: system, light or dark.
- **Color theme**: 7 presets, or **Custom colors** with two colors of your choice; turn **Use gradient** on or off and pick the gradient direction.
- **Font**, **Text size**, **Button size**, **Bold text**.
- **Interface scale**: 80% to 150%, also with `Command +`, `Command -` and `Command 0`.
- **Scale with window size**: text and buttons grow as the window gets larger.
- Collapse or expand the sidebar with the toolbar button or `Control Command S`.

### Preferences

- **Language**: 繁體中文, 简体中文, English, 日本語, 한국어, or follow the system.
- **Save downloads to** and **Simultaneous downloads** (unlimited by default; if YouTube asks for verification, try 2 to 3).
- **External tools**: paths to yt-dlp and ffmpeg; **Auto-detect** installs them if missing; **Update yt-dlp**.
- **YouTube sign-in**: if you see "Sign in to confirm you're not a bot", turn on **Use my browser's YouTube sign-in**.
  - If it says macOS isn't letting TubeGrab read the browser's data, click **Open System Settings**, add TubeGrab under Full Disk Access, turn it on, and reopen the app.
  - Or choose **cookies.txt file** and select a cookies.txt exported with a browser extension (treat this file like your login and don't share it).
- **KKBOX Open API** and **Spotify API** (optional).

### Update check and reporting problems

- The app checks GitHub for a new version automatically once a day at launch, or click **Check now** in **About**. When a new version is available, it shows what's new and a **Download update** button.
- In **About**, click **Report a problem** or **Suggest a feature** to open GitHub with your version and system details already filled in. Failed downloads also have a **Report** button. You can review and edit everything before submitting, and your user name is never included.

## FAQ

**"Sign in to confirm you're not a bot" or HTTP 403**
YouTube is temporarily asking for verification because of too many requests. Wait a few minutes, click **Update yt-dlp** in Preferences, or turn on **Use my browser's YouTube sign-in**.

**"could not find chrome cookies database"**
macOS isn't letting TubeGrab read the browser's data. Follow the Full Disk Access steps in Preferences, or use a cookies.txt file instead.

**An MP4 won't open in QuickTime**
4K videos usually only exist in VP9 or AV1. Choose 1080p or lower, or use MKV with [IINA](https://iina.io).

**A Spotify or Apple Music playlist can't be read**
The playlist must be public. Website changes can also break reading.

**No lyrics found for a Chinese song**
Check that the title and artist are correct (fix them in the song info first), then click **Find lyrics** to preview. Some lesser-known songs are not in LRCLIB.

**Vocal removal has no effect**
Vocal removal needs a stereo recording; live or near-mono recordings give limited results. Try searching for the official "Artist - Topic" upload instead.

## For developers

### Requirements

| Item | Purpose | Needed |
|---|---|---|
| macOS 14 or later | Running the app | Required |
| Xcode 15 or later, or Command Line Tools (Swift 5.10 or later) | Building | Required |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Reading and downloading videos | Required (the app can install it) |
| [ffmpeg](https://ffmpeg.org/) (with ffprobe) | Merging, converting, trimming, cover art, audio and video processing | Required (the app can install it) |
| [deno](https://deno.com/) | JavaScript runtime that recent yt-dlp versions need for full YouTube support | Recommended |

The Swift code uses no third-party packages, only Apple frameworks: SwiftUI, AVKit, AVFoundation, AppKit and Foundation.

Installing the external tools manually:

```bash
brew install yt-dlp ffmpeg deno
```

### Build and run

```bash
swift run
```

Build `build/TubeGrab.app`:

```bash
./scripts/build-app.sh
```

Build for both Apple Silicon and Intel:

```bash
./scripts/build-app.sh --universal
```

Open in Xcode:

```bash
open Package.swift
```

### Packaging a release

```bash
./scripts/package.sh 1.1
```

This creates `TubeGrab-1.1-macOS.dmg`, `TubeGrab-1.1-macOS.zip` and `SHA256SUMS.txt` in `dist/` (ignored by git). Use a higher version number for every release so the app's update check can notify users.

### Changing the app icon

Save the new image as `assets/logo-source.png` (any background works; the rounded square is detected and the background and glow are removed), then run:

```bash
swift scripts/make-icon.swift
```

This creates `assets/AppIcon.png` and `assets/AppIcon.icns`, which the next build uses automatically.

### Project structure

```text
Package.swift
assets/                         Source image and generated app icons
scripts/
  build-app.sh                  Builds the .app (--universal adds Intel)
  package.sh                    Creates the release .dmg and .zip
  make-icon.swift               Generates the app icon from the source image
Sources/TubeGrab/
  App.swift                     App entry point, sidebar, appearance
  Router.swift                  Sidebar pages and hand-offs between pages
  PageStores.swift              Page contents kept while switching pages
  Layout.swift                  Window-based scaling and compact layouts
  Models.swift                  Settings, download options, song info
  Localization.swift            Translations for five languages
  Theme.swift                   Theme colors, fonts, card and button styles
  Components.swift              Shared components (button styles, banner input bar)
  ProcessRunner.swift           Runs external commands and reads their output line by line
  ToolInstaller.swift           Detects and installs yt-dlp, ffmpeg and deno
  YTDLPService.swift            yt-dlp calls: info, preview, search, download arguments
  DownloadManager.swift         Download queue and progress
  PlaylistImporter.swift        Spotify, Apple Music, KKBOX, text lists and song matching
  PlaylistFileImporter.swift    CSV, TXT and XLSX import
  AudioTools.swift              Audio effects, upscaling and aspect ratio (ffmpeg filters)
  PreviewRenderer.swift         "With settings" preview clips
  AudioPreviewPlayer.swift      Search result previews
  MetadataLookup.swift          Song info from the web (iTunes Search API)
  LyricsService.swift           Lyrics lookup, .lrc files and lyrics tags
  ScoreFinder.swift             Sheet music search and lyrics export
  FileOpener.swift              Opens files in a player that can play them
  Feedback.swift                Problem reports (GitHub issues)
  UpdateChecker.swift           Checks GitHub Releases for new versions
  Views/                        Page views
```

### How it works

- `yt-dlp -J` fetches the video info. Edited titles and artists are written into fields such as `meta_title` and `meta_artist`, then the download runs with `--load-info-json`; `--embed-metadata` writes them into the file.
- Progress: `--progress-template` prints percentages in a fixed format. When trimming, ffmpeg does the download and `out_time_us` from `-progress pipe:2` is used. Video, audio and merging are combined into one continuous overall progress value.
- Audio tools, upscaling and aspect ratio run in a single ffmpeg pass after downloading; the "With settings" preview uses the same pipeline.
- MP3 lyrics are written into the ID3 USLT frame directly by the app (ffmpeg can only write a TXXX frame, which Apple Music ignores); other formats use the lyrics tag.
- For Spotify and Apple Music only song titles and artists from public pages are read; KKBOX uses the official Open API. Songs are then searched on YouTube.

## Open-source projects used

| Project | License | Used for |
|---|---|---|
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | Unlicense | Reading and downloading videos |
| [FFmpeg](https://ffmpeg.org/) | LGPL / GPL | Audio and video processing |
| [Deno](https://deno.com/) | MIT | JavaScript runtime for yt-dlp |
| [LRCLIB](https://lrclib.net/) | Open data | Lyrics database |
| iTunes Search API | Apple | Song info for reference |

## License

The source code of this project is released under the [MIT License](LICENSE). External tools and data sources are used under their own licenses.

Once again: this project is for educational use only. Please respect creators and copyright.
