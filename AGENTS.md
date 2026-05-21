# Coupon Keeper 작업 규칙

이 저장소는 Coupon Keeper 단일 앱 저장소다. 앱과 관련된 기획, GSD 계획, 구현 코드, 테스트, 출시 준비 문서는 모두 이 저장소 안에서 관리한다.

## 기본 원칙

1. 문서 내용은 한국어로 작성한다.
2. 파일명과 폴더명은 영어 kebab-case를 사용한다.
3. iOS와 Android를 함께 지원하는 구조를 유지한다.
4. 서버, 로그인, 클라우드 백업 없이 로컬-first MVP를 우선한다.
5. 사진, 쿠폰 이미지, OCR 텍스트, 위치 정보는 기기 밖으로 전송하지 않는다.
6. 큰 구현 작업은 `.planning/ROADMAP.md`의 phase 순서를 따른다.

## Product Context

핵심 가치는 사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만드는 것이다.

현재 결정:

- Flutter + native platform channels
- Guided scan-first 권한 모델
- SQLite + 앱 내부 이미지 사본
- `coupon`이 아닌 `pass` 중심 도메인 모델
- Today / Wallet / Scan 하단 탭
- 무료 D-7/D-Day 알림
- 맥락형 Pro 게이트

## GSD 컨텍스트

- 프로젝트 문서: `.planning/PROJECT.md`
- 요구사항: `.planning/REQUIREMENTS.md`
- 로드맵: `.planning/ROADMAP.md`
- 현재 상태: `.planning/STATE.md`
- 연구 요약: `.planning/research/SUMMARY.md`

다음 단계는 `$gsd-discuss-phase 1`이다.

## Workflow

파일을 크게 수정하거나 새 기능을 구현하기 전에는 GSD 명령으로 시작해 `.planning/` 컨텍스트와 실행 상태를 맞춘다.

- 작은 문서 수정이나 단발 작업: `$gsd-quick`
- 버그 조사와 수정: `$gsd-debug`
- phase 시작 전 맥락 정리: `$gsd-discuss-phase <번호>`
- phase 계획 작성: `$gsd-plan-phase <번호>`
- 계획된 phase 실행: `$gsd-execute-phase <번호>`
- phase 검증: `$gsd-verify-work <번호>`

사용자가 명시적으로 GSD 우회를 요청하지 않는 한, Coupon Keeper 구현 작업은 `.planning/ROADMAP.md`의 phase 순서를 기준으로 진행한다.

## Planned App Structure

```text
lib/
  presentation/
  application/
  domain/
  data/
  platform/
```

- `presentation`: 화면, 위젯, 라우팅, 사용자 입력 처리
- `application`: 스캔 시작, 후보 승인, 사용 완료, 알림 재조정 같은 유스케이스
- `domain`: `Pass`, `ScanCandidate`, `ReminderPlan`, `Entitlement` 같은 순수 모델과 규칙
- `data`: SQLite repository, 이미지 사본 저장소, 로컬 entitlement 캐시
- `platform`: iOS/Android 사진 선택, 파일 접근, OCR, 알림, 인앱결제 어댑터

## Quality Bar

- 자동 등록이 아니라 자동 후보화 후 사용자 확인을 기본으로 한다.
- OCR 확신도가 낮은 값은 숨기거나 `확인 필요` 상태로 보여준다.
- 원본 이미지는 자동 삭제하지 않고 정리 후보와 시스템 UI 위임까지만 제공한다.
- 주요 UI는 로딩, 빈 상태, 오류, 성공, 부분 성공 상태를 모두 가진다.
- 터치 타깃은 44px 이상, 본문은 16px 이상, 상태는 색만으로 표현하지 않는다.
- 구현 완료 전 단위 테스트, 위젯 테스트, 통합 테스트 중 해당 범위에 맞는 검증을 추가한다.
