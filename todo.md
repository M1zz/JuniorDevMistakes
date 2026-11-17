# TODO

## App Store 심사 대응
- [x] Paywall에 이용약관(EULA)/개인정보처리방침 링크 추가 (3.1.2(c), c4b06b6)
- [ ] App Store Connect 앱 설명(Description) 하단에 이용약관(EULA) 링크 추가 — 3.1.2(c) 리젝 대응
- [ ] App Review Information의 Notes 필드에 EULA 링크 위치 안내 문구 추가
- [ ] 심사 메시지에 스크린 레코딩 첨부하여 회신

## 리브랜딩 (앱 이름 · 아이콘) — 2026-11-15 진행분

### 결정된 것
- 앱 이름: 한국어 "시니어 개발자로", 영어 "Road to Senior Dev" (영어 홈 화면 이름은 잘림 방지로 "Senior Dev")
- 아이콘: 9차 N3 반창고 붙인 버그 (버그 = 실수, 반창고 = 고쳐 준다). 원본 design/icon-drafts/v9/N3.svg

### 완료
- [x] git pull (원격 47개 커밋 반영)
- [x] InfoPlist.xcstrings 표시 이름 ko · en · en-GB 변경, pbxproj 기본 표시 이름 변경
- [x] APPSTORE.md ko · en · en-GB 이름 · 부제 · 설명 속 앱 이름 변경
- [x] 소개 · 지원 · 개인정보 페이지 ko · en · en-GB 앱 이름 변경 (docs/, docs/site/*.json, scripts/docs_i18n/*.json)
- [x] 빌드 확인 (iOS 시뮬레이터, 에러 없음)
- [x] 아이콘 시안 1~6차 제작 → design/icon-drafts/ (drafts.html 을 브라우저로 열면 전체 비교)
  - 온라인 시안 페이지: https://claude.ai/artifact/DN3i6aPnYkdrKs1YhJHbrY
  - 6차(최신): P1 미드나잇 터미널(추천) · P2 인디고 글로우 · P3 페이퍼 · P4 선라이즈
  - P1~P4.svg 와 1024 PNG 포함, make_icons.py 로 다시 생성 가능 (cd design/icon-drafts && python3 make_icons.py)

- [x] 7차 "쌈뽕 버전" 제작 → design/icon-drafts/v7/ (K1 키캡 · K2 네온 · K3 리퀴드 글래스 · K4 레벨 업, make_v7.py 로 재생성)
- [x] 8차 플랫(그라데이션 없음) 제작 → design/icon-drafts/v8/ (F1 큰 체크 · F2 빨강→초록 · F3 터미널 · F4 잘린 괄호 · F5 체크리스트 · F6 코랄 원, make_v8.py)
- [x] 9차 새 소재(플랫) 제작 → design/icon-drafts/v9/ (N1 고무 오리 · N2 뿔테 안경 · N3 반창고 버그 · N4 경험치 바 · N5 깃 그래프 · N6 픽셀 왕관, make_v9.py)

### 다음에 할 일
- [x] 아이콘 최종안: 9차 N3 반창고 버그
- [x] AppIcon 1024.png 교체 (알파 없는 RGB) 후 빌드 확인
- [x] docs/icon.png (웹 페이지 아이콘) 교체
- [ ] App Store 스크린샷 · 프로모션 이미지에 옛 아이콘이 들어갔는지 확인
- [ ] 나머지 21개 언어 이름 바꿀지 결정 (지금은 옛 이름 유지: やらかし100, 踩坑100 등)
- [ ] App Store Connect 인앱 상품 이름 "실수 100 PRO" 바꿀지 결정
- [ ] Mac 메뉴 "주니어 개발자의 실수 100 정보" 문구 (24개 언어 키라 보류)
- [ ] 스크린샷 문구(scripts/compose_screenshots.py)에 앱 이름 들어가는지 확인

### 참고
- 원래 컴퓨터에 커밋 안 한 pbxproj 변경이 git stash 에 남아 있음 (Mac Catalyst · iPad 지원 끄기). stash 는 푸시되지 않으므로 다른 컴퓨터에는 없음. 필요 없으면 원래 컴퓨터에서 git stash drop
