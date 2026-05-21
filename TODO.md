# TODO

## Coupon Keeper

### P2: Apple Wallet/Google Wallet 추가 기능 검토

- What: 쿠폰/교환권/바코드 이미지를 Apple Wallet 또는 Google Wallet 패스로
  추가하는 기능을 검토한다.
- Why: 해외 확장과 Wallet 보완재 포지셔닝에는 도움이 되지만, MVP에서는
  인증서, 서명, issuer 계정, API 제약 때문에 범위가 커진다.
- Context: 첫 출시에서는 Wallet을 대체하지 않고, Wallet 밖에 남은 이미지를
  찾아주는 로컬 쿠폰 지갑에 집중한다.
- Effort: M
- Priority: P2
- Depends on: MVP에서 쿠폰 탐지, 만료 알림, 쿠폰 지갑 사용성이 검증된 뒤 진행한다.

### P2: 자주 가는 장소 기반 알림 검토

- What: 사용자가 쿠폰에 장소를 직접 연결하면, 해당 장소 근처에서 쿠폰 사용을
  알려주는 Pro 기능을 검토한다.
- Why: 매장 앞에서 쿠폰을 떠올리는 실제 사용 장면과 잘 맞지만, 위치 권한과
  앱 심사 리스크가 크다.
- Context: MVP에서는 위치 권한을 요청하지 않는다. 후속 버전에서 사용자가 명시적으로
  장소를 등록하는 로컬 리마인더 방식부터 검토한다.
- Effort: M
- Priority: P2
- Depends on: Pro 기능 가치와 사용자 신뢰 메시지가 검증된 뒤 진행한다.

### P3: 무료 광고 수익화 재검토

- What: 무료 버전에 광고를 넣을지 MVP 이후 다시 검토한다.
- Why: 초기에는 로컬/개인정보 보호 메시지가 중요하고, 광고 SDK는 추적 동의와
  신뢰 저하를 만들 수 있다.
- Context: MVP에서는 광고를 넣지 않는다. 사용자 수, 유지율, Pro 전환율을 본 뒤
  광고가 제품 신뢰보다 큰 수익을 만들 수 있는지 판단한다.
- Effort: S
- Priority: P3
- Depends on: MVP 출시 후 사용량과 구매 전환 데이터가 필요하다.

### P2: Pro 확장 자동 스캔 검토

- What: 사용자가 명시적으로 허용한 경우 전체 사진첩 또는 다운로드 폴더의 더 넓은
  자동 스캔을 Pro 기능으로 제공할지 검토한다.
- Why: 숨어 있는 쿠폰을 더 많이 찾을 수 있지만, 권한 허들과 앱 심사 리스크가 커진다.
- Context: MVP는 guided scan으로 시작한다. 사용자가 앱을 신뢰하고 첫 스캔/알림 가치를
  경험한 뒤, 더 강한 자동화가 구매 전환을 만드는지 확인한다.
- Effort: M
- Priority: P2
- Depends on: guided scan 유지율, 첫 스캔 완료율, Pro 전환 데이터가 필요하다.

### P2: 온디바이스 쿠폰 분류 모델 고도화 검토

- What: 규칙 기반 OCR 파서 이후, 사용자 수정 데이터를 기반으로 온디바이스 쿠폰/패스
  분류 모델을 도입할지 검토한다.
- Why: 국가별 쿠폰 형식과 브랜드 패턴을 더 잘 잡을 수 있지만, 테스트셋과 모델 품질
  관리가 필요하다.
- Context: MVP에서는 iOS Vision과 Android ML Kit OCR 결과를 규칙 기반으로 후보화한다.
  사용자 확인/수정 결과를 저장해 나중에 모델 개선 재료로 쓸 수 있게 한다.
- Effort: L
- Priority: P2
- Depends on: 충분한 후보/수정 데이터와 오탐/미탐 패턴 분석이 필요하다.

### P3: 서버 영수증 검증 검토

- What: App Store와 Google Play 구매 영수증을 서버에서 검증하는 구조를 도입할지
  검토한다.
- Why: 부정 구매 방지는 강화되지만, 서버, 계정, 운영 비용이 생기며 로컬-only 메시지가
  약해질 수 있다.
- Context: MVP는 스토어 인앱결제와 기기 로컬 entitlement 캐시로 시작한다. 실제 결제
  문제나 환불/복원 이슈가 관찰되기 전까지 서버 검증은 미룬다.
- Effort: M
- Priority: P3
- Depends on: 출시 후 구매/복원 실패율과 부정 사용 리스크 관찰이 필요하다.

### P2: 앱스토어/플레이스토어 배포 파이프라인 설계

- What: Flutter iOS/Android 빌드, 서명, 릴리즈 노트, 스토어 메타데이터, 내부 테스트
  배포 절차를 설계한다.
- Why: 모바일 앱은 코드가 있어도 서명과 스토어 배포가 준비되지 않으면 사용자가 설치할
  수 없다.
- Context: 현재 문서는 제품/아키텍처 계획 단계다. 앱 스캐폴드가 만들어지면 TestFlight,
  Google Play internal testing, 스토어 인앱결제 상품 설정까지 묶어서 설계해야 한다.
- Effort: M
- Priority: P2
- Depends on: 앱 번들 ID, Flutter 프로젝트 생성, 첫 실행 가능한 빌드가 필요하다.

### P2: Coupon Keeper 고충실도 mockup 생성

- What: gstack designer 인증 설정 후 Today, Wallet, Scan, Pass Detail, Pro Gate의
  고충실도 mockup과 비교 보드를 생성한다.
- Why: 현재 디자인 리뷰는 텍스트 기반 UX 기획까지 완료했지만, 실제 시각 방향은 아직
  이미지로 검증하지 않았다.
- Context: 로컬 gstack designer는 `~/.gstack/openai.json` 또는 `OPENAI_API_KEY` 기반
  인증만 지원한다. OAuth/MCP 로그인 방식은 현재 지원되지 않는다.
- Effort: S
- Priority: P2
- Depends on: OpenAI API key 설정 또는 gstack designer의 OAuth/MCP 인증 지원이 필요하다.

### P2: Coupon Keeper DESIGN.md 분리

- What: 설계 문서 안의 미니 디자인 시스템을 앱 스캐폴드 생성 후 `DESIGN.md`로
  분리한다.
- Why: 구현자가 색상, 타입, 상태 칩, pass row, barcode panel 규칙을 일관되게 재사용할
  수 있어야 한다.
- Context: MVP 기획 단계에서는 `coupon-wallet-design.md` 안에 미니 시스템을 먼저
  포함했다. mockup이 확정되면 실제 토큰과 컴포넌트 규칙을 별도 문서로 승격한다.
- Effort: S
- Priority: P2
- Depends on: Flutter 앱 스캐폴드와 첫 mockup 방향 확정이 필요하다.
