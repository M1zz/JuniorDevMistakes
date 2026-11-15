# TODO

## App Store 심사 대응
- [x] Paywall에 이용약관(EULA)/개인정보처리방침 링크 추가 (3.1.2(c), c4b06b6)
- [ ] App Store Connect 앱 설명(Description) 하단에 이용약관(EULA) 링크 추가 — 3.1.2(c) 리젝 대응
- [ ] App Review Information의 Notes 필드에 EULA 링크 위치 안내 문구 추가
- [ ] 심사 메시지에 스크린 레코딩 첨부하여 회신

## 리브랜딩 (앱 이름 · 아이콘) — 2026-11-15 진행분

### 결정된 것
- 앱 이름: 한국어 "시니어 개발자로", 영어 "Road to Senior Dev" (영어 홈 화면 이름은 잘림 방지로 "Senior Dev")
- 아이콘 방향: <V/> 셀프 클로징 태그 모양 (괄호 · 슬래시는 코드, 가운데 체크는 실수 확인)

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

### 다음에 할 일
- [ ] 아이콘 최종안 고르기 (6차 P1~P4 중, 또는 더 다듬기)
- [ ] 고른 PNG 를 JuniorDevMistakes/Assets.xcassets/AppIcon.appiconset/1024.png 로 교체 후 빌드 (지금 아이콘에는 AI 생성 워터마크가 있어 꼭 교체)
- [ ] docs/icon.png (웹 페이지 아이콘)도 같이 교체
- [ ] 나머지 21개 언어 이름 바꿀지 결정 (지금은 옛 이름 유지: やらかし100, 踩坑100 등)
- [ ] App Store Connect 인앱 상품 이름 "실수 100 PRO" 바꿀지 결정
- [ ] Mac 메뉴 "주니어 개발자의 실수 100 정보" 문구 (24개 언어 키라 보류)
- [ ] 스크린샷 문구(scripts/compose_screenshots.py)에 앱 이름 들어가는지 확인

### 참고
- 원래 컴퓨터에 커밋 안 한 pbxproj 변경이 git stash 에 남아 있음 (Mac Catalyst · iPad 지원 끄기). stash 는 푸시되지 않으므로 다른 컴퓨터에는 없음. 필요 없으면 원래 컴퓨터에서 git stash drop
