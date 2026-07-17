#!/bin/bash
# 손쉬운 사용(Accessibility) 권한 꼬임 복구.
#
# 서명이 다른 빌드(개발용 ↔ Developer ID)로 앱을 교체하면 TCC 항목이 옛 서명에
# 묶여, 시스템 설정에 토글은 보여도 실제 권한(AXIsProcessTrusted)은 거부된다.
# 유일한 해법은 항목을 지우고 다시 허용하는 것.
#
# 사용: scripts/reset-accessibility.sh
set -euo pipefail

BUNDLE_ID=kr.ai.simpool.CopyNod

echo "==> CopyNod 종료"
pkill -x CopyNod 2>/dev/null || true

echo "==> TCC Accessibility 항목 리셋 ($BUNDLE_ID)"
tccutil reset Accessibility "$BUNDLE_ID"

echo "==> CopyNod 재실행"
open -a CopyNod

echo
echo "완료. 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 CopyNod를 다시 허용하세요."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
