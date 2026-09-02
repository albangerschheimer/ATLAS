# ATLAS — Release Checklist

This checklist is the Phase 1 release gate. Automated checks protect the repository continuously; manual checks are required before installing a build as a dependable personal tracker or submitting it publicly.

## Automated gates

- [x] App, unit-test and UI-test targets compile with Swift 6 strict concurrency.
- [x] Pure domain tests cover volume, records, estimated 1RM and progression.
- [x] SwiftData tests cover seed idempotence, cascade deletion, copying and target snapshots.
- [x] A V1 disk store reopens with workout relationships, UUIDs, notes and optional metrics intact.
- [x] JSON export is versioned and preserves nested records.
- [x] CSV export filters drafts/incomplete sets and escapes commas, quotes and line breaks.
- [x] A generated disk store with 1,000 workouts and 24,000 sets stays within fetch/save budgets.
- [x] UI automation covers custom exercise → program/day → workout → completed history.
- [x] The bundled 214-exercise catalog is additive/idempotent and preserves custom exercises during upgrades.
- [x] Every visible anatomical muscle subcategory contains at least one bundled exercise.
- [x] UI and persistence tests cover full right-swipe set deletion and contiguous set reindexing.
- [x] The critical workout controls have accessibility labels and stable UI-test identifiers.
- [x] The dashboard launches under Dark Mode and the largest accessibility Dynamic Type category.
- [x] Health dashboard tests cover pre-authorization, successful loading, unavailable HealthKit and deterministic readiness.
- [x] Complete data deletion is tested twice in succession and restores only the bundled catalog.
- [x] SwiftData V1→V2 migration preserves existing workouts and accepts nutrition entries.
- [x] Nutrition totals, missing-macro availability, Open Food Facts decoding/cache and export/reset are tested.
- [x] Equivalent Strava/Mi Fitness activities are reconciled once while preserving source provenance.
- [x] UI automation covers manual nutrition creation and swipe deletion.

## Manual device gate

- [ ] Run on a physical iPhone with the oldest supported iOS release.
- [ ] Create, interrupt, relaunch and resume a draft in airplane mode.
- [ ] Complete a program workout and verify history after terminating and reopening ATLAS.
- [ ] Exercise the complete flow at every Accessibility Dynamic Type size.
- [ ] Navigate the workout flow with VoiceOver and verify field names, order and actions.
- [ ] Check contrast in Light, Dark and Increased Contrast modes.
- [ ] Export JSON and CSV to Files, inspect both, then import the CSV into Numbers or Excel.
- [ ] Fill enough notes to verify multiline content and keyboard dismissal during a workout.
- [ ] Confirm deletion dialogs for programs and workout drafts.
- [ ] Verify short-swipe reveal and full-swipe set deletion with one hand during a real workout.
- [ ] Verify acceptable battery use and set-entry latency during a normal session.

## Data safety gate

- [x] Store-open failure shows a recoverable screen and never auto-deletes local data.
- [x] Save failures remain visible and offer retry.
- [x] Schema V1 is frozen; V2 adds nutrition through a tested migration stage.
- [x] Complete local export exists before any cloud sync.
- [x] Add and test an explicit “Delete all ATLAS data” control before public distribution.
- [ ] Keep a real exported fixture from the last pre-release build and verify it can be decoded by the current exporter schema tests.

## Privacy and distribution gate

- [x] HealthKit access is read-only, contextual and optional; Camera access is contextual to barcode scanning; Calendar, Photos and notifications are not requested.
- [x] The HealthKit capability and `NSHealthShareUsageDescription` match the visible dashboard feature.
- [x] Phase 1 has no account, analytics SDK, backend or third-party runtime dependency.
- [x] Export is initiated explicitly and uses the system file interface.
- [ ] Verify the built app produces no unexpected network traffic.
- [ ] Complete the App Store privacy questionnaire from the shipping binary’s behavior.
- [ ] Add final user-facing privacy policy and support contact before public distribution.
- [ ] Archive a signed Release build and run Organizer validation.
