# Requirements: Coupon Keeper

**Defined:** 2026-05-21
**Core Value:** 사용자가 잊고 있던 현금성 쿠폰 이미지를 찾아 만료 전에 쓰게 만든다.

## v1 Requirements

### App Shell

- [x] **SHELL-01**: User can launch the Flutter app on iOS and Android.
- [x] **SHELL-02**: User can navigate between Today, Wallet, and Scan using bottom tabs.
- [x] **SHELL-03**: User sees first-run empty states that point to guided scan.
- [x] **SHELL-04**: User can use primary actions with one hand on small mobile screens.

### Pass Storage

- [x] **PASS-01**: User can store a pass with type, title, brand, estimated value, expiry, status, source metadata, image copy path, OCR text, and confidence.
- [x] **PASS-02**: User can keep viewing a saved pass after the source photo or file is unavailable, using the app-internal image copy.
- [x] **PASS-03**: User can see active, used, expired, and cleanup-candidate pass states.

### Guided Scan

- [x] **SCAN-01**: User can start a guided scan from the Scan tab or Today CTA.
- [x] **SCAN-02**: User can choose photos or downloadable files/folders without first-launch broad library scanning.
- [x] **SCAN-03**: User sees batch scan progress, live candidate count, and a cancel option.
- [x] **SCAN-04**: App skips already-scanned files using fingerprints.
- [x] **SCAN-05**: User sees a first scan discovery report before reviewing individual candidates.

### OCR and Candidate Confirmation

- [x] **OCR-01**: App extracts text from selected images using iOS Vision or Android ML Kit.
- [x] **OCR-02**: App parses likely expiry dates, values, brands, and barcode candidates from OCR text.
- [x] **OCR-03**: User sees uncertain OCR results as candidates, not as automatically saved passes.
- [x] **OCR-04**: User can edit expiry, value, title, and brand before saving.
- [x] **OCR-05**: User can reject false positive candidates.
- [x] **OCR-06**: User can manually register a pass when OCR finds nothing.

### Wallet and Pass Detail

- [x] **WALL-01**: User can view active passes in Wallet.
- [x] **WALL-02**: User can filter Wallet by active, used, expired, and cleanup candidates.
- [x] **WALL-03**: User can open pass detail and see a large image and barcode area.
- [x] **WALL-04**: User can tap the barcode area to expand it for store use.
- [x] **WALL-05**: User can mark a pass as used.
- [x] **WALL-06**: User can see state chips such as D-7, today expiry, used, expired, confirmation needed, and source missing.

### Reminders

- [x] **REM-01**: Free user receives D-7 and D-Day local notifications for active passes with expiry dates.
- [x] **REM-02**: Pro user can receive D-7, D-3, D-1, D-Day, and custom reminders.
- [x] **REM-03**: App schedules reminders when passes are saved or updated.
- [x] **REM-04**: App reconciles stale, missing, used, or expired reminders on launch/resume.

### Pro and Billing

- [ ] **PRO-01**: Free user can keep up to 5 active passes.
- [ ] **PRO-02**: User sees Pro gate only in context: 6th active pass, custom reminders, unlimited save affordance, or cleanup candidates.
- [ ] **PRO-03**: User can purchase Pro through App Store or Google Play in-app purchase.
- [ ] **PRO-04**: User can restore Pro purchase.
- [ ] **PRO-05**: App caches Pro entitlement locally and keeps free features usable when store checks fail.

### Cleanup

- [x] **CLEAN-01**: User can move a used pass into cleanup candidates.
- [x] **CLEAN-02**: User can review cleanup candidates without automatic source deletion.
- [x] **CLEAN-03**: User can hand off source cleanup to the system UI or original app when available.
- [x] **CLEAN-04**: User sees a source-missing state when the original file is gone.

### Privacy, Accessibility, and Quality

- [ ] **QUAL-01**: App works without account login, server sync, or cloud backup.
- [ ] **QUAL-02**: App does not send photos, coupon images, OCR text, or location data off-device.
- [ ] **QUAL-03**: App exposes loading, empty, error, success, and partial-success UI states for Today, Scan, Wallet, Pass Detail, Pro Gate, and Cleanup.
- [ ] **QUAL-04**: App uses 44px minimum touch targets, body text 16px or larger, 4.5:1 contrast, and non-color-only state indicators.
- [ ] **QUAL-05**: App provides screen reader labels for barcode, expiry, status, and primary actions.
- [ ] **QUAL-06**: App includes unit, widget, and integration tests for the core flows.
- [ ] **QUAL-07**: App can be built for iOS App Store and Google Play internal testing.

## v2 Requirements

### Pro Expansion

- **V2-PRO-01**: User can explicitly grant wider photo/download access for stronger Pro auto-scan.
- **V2-PRO-02**: User can attach places to passes and receive local place-based reminders.

### Wallet Integration

- **V2-WALT-01**: User can add supported pass types to Apple Wallet or Google Wallet when platform requirements are met.

### Intelligence

- **V2-INT-01**: App can use user-confirmed corrections to improve on-device coupon/pass classification.

### Sync

- **V2-SYNC-01**: User can opt into cloud backup or cross-device sync if local-only MVP proves valuable.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Server sync/account login | MVP trust and speed depend on local-only operation. |
| First-launch full-library auto-scan | Permissions and review risk are too high before trust is earned. |
| Apple Wallet/Google Wallet pass generation | Certificate, issuer, and API scope is too large for MVP. |
| Background GPS store detection | Location permission and privacy tradeoffs are not justified in v1. |
| Free ads | Ad SDKs conflict with privacy messaging. |
| Server receipt validation | Backend cost and account complexity are not needed for first validation. |
| Auto-delete source images | User trust risk is too high; deletion must stay explicit. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHELL-01 | Phase 1 | Complete |
| SHELL-02 | Phase 1 | Complete |
| SHELL-03 | Phase 1 | Complete |
| SHELL-04 | Phase 1 | Complete |
| PASS-01 | Phase 1 | Complete |
| PASS-02 | Phase 1 | Complete |
| PASS-03 | Phase 1 | Complete |
| SCAN-01 | Phase 2 | Complete |
| SCAN-02 | Phase 2 | Complete |
| SCAN-03 | Phase 2 | Complete |
| SCAN-04 | Phase 2 | Complete |
| SCAN-05 | Phase 3 | Complete |
| OCR-01 | Phase 3 | Complete |
| OCR-02 | Phase 3 | Complete |
| OCR-03 | Phase 3 | Complete |
| OCR-04 | Phase 3 | Complete |
| OCR-05 | Phase 3 | Complete |
| OCR-06 | Phase 3 | Complete |
| WALL-01 | Phase 4 | Complete |
| WALL-02 | Phase 4 | Complete |
| WALL-03 | Phase 4 | Complete |
| WALL-04 | Phase 4 | Complete |
| WALL-05 | Phase 4 | Complete |
| WALL-06 | Phase 4 | Complete |
| REM-01 | Phase 5 | Complete |
| REM-02 | Phase 5 | Complete |
| REM-03 | Phase 5 | Complete |
| REM-04 | Phase 5 | Complete |
| PRO-01 | Phase 6 | Pending |
| PRO-02 | Phase 6 | Pending |
| PRO-03 | Phase 6 | Pending |
| PRO-04 | Phase 6 | Pending |
| PRO-05 | Phase 6 | Pending |
| CLEAN-01 | Phase 4 | Complete |
| CLEAN-02 | Phase 4 | Complete |
| CLEAN-03 | Phase 4 | Complete |
| CLEAN-04 | Phase 4 | Complete |
| QUAL-01 | Phase 7 | Pending |
| QUAL-02 | Phase 7 | Pending |
| QUAL-03 | Phase 7 | Pending |
| QUAL-04 | Phase 7 | Pending |
| QUAL-05 | Phase 7 | Pending |
| QUAL-06 | Phase 7 | Pending |
| QUAL-07 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 44 total
- Mapped to phases: 44
- Unmapped: 0

---
*Requirements defined: 2026-05-21*
*Last updated: 2026-06-05 after Phase 5 MVP Light completion*
