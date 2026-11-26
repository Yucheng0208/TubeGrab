#!/bin/bash
# 把 Swift Package 打包成可以雙擊開啟的 TubeGrab.app
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/TubeGrab.app"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/release/TubeGrab" "$APP/Contents/MacOS/TubeGrab"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>TubeGrab</string>
    <key>CFBundleDisplayName</key><string>TubeGrab</string>
    <key>CFBundleIdentifier</key><string>com.example.tubegrab</string>
    <key>CFBundleExecutable</key><string>TubeGrab</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleDevelopmentRegion</key><string>zh-Hant</string>
    <key>CFBundleLocalizations</key>
    <array><string>zh-Hant</string><string>zh-Hans</string><string>en</string><string>ja</string><string>ko</string></array>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# 平台 Logo（選用）：logos/kkbox.png 等
if [ -d logos ]; then cp -R logos "$APP/Contents/Resources/logos"; fi

# 本機自簽（ad-hoc），讓 macOS 允許執行
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✅ 完成：$(pwd)/$APP"
echo "   可以把它拖到「應用程式」資料夾。"
