# ATLAS — Privacy and Health Data Policy

## 1. Default posture

ATLAS handles training and health information as sensitive personal data. The default is local processing and local storage. A user can use the V1 strength tracker without an account, backend or network connection.

This document is a product/engineering policy, not a substitute for the final App Store privacy policy or legal review.

## 2. Data inventory

### V1 local data

- exercise library and favorites;
- programs and prescriptions;
- workout dates, sets, loads, repetitions, RIR/RPE and notes;
- preferences and optional bodyweight entered by the user.

These records live in the app's SwiftData store on device and receive normal iOS data protection. They are not uploaded by default.

### Current opt-in Apple Health data

- Apple Health samples and workouts;
- sleep, heart rate, steps, walking/running distance and active energy when available;
- compatible scale measurements: weight, body-fat percentage, lean body mass and BMI;
- dietary energy, protein, carbohydrates and fat written by Foodvisor or another authorized source.

Dashboard values are read into an ephemeral snapshot. When the user opens Progress → Measurements and authorizes access, ATLAS copies only compatible scale values, their date and a human-readable source into its local SwiftData history so graphs work offline. No HealthKit sample is sent to a server. Repeated imports are deduplicated by metric, timestamp and value.

### Current local/network nutrition data

- local manual or scanned nutrition entries and goals;
- a scanned barcode sent to Open Food Facts to retrieve contributor-supplied product data;
- locally cached Open Food Facts product metadata;

### Later opt-in data

- selected Apple Calendar events;
- photos explicitly chosen for machine or meal analysis;
- minimized aggregates sent to an AI coach.

## 3. HealthKit rules

- HealthKit is the abstraction used for Xiaomi/Mi Fitness, Foodvisor and Strava data; ATLAS does not require direct accounts with these providers.
- Access is requested only after the corresponding feature exists and the user asks to connect it.
- Read and write purposes are explained separately.
- ATLAS never uses HealthKit data for advertising, data brokerage or cross-app profiling.
- Raw HealthKit samples are not copied to a server by default.
- Each displayed metric exposes its source and timestamp where meaningful.
- Equivalent source workouts are reconciled into one canonical activity without deleting HealthKit records; contributing sources remain visible.
- Apple does not reveal per-type Health read denial to apps. ATLAS therefore distinguishes “not requested”, “unavailable”, “no readable data” and “read failed”, but never claims to know that a specific read permission was denied.

## 4. Private AI analysis

“Private AI analysis” sends only the minimum aggregated context needed for a requested answer. A typical payload may contain:

```json
{
  "sleep_status": "below_7_day_baseline",
  "quadriceps_load": "high",
  "next_events": ["basketball_tomorrow"],
  "recent_performance_trend": "stable"
}
```

It should omit identity, raw HealthKit samples, free-form notes, exact event titles and full set history unless the user explicitly chooses a detailed analysis and sees what will be sent.

Before transmission, ATLAS must show:

- what categories will leave the device;
- the reason they are needed;
- which processor/model provider receives them;
- whether they are retained and for how long;
- a cancel option.

AI output is a suggestion. It cannot write to workouts, programs, goals or calendar without an explicit confirmation showing the proposed change.

## 5. Retention, deletion and export

- Local training data is retained until the user deletes an item, uses the in-app complete deletion control or deletes the app.
- The complete deletion control removes workouts, programs, custom exercises, notes and local nutrition entries, then restores a fresh bundled exercise catalog.
- Aggregate deletion must include owned days, prescriptions, workout exercises and sets.
- Export uses a documented, versioned JSON format including nutrition entries and CSV for completed training history. It is created locally only after an explicit user action.
- The current export is portable but not yet an in-app restore mechanism; the interface states this clearly.
- Later server data must have an independent account deletion path and a defined retention window.
- Local backups/iCloud device backup behavior must be disclosed in the final privacy notice.

## 6. Security controls

- Use App Sandbox and iOS data protection; no custom cryptography.
- Keep credentials in Keychain, never SwiftData or source code.
- Use TLS for all later network traffic.
- Redact health values, notes, tokens and identifiers from logs.
- Do not include sensitive payloads in crash-report breadcrumbs.
- Protect export/share flows with an explicit system file/share sheet initiated by the user.
- Prefer on-device transformations and aggregation.

## 7. Permissions UX

No sensitive permission is requested at first launch. Permission prompts follow a contextual explanation and a user action. Denial does not block unrelated modules:

- Health denied → manual training remains fully functional;
- Calendar denied → internal ATLAS calendar remains available;
- Camera denied → manual barcode/product entry remains available;
- Notifications denied → visible in-app timer remains available.

## 8. Medical and safety language

Readiness, fatigue and load are training estimates, not diagnoses. ATLAS must not claim to detect injury or disease. For reported pain or concerning symptoms, the interface recommends stopping or adapting activity and consulting a qualified professional when appropriate.

## 9. Third parties and licensing

Before adding a provider, document:

- data sent and purpose;
- processor location and subprocessors;
- retention/training policy;
- user controls and deletion route;
- SDK/network permissions;
- license and attribution obligations.

Third-party exercise-video providers are disabled in this release. No exercise name, workout history or HealthKit value is sent to wger or ExerciseDB.

Open Food Facts receives the scanned barcode, locale, app User-Agent and normal network metadata. ATLAS does not send workout, HealthKit or nutrition-journal values with this request. Product data is contributor-supplied, displayed with attribution and subject to the Open Database License (ODbL).

## 10. Release checklist

- App Privacy questionnaire matches actual collection and transmission.
- Usage descriptions name the visible feature and do not overclaim.
- HealthKit entitlement includes only required access.
- Network inspection confirms no unexpected data leaves the device.
- Delete/export controls pass tests.
- Logs and crash reports contain no sensitive sample values.
- AI consent screen matches the production provider contract.
