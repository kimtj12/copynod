#!/bin/bash
# 개발 버전을 설치본과 같은 Developer ID 서명으로 빌드해 실행.
#
# 디버그 빌드(Apple Development 서명)는 기존 TCC 항목과 서명이 달라 손쉬운 사용
# 권한이 꼬인다 (scripts/reset-accessibility.sh 참조). 릴리스 파이프라인의
# archive → export만 수행하면 설치본과 서명이 같아 권한 리셋 없이 실행된다.
# notarize는 생략 — 로컬 빌드는 격리 속성이 없어 Gatekeeper를 거치지 않는다.
#
# 확인이 끝나면: 앱 종료 후 `open -a CopyNod`로 설치본 재실행.
#
# 사용: scripts/run-dev.sh
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD=build
ARCHIVE="$BUILD/dev.xcarchive"
EXPORT="$BUILD/dev-export"

echo "==> Archive (Release)"
xcodebuild -project CopyNod.xcodeproj -scheme CopyNod -configuration Release \
  archive -archivePath "$ARCHIVE" -quiet

echo "==> Export (Developer ID 서명)"
rm -rf "$EXPORT"
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist scripts/ExportOptions.plist -exportPath "$EXPORT" -quiet

echo "==> 실행 중인 CopyNod 종료 후 개발 버전 실행"
pkill -x CopyNod 2>/dev/null || true
open "$EXPORT/CopyNod.app"

echo
echo "완료. 확인이 끝나면 앱을 종료하고 'open -a CopyNod'로 설치본을 다시 실행하세요."
