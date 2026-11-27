#!/bin/bash
# 打包發佈檔：產生 dist/ 底下的 .dmg 與 .zip（可直接上傳到 GitHub Releases）
# 用法：./scripts/package.sh [版本號]    例如 ./scripts/package.sh 1.0
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.0}"
NAME="TubeGrab-${VERSION}-macOS"
DIST="dist"
APP="build/TubeGrab.app"

echo "== 1/4 編譯（Apple Silicon + Intel）"
VERSION="$VERSION" ./scripts/build-app.sh --universal

echo "== 2/4 檢查"
lipo -info "$APP/Contents/MacOS/TubeGrab"
codesign --verify --deep "$APP" && echo "簽章檢查通過（ad-hoc）"

rm -rf "$DIST" && mkdir -p "$DIST"

echo "== 3/4 ZIP"
ditto -c -k --norsrc --noextattr --noqtn --noacl --keepParent "$APP" "$DIST/$NAME.zip"

echo "== 4/4 DMG"
STAGE="$(mktemp -d)/TubeGrab"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/LICENSE.txt"
cat > "$STAGE/請先閱讀 Read Me.txt" <<'TXT'
TubeGrab — macOS 影片／音樂下載工具（教學範例）

【安裝】
1. 把 TubeGrab 拖到右邊的「Applications（應用程式）」資料夾。
2. 第一次打開：在「應用程式」資料夾裡對 TubeGrab 按右鍵 →「打開」→ 再按一次「打開」。
   （本程式沒有經過 Apple 公證，macOS 第一次會詢問；之後就可以直接雙擊。）
   若出現「已損毀，無法打開」，請打開「終端機」執行：
   xattr -dr com.apple.quarantine /Applications/TubeGrab.app
3. 打開後若看到「需要安裝下載工具」，按「一鍵安裝」即可。

【需求】macOS 14 Sonoma 以上，Apple Silicon 與 Intel Mac 皆可。

【免責聲明】本程式僅供教學與範例用途。請只下載你擁有權利或已獲授權的內容，
並遵守各平台服務條款與著作權法。本程式依「現狀」提供，不提供任何保證；
使用本程式所產生的一切後果由使用者自行承擔，作者不負任何責任。

----
Install: drag TubeGrab to Applications. First launch: right-click the app → Open → Open
(it is not notarized by Apple). If macOS says it is damaged, run in Terminal:
  xattr -dr com.apple.quarantine /Applications/TubeGrab.app
Disclaimer: for educational use only. Provided "as is" without warranty;
you use it at your own risk and the author accepts no liability.
TXT
hdiutil create -volname "TubeGrab ${VERSION}" -srcfolder "$STAGE" -ov -format UDZO "$DIST/$NAME.dmg" >/dev/null
rm -rf "$(dirname "$STAGE")"

(cd "$DIST" && shasum -a 256 "$NAME.dmg" "$NAME.zip" > SHA256SUMS.txt)

echo
echo "完成：$(pwd)/$DIST"
ls -lh "$DIST"
