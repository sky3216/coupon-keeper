# Research: Pitfalls

**Generated:** 2026-05-21
**Project:** Coupon Keeper

## Common Mistakes

| Pitfall | Warning Sign | Prevention | Phase |
|---------|--------------|------------|-------|
| Asking for broad photo access too early | First launch permission prompt feels scary | Start with guided scan and selected assets | Phase 2 |
| Treating OCR as truth | Wrong expiry dates silently saved | Require confirmation and confidence states | Phase 3 |
| Building a card-heavy dashboard | Wallet looks pretty but is slow to scan | Use compact lists and large detail only | Phase 4 |
| Hiding useful alerts behind Pro | Free users do not feel the core value | Free D-7/D-Day reminders | Phase 5 |
| Auto-deleting source images | User loses an important image | Cleanup candidates only, system UI handoff | Phase 4 |
| Overbuilding payment infrastructure | Server/account scope appears too early | Local entitlement cache for MVP | Phase 6 |
| Delaying accessibility | Barcode and actions fail in real store use | 44px targets, labels, enlarged barcode mode | Phase 4 |

## Prevention Strategy

Keep the product honest: every automated step should either be reversible, confirmed by the user, or framed as a candidate. The app earns trust by being useful even when OCR is uncertain.
