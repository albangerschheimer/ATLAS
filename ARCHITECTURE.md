# ATLAS — Architecture

## 1. Architectural direction

ATLAS uses a local-first, feature-oriented SwiftUI architecture with three broad layers:

```text
SwiftUI Features
      ↓ user intents / view state
Application modules
      ↓ domain models and results
Domain engines (pure Swift)
      ↓ persistence seam
SwiftData adapter
```

Apple frameworks and future network integrations sit behind explicit seams only when there are at least two useful adapters (for example, HealthKit plus a mock health-data adapter). This avoids creating protocol forests for behavior that does not vary.

The important deep modules are:

- **Training repository** — a small interface that hides SwiftData queries, relationship management and save behavior;
- **Workout builder** — turns a program prescription into a mutable workout without exposing mapping details;
- **Training analytics** — calculates volume and records from completed domain sets;
- **Progression engine** — later evaluates a completed prescription and returns a recommendation plus reasons;
- **Health data provider** — implemented seam for read-only Apple Health and deterministic mock data;
- **Activity canonicalizer** — reconciles source-attributed HealthKit workouts without double-counting a real-world effort;
- **Nutrition module** — combines ephemeral Apple Health samples with local SwiftData entries and cached product metadata;
- **Readiness engine** — pure module that returns a conservative score and explanations when required inputs exist.

The interface of each module is also its test surface. UI tests should verify navigation and critical flows; domain tests exercise calculation interfaces directly.

## 2. Project structure

```text
ATLAS.xcodeproj
ATLAS/
  App/
    ATLASApp.swift
    AppContainer.swift
    RootTabView.swift
  Core/
    DomainModels.swift
    TrainingAnalytics.swift
    ProgressionEngine.swift
  Data/
    ModelContainerFactory.swift
    Models/
      ExerciseRecord.swift
      ProgramRecord.swift
      WorkoutRecord.swift
      NutritionModels.swift
    SeedData.swift
  Features/
    Today/
    Train/
      ExerciseLibrary/
      Programs/
      Workout/
      History/
    Calendar/
    Progress/
    Profile/
  DesignSystem/
    AtlasTheme.swift
    MetricCard.swift
Tests/
  AtlasCoreTests/
```

V1 is a single app target to keep builds and refactors simple. `ATLAS/Core` is also compiled by the root Swift package so deterministic logic can be tested from the command line without requiring an iOS simulator.

## 3. Data flow and ownership

SwiftData records are the source of truth for local persisted data. Feature views use `@Query` for read-focused screens and the environment `ModelContext` for focused mutations. Mapping into pure domain values happens before calling analytics engines.

This is deliberate for V1: a broad repository abstraction around every CRUD call would be shallow. A dedicated repository seam should be introduced when batch imports, cloud sync or a second persistence adapter makes it real.

Rules:

- SwiftUI views do not calculate records or progression rules.
- Pure engines do not import SwiftUI, SwiftData, HealthKit or EventKit.
- Relationships are owned and mutated by one aggregate root: program owns days/prescriptions; workout owns workout exercises/sets.
- Deleting an aggregate cascades to owned children.
- UI state such as the running timer is transient; logged sets and workout dates are persisted.

## 4. Principal domain model

```text
ExerciseRecord
  ├─ stable ID
  ├─ localized names / aliases
  ├─ primary + secondary muscles
  ├─ equipment / category
  └─ instructions / favorite / custom

ProgramRecord
  └─ ProgramDayRecord (ordered)
       └─ ProgramExerciseRecord (ordered)
            └─ references ExerciseRecord

WorkoutRecord
  └─ WorkoutExerciseRecord (ordered)
       ├─ references ExerciseRecord
       └─ WorkoutSetRecord (ordered)
```

References from historical workout exercises preserve an exercise-name snapshot. History therefore remains understandable if a library exercise is later renamed or deleted.

## 5. SwiftData schema decisions

- `ATLASchemaV1` is frozen; `ATLASchemaV2` adds local nutrition entries through a tested lightweight migration.
- `CurrentSchema` is the only alias moved when a future schema version becomes current.
- UUIDs are created by the app and marked unique on aggregate roots.
- Enums are persisted as raw strings for migration clarity.
- Muscle and alias collections are encoded as scalar string arrays in V1.
- Child order is explicit (`sortIndex`); array relationship ordering is not assumed.
- Optional metrics remain optional. Zero is a real value, not the absence sentinel.
- Workouts use an explicit draft/completed state and optional end date.
- Store opening is recoverable: failure displays a data-unavailable screen and never deletes the store automatically.

### Portable export

`AtlasDataExporter` maps SwiftData records into acyclic value DTOs. Models themselves are not `Codable`, which avoids encoding inverse relationships and keeps the portable format independent from storage internals.

- JSON format version 2 contains exercises, programs, drafts, completed workouts, nutrition entries, snapshots, notes and optional metrics.
- CSV contains one row per completed set using invariant numbers, ISO-8601 dates and RFC 4180 escaping.
- Export is always initiated by the user through the system file exporter; no file is uploaded by ATLAS.

## 6. External seams

### Health data provider (implemented Phase 2 slice)

```swift
protocol HealthDataProvider {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws
    func loadSnapshot(week: DateInterval, now: Date) async -> HealthSnapshot
}
```

Adapters:

- `HealthKitDataProvider` for production;
- `MockHealthDataProvider` for previews and tests.

Every displayed metric contains source, timestamps, optional value/unit and availability. Xiaomi, Foodvisor and Strava are not direct account integrations; ATLAS reads what those apps write to Apple Health. Samples are read into an ephemeral dashboard snapshot and are not duplicated into SwiftData. `HealthActivityCanonicalizer` groups likely duplicate activities by sport, start time, duration and compatible distance, retains all contributing sources and prefers the richer Strava record for running/cycling display.

### Nutrition and food lookup (implemented Phase 4)

Local manual/scanned entries use SwiftData V2. Apple Health nutrition stays ephemeral and is added to local entries per day. Availability is tracked per nutrient so a missing macro is never rendered as zero. Barcode scanning uses AVFoundation; the barcode alone is sent to the Open Food Facts v3.6 API. Product metadata is cached locally, quantities remain editable, and the UI attributes the contributor database.

### Calendar provider (Phase 2)

An EventKit adapter will read only calendars selected by the user and export to a dedicated ATLAS calendar by default. Internal planned sessions remain in SwiftData so calendar denial never breaks training.

### Coach gateway (Phase 3)

The coach receives a versioned, minimized aggregate DTO. It returns suggestions, explanations and confidence; applying a suggestion is a separate, explicit user action. The deterministic engines remain authoritative for scores and conflicts.

## 7. Apple frameworks

| Need | Framework | Phase | Notes |
|---|---|---:|---|
| Interface | SwiftUI | 1 | Native navigation and forms |
| Local persistence | SwiftData | 1 | Offline source of truth |
| Tests | XCTest / Swift Testing | 1 | Pure domain plus persistence integration |
| Health import | HealthKit | 2 | Read-only initially; background delivery only if justified |
| Calendar | EventKit / EventKitUI | 2 | User-selected calendars and ATLAS export |
| Notifications | UserNotifications | 2 | Optional rest/event reminders |
| Barcode capture | AVFoundation | 4 | Permission only at point of use |
| Food lookup | URLSession | 4 | Open Food Facts with caching and attribution |
| Photos/camera | PhotosUI / AVFoundation | 5–6 | Machine/meal recognition, explicitly deferred |
| Charts | Swift Charts | 1/3 | Progress visuals, no external chart dependency |

## 8. Permissions and capabilities

The current app includes the HealthKit capability, `NSHealthShareUsageDescription` and `NSCameraUsageDescription`. It requests only read types used by visible dashboard/nutrition features, after the user taps the connection action; no HealthKit write access is requested. Camera permission is requested only from the scanner. Missing or denied data leaves manual tracking functional and is never represented as zero.

EventKit later requires `NSCalendarsFullAccessUsageDescription` (or the least-access key supported by the deployment target) and a clear calendar-selection screen. Camera and Photos permissions remain absent.

Selected Photos access through `PhotosPicker` should be preferred to broad library access if meal or machine recognition is added later.

## 9. Error handling and observability

- Persistence failures are shown with a recoverable message; drafts stay onscreen until a save succeeds.
- Retrying a save also replays its success transition, preventing duplicate creation after a transient failure.
- Import jobs are idempotent using external sample identifiers plus source.
- Missing permissions and missing data are distinct states.
- Logs use `Logger` with private fields for health-sensitive values.
- No health payload, food log or workout note is written to analytics/crash metadata by default.

## 10. Testing strategy

- Pure tests: volume, PR, estimated 1RM, progression, fatigue, readiness and conflict rules.
- SwiftData integration tests: in-memory container, cascade deletion, ordering, history snapshots and disk-store reopening.
- Export tests: version, nested-field fidelity, completed-set filtering and CSV escaping.
- Performance test: 1,000 workouts, 6,000 workout exercises and 24,000 sets in a disk store.
- Health tests: authorization boundary, unavailable/missing states, mock snapshot loading and deterministic readiness.
- UI tests: create exercise → program → workout → completed history, manual nutrition add/delete, plus Dark Mode/accessibility-size launch.

Tests assert observable results at module interfaces and avoid private implementation details.

## 11. Technical risks

| Risk | Impact | Mitigation |
|---|---|---|
| Mi Fitness writes incomplete/inconsistent Health data | Missing readiness inputs | Show provenance/availability; manual fallback; never assume sync |
| SwiftData migrations and relationship ordering | Data loss or reordered sessions | Explicit order fields, migration plan, export, integration tests |
| One large model context causes UI stalls | Poor workout entry UX | Small fetches, predicates, background import contexts later |
| Health permissions are all-or-nothing in UX | Low trust/denial | Explain each use and request only implemented types |
| AI suggestion changes user data | Loss of control | Two-step propose/apply flow with diff and reason |
| Cross-sport load models overstate certainty | Unsafe advice | Deterministic explainable inputs, confidence, conservative thresholds |
| Scope explosion | Core tracker never becomes solid | Phase gates in ROADMAP.md and no speculative backend |

## 12. Dependencies

V1 has no external dependency. Native frameworks cover persistence, navigation, charts and testing. A dependency may be proposed later only with a documented capability gap, license, privacy effect, binary cost and removal strategy.
