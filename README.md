<div align="center">

# ATLAS

**A local-first, open source strength & health tracker for iPhone.**

[![CI](https://github.com/albangerschheimer/ATLAS/actions/workflows/ci.yml/badge.svg)](https://github.com/albangerschheimer/ATLAS/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platform: iOS 17+](https://img.shields.io/badge/Platform-iOS%2017%2B-lightgrey.svg)](https://developer.apple.com/ios/)

**Language / Langue — [English](#english) · [Français](#français)**

<p align="center">
  <img src="docs/screenshots/atlas-today.png" width="30%" alt="ATLAS Today screen">
  <img src="docs/screenshots/atlas-training.png" width="30%" alt="ATLAS Workout screen">
  <img src="docs/screenshots/atlas-progress.png" width="30%" alt="ATLAS Progress screen">
</p>

</div>

---

<a id="english"></a>

## English

I wanted one simple, complete app to run my lifting sessions, follow my progress, and keep my sports data in a single place. **ATLAS** is that app: a native personal training companion for iPhone — local-first, no mandatory account, open source.

### Why ATLAS

- **Local-first.** Your data lives in SwiftData on your device. There is no ATLAS server and no account to create.
- **Optional integrations only.** Apple Health and the barcode scanner are opt-in and triggered by an explicit action, never in the background.
- **One place for everything.** Strength work, cardio from your watch, nutrition and readiness in the same weekly view.

### Features

**Training**

- Searchable, filterable bilingual library of 214 exercises, plus your own custom ones
- Illustrated muscle map — broad regions (arms, back, legs) down to biceps, forearms, lats, traps, adductors, obliques
- User-authored programs, days and prescriptions, with duplication and confirmed deletion
- Free workouts, or workouts started from a program day, with exercise replacement mid-draft
- Weight, reps, RIR, RPE, duration, distance and notes per set
- Swipe-to-delete sets with immediate reindexing and persistence
- Recent performance, deterministic progression suggestions and estimated 1RM
- Rest timer with a quick 15-second extension
- History and one-tap repeat with previous values prefilled

**Health & nutrition**

- Optional read-only Apple Health connection for Mi Fitness-synchronised metrics and workouts
- Weekly dashboard for strength, running, cycling, swimming and basketball, with data provenance
- Deterministic readiness from sleep and resting heart rate, with explicit missing-data states
- Nutrition journal, configurable energy/macro goals and seven-day trends
- Foodvisor nutrition read through Apple Health, without a Foodvisor account inside ATLAS
- Barcode scanning with editable Open Food Facts values, attribution and a local product cache
- Strava/Mi Fitness reconciliation, so one real activity counts once while its sources stay visible

**Data ownership**

- Complete versioned JSON export and completed-set CSV export
- Explicit deletion of all personal ATLAS data, restoring the bundled catalog
- Recoverable persistence feedback instead of silent save failures
- SwiftData V1 → V2 migration preserving existing training data

### Getting started

1. Install a complete Xcode release with the iOS 17+ SDK.
2. Open `ATLAS.xcodeproj`.
3. Select an iPhone simulator and run the `ATLAS` scheme.

On first launch the app seeds an additive bilingual catalog of 214 exercises without replacing custom exercises.

### Running the tests

The pure domain core is a SwiftPM package, so it runs anywhere Swift does:

```sh
swift test
```

`ATLASCore` compiles only `ATLAS/Core`, which keeps analytics and progression tests independent of SwiftUI, SwiftData and the simulator. This is what CI runs on every push.

The full iOS suite (`ATLASTests`, `ATLASUITests`) runs from Xcode with **Product → Test**. The critical UI test uses an isolated in-memory store, so it never touches personal simulator data.

If the machine only has Command Line Tools and SwiftPM is unavailable, the same core checks compile directly:

```sh
swiftc -warnings-as-errors ATLAS/Core/*.swift Tests/CoreTestRunner.swift -o /tmp/atlas-core-tests
/tmp/atlas-core-tests
```

### Privacy

Personal data stays on the device. Apple Health access is optional, read-only and requested only after an explicit action. The camera is requested only when the barcode scanner opens, and Open Food Facts is contacted only for a product lookup. See [PRIVACY.md](PRIVACY.md).

### Design documents

| Document | Contents |
| --- | --- |
| [PRODUCT_SPEC.md](PRODUCT_SPEC.md) | Product scope and behaviour |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, persistence and data flow |
| [PRIVACY.md](PRIVACY.md) | What is stored, where, and what leaves the device |
| [ROADMAP.md](ROADMAP.md) | What is planned next |
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | Pre-release verification steps |

### Contributing

Issues and pull requests are welcome. Please open an issue describing the change before starting significant work, and make sure `swift test` passes.

### AI transparency

This project and its presentation video were built with the help of **GPT-5.6 Sol**. The model acted as an assistant for design, implementation, verification and producing the presentation; product decisions and responsibility for the result remain human. This note does not mean ATLAS ships an AI feature at runtime.

### License

[MIT](LICENSE) © 2026 Alban Gerschheimer.

---

<a id="français"></a>

## Français

Je voulais une app simple et complète pour gérer mes séances de musculation, suivre ma progression et réunir mes données sportives au même endroit. **ATLAS** est cette app : un coach sportif personnel natif pour iPhone, local-first, sans compte obligatoire et open source.

### Pourquoi ATLAS

- **Local-first.** Vos données vivent dans SwiftData, sur votre appareil. Il n'y a pas de serveur ATLAS et aucun compte à créer.
- **Intégrations facultatives.** Apple Santé et le scanner de codes-barres sont opt-in et déclenchés par une action explicite, jamais en arrière-plan.
- **Tout au même endroit.** Musculation, cardio de la montre, nutrition et readiness dans la même vue hebdomadaire.

### Fonctionnalités

**Entraînement**

- Bibliothèque bilingue de 214 exercices, filtrable et cherchable, plus vos exercices personnalisés
- Carte musculaire illustrée — des grandes régions (bras, dos, jambes) jusqu'aux biceps, avant-bras, dorsaux, trapèzes, adducteurs et obliques
- Programmes, journées et prescriptions créés par l'utilisateur, avec duplication et suppression confirmée
- Séances libres ou issues d'une journée de programme, avec remplacement d'exercice en cours de brouillon
- Poids, répétitions, RIR, RPE, durée, distance et notes par série
- Suppression de série par swipe, avec réindexation et persistance immédiates
- Performances récentes, suggestion de progression déterministe et 1RM estimé
- Minuteur de repos avec extension rapide de 15 secondes
- Historique et répétition en un geste, valeurs précédentes pré-remplies

**Santé & nutrition**

- Connexion Apple Santé facultative et en lecture seule, pour les métriques et séances synchronisées par Mi Fitness
- Tableau de bord hebdomadaire musculation, course, vélo, natation et basket, avec provenance des données
- Readiness déterministe à partir du sommeil et de la fréquence cardiaque au repos, avec états explicites de données manquantes
- Journal nutritionnel, objectifs énergie/macros configurables et tendances sur sept jours
- Lecture de la nutrition Foodvisor via Apple Santé, sans compte Foodvisor dans ATLAS
- Scan de codes-barres avec valeurs Open Food Facts éditables, attribution et cache produit local
- Réconciliation Strava/Mi Fitness : une activité réelle est comptée une fois, ses sources restent visibles

**Maîtrise de vos données**

- Export JSON complet et versionné, export CSV des séries terminées
- Suppression explicite de toutes les données personnelles ATLAS, avec restauration du catalogue fourni
- Retour d'erreur récupérable sur la persistance, au lieu d'échecs silencieux
- Migration SwiftData V1 → V2 préservant les données d'entraînement existantes

### Démarrer

1. Installez une version complète de Xcode avec le SDK iOS 17+.
2. Ouvrez `ATLAS.xcodeproj`.
3. Sélectionnez un simulateur iPhone et lancez le schéma `ATLAS`.

Au premier lancement, l'app installe un catalogue bilingue additif de 214 exercices sans écraser les exercices personnalisés.

### Lancer les tests

Le cœur métier pur est un package SwiftPM, il tourne donc partout où Swift tourne :

```sh
swift test
```

`ATLASCore` ne compile que `ATLAS/Core`, ce qui garde les tests d'analytics et de progression indépendants de SwiftUI, SwiftData et du simulateur. C'est ce que la CI exécute à chaque push.

La suite iOS complète (`ATLASTests`, `ATLASUITests`) se lance depuis Xcode avec **Product → Test**. Le test UI critique utilise un store en mémoire isolé : il ne touche jamais aux données personnelles du simulateur.

Si la machine n'a que les Command Line Tools et pas SwiftPM, les mêmes vérifications se compilent directement :

```sh
swiftc -warnings-as-errors ATLAS/Core/*.swift Tests/CoreTestRunner.swift -o /tmp/atlas-core-tests
/tmp/atlas-core-tests
```

### Vie privée

Les données personnelles restent sur l'appareil. L'accès à Apple Santé est facultatif, en lecture seule, et demandé seulement après une action explicite. La caméra n'est demandée qu'à l'ouverture du scanner, et Open Food Facts n'est contacté que pour rechercher un produit. Voir [PRIVACY.md](PRIVACY.md).

### Documents de conception

| Document | Contenu |
| --- | --- |
| [PRODUCT_SPEC.md](PRODUCT_SPEC.md) | Périmètre produit et comportements |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Modules, persistance et flux de données |
| [PRIVACY.md](PRIVACY.md) | Ce qui est stocké, où, et ce qui quitte l'appareil |
| [ROADMAP.md](ROADMAP.md) | La suite prévue |
| [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | Vérifications avant publication |

### Contribuer

Les issues et pull requests sont les bienvenues. Ouvrez une issue décrivant le changement avant d'attaquer un gros morceau, et vérifiez que `swift test` passe.

### Transparence sur l'IA

Ce projet et sa vidéo de présentation ont été réalisés avec l'aide de **GPT-5.6 Sol**. L'IA a servi d'assistant pour la conception, l'implémentation, la vérification et la production de la présentation ; les choix de produit et la responsabilité du résultat restent humains. Cette mention ne signifie pas qu'ATLAS intègre une fonctionnalité d'IA à l'exécution.

### Licence

[MIT](LICENSE) © 2026 Alban Gerschheimer.
