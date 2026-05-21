# Research: Architecture

**Generated:** 2026-05-21
**Project:** Coupon Keeper

## Component Boundaries

```text
Flutter presentation
  -> application use cases
  -> domain models and rules
  -> data repositories
  -> platform adapters
       -> iOS Swift: PhotosPicker, Vision, UserNotifications, StoreKit bridge
       -> Android Kotlin: Photo Picker/SAF, ML Kit, notifications, Play Billing bridge
```

## Data Flow

```text
user-selected photos/folder
  -> native media/file adapter
  -> native OCR
  -> normalized OCR result
  -> coupon/pass candidate detector
  -> date/value/brand/barcode parser
  -> discovery report
  -> user confirmation
  -> SQLite pass metadata
  -> app-internal image copy
  -> local notification scheduler
```

## Build Order Implications

1. Define pass domain model and repository contracts before platform work.
2. Build UI shell and empty states early so user flows have a place to land.
3. Use platform test doubles before native OCR is complete.
4. Add real native adapters behind stable interfaces.
5. Keep Pro entitlement and notification rules testable in pure Dart.

## Architecture Risks

- Platform channel details leaking into UI will make screens brittle.
- OCR confidence and parsing errors must be visible as candidate uncertainty, not hidden as failed automation.
- Local notification scheduling must reconcile on app launch/resume because mobile OS scheduling behavior can vary.
- Image copies must be managed to avoid saving-space backlash.
