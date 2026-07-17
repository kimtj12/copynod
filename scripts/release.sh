#!/bin/bash
# CopyNod 릴리스 파이프라인: archive → Developer ID 서명 export → notarize → staple → zip → appcast.
#
# 사전 요건 (1회 설정, docs/release.md 참조):
#   1. Developer ID Application 인증서가 키체인에 있을 것
#   2. notarytool 자격 증명: xcrun notarytool store-credentials copynod-notary \
#        --apple-id <애플ID> --team-id RC348YTD6U --password <앱 암호>
#   3. Sparkle EdDSA 개인 키가 로그인 키체인에 있을 것 (generate_keys로 생성)
#
# 사용: scripts/release.sh
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD=build
ARCHIVE="$BUILD/CopyNod.xcarchive"
EXPORT="$BUILD/export"
APP="$EXPORT/CopyNod.app"

echo "==> Archive (Release)"
xcodebuild -project CopyNod.xcodeproj -scheme CopyNod -configuration Release \
  archive -archivePath "$ARCHIVE" -quiet

echo "==> Export (Developer ID 서명)"
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath "$EXPORT" -quiet

VERSION=$(defaults read "$PWD/$APP/Contents/Info" CFBundleShortVersionString)
ZIP="$BUILD/CopyNod-$VERSION.zip"

echo "==> Notarize (버전 $VERSION)"
# --norsrc: 확장 속성(com.apple.provenance 등)을 AppleDouble(._*)로 zip에 넣지 않는다.
# 넣으면 Finder 압축 해제가 심볼릭 링크의 ._* 파일을 실파일로 남겨 Gatekeeper가 거부한다.
ditto -c -k --norsrc --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile copynod-notary --wait

echo "==> Staple 후 재압축"
xcrun stapler staple "$APP"
rm "$ZIP"
ditto -c -k --norsrc --keepParent "$APP" "$ZIP"

# appcast는 최신 릴리스 1건만 담는다 (의도) — Sparkle 업데이트에는 최신 항목이면 충분하고,
# 과거 릴리스 이력은 GitHub Releases가 보존한다.
echo "==> Appcast 생성 (EdDSA 서명 포함) → docs/appcast.xml"
GENERATE_APPCAST=$(find ~/Library/Developer/Xcode/DerivedData/CopyNod-*/SourcePackages/artifacts/sparkle/Sparkle/bin -name generate_appcast | head -1)
APPCAST_DIR="$BUILD/appcast"
mkdir -p "$APPCAST_DIR"
cp "$ZIP" "$APPCAST_DIR/"
"$GENERATE_APPCAST" "$APPCAST_DIR" \
  --download-url-prefix "https://github.com/kimtj12/copynod/releases/download/v$VERSION/"
cp "$APPCAST_DIR/appcast.xml" docs/appcast.xml

echo
echo "완료. 남은 수동 단계:"
echo "  1. gh release create v$VERSION $ZIP --title \"CopyNod $VERSION\" --notes \"...\""
echo "  2. docs/appcast.xml 커밋·푸시 (GitHub Pages가 docs/에서 서빙)"
