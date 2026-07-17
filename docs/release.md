# CopyNod — 릴리스 절차

> M4에서 작성 (2026-07-17). 자동화된 부분은 [scripts/release.sh](../scripts/release.sh), 이 문서는 1회 설정과 수동 단계.

## 1회 설정 (릴리스 전 필수)

1. **Developer ID Application 인증서** — 현재 키체인에 없음 (2026-07-17 확인).
   - Xcode → Settings → Accounts → 팀(YYQ8RM9QJ9) 선택 → Manage Certificates… → `+` → Developer ID Application.
   - 확인: `security find-identity -v -p codesigning`에 "Developer ID Application"이 보여야 함.
2. **notarytool 자격 증명** — [appleid.apple.com](https://appleid.apple.com)에서 앱 암호(app-specific password) 발급 후:
   ```bash
   xcrun notarytool store-credentials copynod-notary \
     --apple-id <애플ID 이메일> --team-id YYQ8RM9QJ9 --password <앱 암호>
   ```
3. **Sparkle EdDSA 키** — 생성 완료 (2026-07-17, 로그인 키체인의 "Private key for signing Sparkle updates").
   공개 키는 project.yml의 `SUPublicEDKey`. **이 키를 잃으면 기존 사용자에게 업데이트를 배포할 수 없으니 키체인 백업 필수.**
4. **GitHub Pages** — 저장소 Settings → Pages → Branch `main`, 폴더 `/docs`.
   appcast 주소(`SUFeedURL`): `https://kimtj12.github.io/copynod/appcast.xml` ← `docs/appcast.xml`로 서빙됨.

## 릴리스 단계

1. `project.yml`에서 `CFBundleShortVersionString`·`CFBundleVersion` 올리고 `xcodegen generate`, 커밋.
2. `scripts/release.sh` 실행 — archive → Developer ID export → notarize(대기) → staple → zip → `docs/appcast.xml` 생성까지 자동.
3. GitHub Release 발행 (스크립트가 정확한 명령을 출력):
   ```bash
   gh release create v<버전> build/CopyNod-<버전>.zip --title "CopyNod <버전>" --notes "..."
   ```
4. `docs/appcast.xml` 커밋·푸시.
5. **업데이트 플로우 테스트**: 이전 버전을 실행해 메뉴바 → Check for Updates…로 새 버전 감지·설치가 되는지 확인.

## 배터리 예산 검증 (릴리스 전 1회)

planning.md 6절의 목표치 확인 절차:

1. CopyNod 실행 후 10분 이상 유휴 상태로 둔다.
2. Activity Monitor → CPU 탭: `% CPU` ~0, `Idle Wake Ups` ~0/초인지 확인. Energy 탭: Energy Impact가 목록 바닥권인지 확인.
3. 메모리 탭: 상주 메모리 40MB 이하 확인.
4. 정밀 측정이 필요하면: `sudo powermetrics --samplers tasks --show-process-energy -i 5000 -n 12 | grep -i copynod`.
