#!/bin/bash
# 把 Swift Package 打包成可以雙擊開啟的 TubeGrab.app
set -euo pipefail
cd "$(dirname "$0")/.."

# 用法：
#   ./scripts/build-app.sh              只編譯這台 Mac 的架構（開發用，較快）
#   ./scripts/build-app.sh --universal  同時支援 Apple Silicon 與 Intel（發佈用）
# 版本號可用環境變數 VERSION 指定，例如 VERSION=1.2 ./scripts/build-app.sh --universal
APP="build/TubeGrab.app"
VERSION="${VERSION:-1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"

if [ "${1:-}" = "--universal" ]; then
    swift build -c release --arch arm64 --arch x86_64
    BIN="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/TubeGrab"
else
    swift build -c release
    BIN=".build/release/TubeGrab"
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/TubeGrab"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>TubeGrab</string>
    <key>CFBundleDisplayName</key><string>TubeGrab</string>
    <key>CFBundleIdentifier</key><string>com.example.tubegrab</string>
    <key>CFBundleExecutable</key><string>TubeGrab</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleDevelopmentRegion</key><string>zh-Hant</string>
    <key>CFBundleLocalizations</key>
    <array><string>zh-Hant</string><string>zh-Hans</string><string>en</string><string>ja</string><string>ko</string></array>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>NSHumanReadableCopyright</key><string>Copyright (c) 2026 Yu-Cheng Chang. MIT License. For educational use only.</string>
</dict>
</plist>
PLIST

# App 圖示（由 swift scripts/make-icon.swift 產生）
if [ -f assets/AppIcon.icns ]; then cp assets/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"; fi
if [ -f assets/AppIcon.png ]; then cp assets/AppIcon.png "$APP/Contents/Resources/AppIcon.png"; fi

# 平台 Logo（選用）：logos/kkbox.png 等
if [ -d logos ]; then cp -R logos "$APP/Contents/Resources/logos"; fi

# 清掉檔案上的 macOS 附加屬性（否則 zip 裡會多出 __MACOSX 資料夾）
xattr -cr "$APP" 2>/dev/null || true

# 本機自簽（ad-hoc），讓 macOS 允許執行
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

# 讓 Finder / Dock 立刻顯示新圖示
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP" >/dev/null 2>&1 || true
touch "$APP"

echo "完成：$(pwd)/$APP"
echo "   可以把它拖到「應用程式」資料夾。"
