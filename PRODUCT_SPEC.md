# ATLAS — Product Specification

## 1. Vision

ATLAS is a personal, native iPhone sports operating system. Its first release is a fast, dependable strength-training tracker; later releases will coordinate strength, hypertrophy, explosiveness, basketball, running, cycling, swimming, recovery and nutrition.

The product optimizes for an athletic and aesthetic physique without treating muscle gain as the only goal. Recommendations must account for the user's other sports and schedule.

## 2. Product principles

1. **The user remains in control.** The coach may explain, warn and propose. It never silently edits a session, program or calendar.
2. **Local first.** Core training remains usable without a network connection.
3. **Structured logic before AI.** Progression, records, training load and readiness are deterministic and testable. A language model explains structured results; it does not invent them.
4. **Missing health data is normal.** Every imported metric carries its source, timestamp and availability. The interface offers an explicit fallback rather than implying that the metric exists.
5. **Fast in the gym.** Recording a working set should take only a few taps and remain comfortable with one hand.
6. **Health is not diagnosis.** Scores and suggestions are estimates, never medical claims.

## 3. Target user and primary jobs

The initial user is an iPhone owner training several times per week who wants to:

- create a personal exercise library and reusable programs;
- start a planned or improvised strength session;
- record weight, repetitions, RIR and notes quickly;
- see recent performance while training;
- review history and personal records;
- later understand how strength work interacts with basketball and endurance.

The wearable path is Xiaomi Smart Band 9 → Mi Fitness → Apple Health → HealthKit → ATLAS. Direct Bluetooth access is explicitly outside the product scope.

## 4. V1 scope

### Included

- five-tab native SwiftUI navigation: Today, Train, Calendar, Progress and Profile;
- additive local library of 214 exercises with French/English names, aliases, detailed muscle subcategories, equipment, category and instructions;
- illustrated anatomical browsing by body region, then by precise muscle;
- custom program creation with training days and prescribed exercises;
- free workouts and workouts started from a program day;
- set logging: load, repetitions, RIR, kind (warm-up/work), completion and notes;
- short-swipe reveal and full right-swipe deletion of individual sets;
- recent exercise history during a workout;
- rest timer;
- completed-workout history;
- deterministic volume and personal-record calculations;
- SwiftData persistence and preview/demo data;
- portable local JSON/CSV export;
- recoverable persistence failures and an explicit SwiftData migration baseline;
- unit, disk-store, performance and critical UI tests;
- optional read-only Apple Health metrics and workouts with source attribution;
- weekly multi-sport dashboard and conservative deterministic readiness;
- weekly sports calendar combining local sessions with reconciled HealthKit activities;
- local nutrition journal, configurable goals and seven-day trends;
- Foodvisor nutrition through read-only Apple Health;
- barcode scanning and cached, editable Open Food Facts product data;
- cross-source activity reconciliation for Strava/Mi Fitness HealthKit records;
- complete local-data deletion with bundled-catalog restoration.

### Intentionally deferred

- EventKit and calendar conflict detection;
- muscular fatigue and advanced cross-sport load modeling;
- AI coach and any cloud backend;
- meal-photo nutrition estimates;
- Fitness Park catalog, machine recognition and meal recognition;
- sync, accounts and social/community features.

The deferred areas may be represented by honest placeholders only; they must not create a false impression that data has been imported or analyzed.

## 5. Core user flows

### Build an exercise library

The user opens Train → Exercises, searches the bundled catalog, adds a custom exercise if needed, and can favorite frequently used exercises. Duplicate names are discouraged by normalized-name search but custom aliases remain possible.

### Create a program

The user opens Train → Programs, creates a program, adds named days, then adds exercises with sets, rep range, target RIR and rest time. No generated program is imposed.

### Run a workout

The user starts a free workout or a program day, adds/reorders exercises, sees the most recent completed sets for each exercise, records sets and marks them complete. Completing a set starts the rest timer. Finishing asks for confirmation and saves a dated session.

### Review progress

The user opens History or Progress to see completed sessions, total volume and estimated 1RM records. V1 results are descriptive, not coaching advice.

## 6. Functional requirements

### Exercise

An exercise stores a stable identifier, French and English names, aliases, primary and secondary muscles, equipment, category, instructions, favorite state and optional custom photo reference. Machine brand/model belong to the later equipment catalog rather than the base exercise identity.

### Program

A program stores an ordered list of days. A day contains ordered prescriptions: exercise reference, set count, minimum/maximum repetitions, target RIR and rest seconds.

### Workout

A workout stores start/end dates, status, optional program/day origin, ordered exercises and ordered sets. A set supports load in kilograms, repetitions, RIR, optional RPE/duration/distance, notes and warm-up/working classification.

### Records and volume

- Volume is the sum of `load × repetitions` for completed loaded sets.
- Weight PR is the largest completed load for an exercise.
- Rep PR is the largest completed repetition count at a given load.
- Estimated 1RM uses the Epley formula for sets with 1–12 repetitions; the interface labels it as an estimate.
- Bodyweight/time/distance movements are retained but excluded from loaded-volume and 1RM calculations when load is absent.

## 7. Non-functional requirements

- iOS 17 or later, iPhone portrait-first, Swift 6 compatible.
- No third-party runtime dependency in V1.
- Core records and training actions work in airplane mode.
- Accessibility labels, Dynamic Type and adequate contrast for primary actions.
- Destructive actions require confirmation and should be recoverable where practical.
- Calculations are pure Swift and testable without SwiftData or HealthKit.
- Health and calendar access will be opt-in and purpose-scoped when implemented.

## 8. Success criteria for the first milestone

The milestone is successful when a fresh install can create an exercise, create a program day, launch or create a workout, record several sets, finish it, relaunch the app and find the session in history. Domain tests pass, and the iOS target builds in a complete Xcode installation.

## 9. Later product metrics

For a personal application, local usage signals are sufficient by default:

- completed workouts per week;
- median taps/time to record a set;
- percentage of started sessions completed;
- programs reused across weeks;
- crash-free sessions.

No analytics SDK is needed for V1.
