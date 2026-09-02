# ATLAS — Delivery Roadmap

Each phase is gated: the next phase starts only after its exit criteria are met. Priorities may change, but a later module must not weaken the offline strength tracker.

## Phase 1 — Strength tracker foundation

### 1A. Architecture and domain

- establish SwiftUI/SwiftData project and folder structure;
- define exercise, program, workout and set schemas;
- add deterministic volume, estimated 1RM and PR calculations;
- seed an additive bilingual catalog of 214 exercises;
- browse the catalog through an illustrated body map and precise muscle subcategories;
- document product, architecture and privacy choices.

Exit criteria: core tests pass; the project has no third-party runtime dependency; the schema can represent the complete V1 flow.

### 1B. Exercise library and programs

- searchable/filterable exercise list;
- custom exercise creation and favorites;
- program/day creation;
- exercise prescriptions with sets, rep range, target RIR and rest;
- edit and delete confirmations.

Exit criteria: a user can create and relaunch into a persisted custom program without network access.

### 1C. Workout logging

- free workout and program-day workout creation;
- rapid set logging, warm-up/work classification and notes;
- recent history per exercise;
- rest timer with visible controls;
- workout completion and history detail;
- right-swipe deletion of individual sets with immediate persistent reindexing;
- PR badges based on completed sets.

Exit criteria: the end-to-end exercise → program → workout → history flow works after app relaunch; unit and critical UI tests pass.

### 1D. Hardening

- accessibility and Dynamic Type pass;
- empty/error states and destructive confirmations;
- in-memory SwiftData integration tests;
- JSON/CSV export design and schema migration plan;
- performance check with at least 1,000 workouts of generated test data.

Exit criteria: no known data-loss issue, acceptable set-entry latency, release checklist documented.

## Phase 2 — Apple integrations and dashboard

- HealthKit capability and contextual authorization;
- `HealthDataProvider` with HealthKit and mock adapters;
- import run, bike, swim and other supported workouts with provenance;
- Xiaomi/Mi Fitness validation through Apple Health only;
- internal weekly sports calendar showing canonical HealthKit and ATLAS activities;
- EventKit calendar selection and ATLAS export;
- clean Today dashboard and weekly sport counts.

Exit criteria: manual mode remains complete; missing/denied Health data never shows as zero; imports are idempotent; calendar conflicts recalculate after movement.

## Phase 3 — Deterministic coaching foundation

- muscle-zone load model including hard sets and RIR;
- cross-sport load for running, cycling, swimming, basketball, sprint and jumps;
- plyometric contacts/load guardrails;
- sub-20-second daily check-in and body pain map;
- explainable readiness with weight redistribution for missing inputs;
- rules for schedule conflicts and conservative confidence.

Then, and only then:

- private aggregate coach payload;
- explanatory AI suggestions with confidence;
- explicit preview/confirm before applying any change.

Exit criteria: deterministic tests cover fatigue, readiness and conflicts; AI cannot mutate user data directly; safety copy is reviewed.

## Phase 4 — Nutrition

- [x] manual calories/macros and configurable goals;
- [x] HealthKit nutrition import when available, including Foodvisor provenance;
- [x] weekly trends;
- [x] AVFoundation barcode scanning;
- [x] Open Food Facts lookup with cache, attribution and editable quantities;
- later meal-photo estimates, always labeled and editable.

Exit criteria: nutrition remains useful offline after previously loaded data; estimates are never presented as exact.

## Phase 5 — Gyms and equipment

- gym location, brand, machine and exercise mapping schema;
- manual machine creation and personal settings;
- licensed structured imports;
- club-specific catalog without fragile scraping;
- community moderation/export design.

Exit criteria: machine identity and personal settings survive exercise-library changes; provenance/license recorded for every imported catalog.

## Phase 6 — Recognition and advanced planning

- opt-in machine-photo recognition;
- opt-in meal recognition;
- advanced endurance zones/trends/planning;
- optional account and sync only after a concrete multi-device need;
- recovery/export/conflict tooling for synced data.

Exit criteria: privacy review, measurable recognition quality, editable results, documented deletion and provider retention.

## Test backlog by phase

| Area | Phase |
|---|---:|
| Volume, PR, 1RM, progression | 1 |
| SwiftData ordering/cascade/migrations | 1 |
| HealthKit import mapping/idempotency | 2 |
| Calendar move/conflict rules | 2–3 |
| Fatigue, plyometric load, readiness | 3 |
| Nutrition quantity and barcode cache | 4 |
| Machine mapping/import validation | 5 |

## Current milestone

Phase 1A–1D now runs end to end in the iPhone simulator. Persistence failures are recoverable, JSON/CSV exports and complete local-data deletion are available from Profile, SwiftData has an explicit frozen V1 schema and migration plan, and disk-store tests verify reopening without losing relationships. Queries used during set entry are bounded or filtered instead of loading every workout.

The HealthKit layer now reads contextual metrics, Foodvisor nutrition and source-attributed workouts. Equivalent Strava, Mi Fitness and other HealthKit workouts are reconciled into one canonical activity using sport, time, duration and distance while retaining contributing sources. The weekly sports calendar combines these canonical activities with completed local sessions. Health samples remain in HealthKit and are refreshed rather than copied into SwiftData. EventKit export remains the main unfinished Phase 2 integration.

Phase 4 is complete except for the explicitly deferred meal-photo estimator: local nutrition entries and goals, Foodvisor-via-HealthKit totals, missing-data states, seven-day trends, barcode capture, cached Open Food Facts lookup, attribution, editable portions, V2 migration, export/reset support and UI coverage are implemented.

The generated performance fixture covers 1,000 workouts, 6,000 workout exercises and 24,000 sets. Thirty-one unit/integration/performance tests and three UI tests pass in the iPhone simulator. The release checklist records the remaining VoiceOver, export-to-Files and App Store distribution gates.
