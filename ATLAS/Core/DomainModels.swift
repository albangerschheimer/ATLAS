import Foundation

enum MuscleGroup: String, CaseIterable, Codable, Sendable {
    case chest
    case back
    case lats
    case upperBack
    case traps
    case lowerBack
    case shoulders
    case biceps
    case triceps
    case forearms
    case quadriceps
    case hamstrings
    case glutes
    case adductors
    case abductors
    case calves
    case core
    case obliques
    case fullBody

    var frenchName: String {
        switch self {
        case .chest: "Pectoraux"
        case .back: "Dos complet"
        case .lats: "Grands dorsaux"
        case .upperBack: "Haut du dos"
        case .traps: "Trapèzes"
        case .lowerBack: "Lombaires"
        case .shoulders: "Épaules"
        case .biceps: "Biceps"
        case .triceps: "Triceps"
        case .forearms: "Avant-bras"
        case .quadriceps: "Quadriceps"
        case .hamstrings: "Ischio-jambiers"
        case .glutes: "Fessiers"
        case .adductors: "Adducteurs"
        case .abductors: "Abducteurs"
        case .calves: "Mollets"
        case .core: "Abdominaux"
        case .obliques: "Obliques"
        case .fullBody: "Corps entier"
        }
    }
}

enum MuscleRegion: String, CaseIterable, Identifiable, Sendable {
    case chest
    case back
    case shoulders
    case arms
    case legs
    case glutes
    case core
    case fullBody

    var id: String { rawValue }

    var frenchName: String {
        switch self {
        case .chest: "Pectoraux"
        case .back: "Dos"
        case .shoulders: "Épaules"
        case .arms: "Bras"
        case .legs: "Jambes"
        case .glutes: "Fessiers"
        case .core: "Abdominaux"
        case .fullBody: "Corps entier"
        }
    }

    var subtitle: String {
        switch self {
        case .chest: "Grand et petit pectoral"
        case .back: "Dorsaux, trapèzes et lombaires"
        case .shoulders: "Deltoïdes"
        case .arms: "Biceps, triceps et avant-bras"
        case .legs: "Quadriceps, ischios, adducteurs et mollets"
        case .glutes: "Fessiers et abducteurs"
        case .core: "Abdominaux et obliques"
        case .fullBody: "Mouvements qui sollicitent tout le corps"
        }
    }

    /// Groups used to include exercises in the broad region. Legacy broad values
    /// remain here so existing custom exercises continue to appear.
    var filterMuscles: [MuscleGroup] {
        switch self {
        case .chest: [.chest]
        case .back: [.back, .lats, .upperBack, .traps, .lowerBack]
        case .shoulders: [.shoulders]
        case .arms: [.biceps, .triceps, .forearms]
        case .legs: [.quadriceps, .hamstrings, .adductors, .calves]
        case .glutes: [.glutes, .abductors]
        case .core: [.core, .obliques]
        case .fullBody: [.fullBody]
        }
    }

    /// User-facing subcategories. `.back` is intentionally hidden because it is
    /// retained only as a compatibility value for older/custom records.
    var subcategories: [MuscleGroup] {
        switch self {
        case .chest: [.chest]
        case .back: [.lats, .upperBack, .traps, .lowerBack]
        case .shoulders: [.shoulders]
        case .arms: [.biceps, .triceps, .forearms]
        case .legs: [.quadriceps, .hamstrings, .adductors, .calves]
        case .glutes: [.glutes, .abductors]
        case .core: [.core, .obliques]
        case .fullBody: [.fullBody]
        }
    }
}

enum EquipmentKind: String, CaseIterable, Codable, Sendable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyweight
    case smithMachine
    case bands
    case other

    var frenchName: String {
        switch self {
        case .barbell: "Barre"
        case .dumbbell: "Haltères"
        case .cable: "Poulie"
        case .machine: "Machine"
        case .bodyweight: "Poids du corps"
        case .smithMachine: "Smith machine"
        case .bands: "Élastiques"
        case .other: "Autre"
        }
    }
}

enum ExerciseCategory: String, CaseIterable, Codable, Sendable {
    case strength
    case hypertrophy
    case power
    case plyometric
    case mobility
    case cardio

    var frenchName: String {
        switch self {
        case .strength: "Force"
        case .hypertrophy: "Hypertrophie"
        case .power: "Explosivité"
        case .plyometric: "Pliométrie"
        case .mobility: "Mobilité"
        case .cardio: "Cardio"
        }
    }
}

enum TrainingSetKind: String, CaseIterable, Codable, Sendable {
    case warmup
    case working

    var frenchName: String {
        switch self {
        case .warmup: "Échauffement"
        case .working: "Travail"
        }
    }
}

struct TrainingSetSnapshot: Equatable, Codable, Sendable {
    var loadKilograms: Double?
    var repetitions: Int?
    var rir: Double?
    var kind: TrainingSetKind
    var isCompleted: Bool

    init(
        loadKilograms: Double? = nil,
        repetitions: Int? = nil,
        rir: Double? = nil,
        kind: TrainingSetKind = .working,
        isCompleted: Bool = true
    ) {
        self.loadKilograms = loadKilograms
        self.repetitions = repetitions
        self.rir = rir
        self.kind = kind
        self.isCompleted = isCompleted
    }
}

struct ExercisePerformance: Equatable, Codable, Sendable {
    var exerciseID: UUID
    var exerciseName: String
    var date: Date
    var sets: [TrainingSetSnapshot]

    init(
        exerciseID: UUID,
        exerciseName: String,
        date: Date,
        sets: [TrainingSetSnapshot]
    ) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.date = date
        self.sets = sets
    }
}

struct ExerciseRecords: Equatable, Sendable {
    var heaviestLoadKilograms: Double?
    var bestRepetitions: Int?
    var estimatedOneRepMaxKilograms: Double?
    var totalVolumeKilograms: Double

    static let empty = ExerciseRecords(
        heaviestLoadKilograms: nil,
        bestRepetitions: nil,
        estimatedOneRepMaxKilograms: nil,
        totalVolumeKilograms: 0
    )
}
