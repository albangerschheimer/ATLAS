import Foundation
import SwiftData

@MainActor
enum SeedData {
    static var bundledExerciseCount: Int { definitions.count }

    static func insertIfNeeded(into context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<ExerciseRecord>())
        var knownNames = Set(existing.flatMap { exercise in
            [normalized(exercise.nameFrench), normalized(exercise.nameEnglish)]
        }.filter { !$0.isEmpty })

        for definition in definitions {
            let names = Set([normalized(definition.nameFrench), normalized(definition.nameEnglish)].filter { !$0.isEmpty })
            if let bundledRecord = existing.first(where: { exercise in
                guard !exercise.isCustom else { return false }
                let recordNames = Set([normalized(exercise.nameFrench), normalized(exercise.nameEnglish)].filter { !$0.isEmpty })
                return !recordNames.isDisjoint(with: names)
            }) {
                // Muscle classification is catalog-owned. Refreshing only these
                // fields upgrades existing installs without touching favorites,
                // notes, names or user-created exercises.
                bundledRecord.primaryMuscles = definition.primary.map(\.rawValue)
                bundledRecord.secondaryMuscles = definition.secondary.map(\.rawValue)
                knownNames.formUnion(names)
                continue
            }
            guard knownNames.isDisjoint(with: names) else { continue }
            context.insert(definition.makeRecord())
            knownNames.formUnion(names)
        }
        try context.save()
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private struct Definition {
        let nameFrench: String
        let nameEnglish: String
        let aliases: [String]
        let primary: [MuscleGroup]
        let secondary: [MuscleGroup]
        let equipment: EquipmentKind
        let category: ExerciseCategory

        func makeRecord() -> ExerciseRecord {
            ExerciseRecord(
                nameFrench: nameFrench,
                nameEnglish: nameEnglish,
                aliases: aliases,
                primaryMuscles: primary,
                secondaryMuscles: secondary,
                equipment: equipment,
                category: category
            )
        }
    }

    private static func d(
        _ french: String,
        _ english: String,
        _ primary: [MuscleGroup],
        secondary: [MuscleGroup] = [],
        equipment: EquipmentKind,
        category: ExerciseCategory = .hypertrophy,
        aliases: [String] = []
    ) -> Definition {
        Definition(nameFrench: french, nameEnglish: english, aliases: aliases, primary: primary, secondary: secondary, equipment: equipment, category: category)
    }

    private static let definitions: [Definition] = [
        // Pectoraux
        d("Développé couché", "Barbell Bench Press", [.chest], secondary: [.triceps, .shoulders], equipment: .barbell, category: .strength, aliases: ["Bench press"]),
        d("Développé couché haltères", "Dumbbell Bench Press", [.chest], secondary: [.triceps, .shoulders], equipment: .dumbbell),
        d("Développé incliné barre", "Incline Barbell Bench Press", [.chest], secondary: [.shoulders, .triceps], equipment: .barbell, category: .strength),
        d("Développé incliné haltères", "Incline Dumbbell Press", [.chest], secondary: [.shoulders, .triceps], equipment: .dumbbell),
        d("Développé décliné barre", "Decline Barbell Bench Press", [.chest], secondary: [.triceps], equipment: .barbell),
        d("Développé décliné haltères", "Decline Dumbbell Press", [.chest], secondary: [.triceps], equipment: .dumbbell),
        d("Développé couché prise serrée", "Close-Grip Bench Press", [.triceps], secondary: [.chest, .shoulders], equipment: .barbell, category: .strength),
        d("Développé couché Smith", "Smith Machine Bench Press", [.chest], secondary: [.triceps, .shoulders], equipment: .smithMachine),
        d("Développé incliné Smith", "Smith Machine Incline Press", [.chest], secondary: [.shoulders, .triceps], equipment: .smithMachine),
        d("Chest press machine", "Machine Chest Press", [.chest], secondary: [.triceps, .shoulders], equipment: .machine),
        d("Chest press convergente", "Converging Chest Press", [.chest], secondary: [.triceps], equipment: .machine),
        d("Écarté haltères", "Dumbbell Fly", [.chest], secondary: [.shoulders], equipment: .dumbbell),
        d("Écarté incliné haltères", "Incline Dumbbell Fly", [.chest], secondary: [.shoulders], equipment: .dumbbell),
        d("Écarté à la poulie", "Cable Fly", [.chest], secondary: [.shoulders], equipment: .cable, aliases: ["Vis-à-vis"]),
        d("Écarté poulie basse", "Low Cable Fly", [.chest], secondary: [.shoulders], equipment: .cable),
        d("Écarté poulie haute", "High Cable Fly", [.chest], equipment: .cable),
        d("Pec deck", "Pec Deck Fly", [.chest], equipment: .machine, aliases: ["Butterfly"]),
        d("Pompes", "Push-Up", [.chest], secondary: [.triceps, .shoulders, .core], equipment: .bodyweight),
        d("Pompes inclinées", "Incline Push-Up", [.chest], secondary: [.triceps], equipment: .bodyweight),
        d("Pompes déclinées", "Decline Push-Up", [.chest], secondary: [.shoulders, .triceps], equipment: .bodyweight),
        d("Dips pectoraux", "Chest Dip", [.chest], secondary: [.triceps, .shoulders], equipment: .bodyweight, category: .strength),
        d("Pullover haltère", "Dumbbell Pullover", [.chest, .lats], secondary: [.triceps], equipment: .dumbbell),

        // Dos
        d("Tractions pronation", "Pull-Up", [.lats], secondary: [.biceps, .upperBack], equipment: .bodyweight, category: .strength, aliases: ["Tractions", "Pull up"]),
        d("Tractions supination", "Chin-Up", [.lats, .biceps], secondary: [.upperBack], equipment: .bodyweight, category: .strength),
        d("Tractions prise neutre", "Neutral-Grip Pull-Up", [.lats], secondary: [.biceps, .upperBack], equipment: .bodyweight, category: .strength),
        d("Tractions assistées", "Assisted Pull-Up", [.lats], secondary: [.biceps, .upperBack], equipment: .machine),
        d("Tirage vertical pronation", "Wide-Grip Lat Pulldown", [.lats], secondary: [.biceps, .upperBack], equipment: .cable),
        d("Tirage vertical prise neutre", "Neutral-Grip Lat Pulldown", [.lats], secondary: [.biceps, .upperBack], equipment: .cable),
        d("Tirage vertical supination", "Reverse-Grip Lat Pulldown", [.lats], secondary: [.biceps], equipment: .cable),
        d("Tirage vertical unilatéral", "Single-Arm Lat Pulldown", [.lats], secondary: [.biceps], equipment: .cable),
        d("Rowing barre buste penché", "Bent-Over Barbell Row", [.upperBack, .lats], secondary: [.biceps, .hamstrings, .core], equipment: .barbell, category: .strength, aliases: ["Barbell row"]),
        d("Rowing Pendlay", "Pendlay Row", [.upperBack, .lats], secondary: [.biceps, .core], equipment: .barbell, category: .strength),
        d("Rowing Yates", "Yates Row", [.lats, .upperBack], secondary: [.biceps], equipment: .barbell),
        d("Rowing haltère unilatéral", "One-Arm Dumbbell Row", [.lats, .upperBack], secondary: [.biceps], equipment: .dumbbell),
        d("Rowing haltères sur banc incliné", "Chest-Supported Dumbbell Row", [.upperBack], secondary: [.lats, .biceps], equipment: .dumbbell),
        d("Rowing T-bar", "T-Bar Row", [.upperBack, .lats], secondary: [.biceps], equipment: .machine, category: .strength),
        d("Rowing poulie basse", "Seated Cable Row", [.upperBack, .lats], secondary: [.biceps], equipment: .cable),
        d("Rowing poulie basse prise large", "Wide-Grip Seated Cable Row", [.upperBack], secondary: [.biceps, .shoulders], equipment: .cable),
        d("Rowing unilatéral à la poulie", "Single-Arm Cable Row", [.lats, .upperBack], secondary: [.biceps], equipment: .cable),
        d("Rowing machine convergente", "Machine High Row", [.upperBack, .lats], secondary: [.biceps], equipment: .machine),
        d("Rowing machine poitrine appuyée", "Chest-Supported Machine Row", [.upperBack], secondary: [.lats, .biceps], equipment: .machine),
        d("Pull-over à la poulie", "Straight-Arm Cable Pulldown", [.lats], secondary: [.triceps], equipment: .cable, aliases: ["Straight arm pulldown"]),
        d("Shrugs barre", "Barbell Shrug", [.traps], secondary: [.shoulders], equipment: .barbell),
        d("Shrugs haltères", "Dumbbell Shrug", [.traps], secondary: [.shoulders], equipment: .dumbbell),
        d("Shrugs Smith", "Smith Machine Shrug", [.traps], secondary: [.forearms], equipment: .smithMachine),
        d("Shrugs à la trap bar", "Trap Bar Shrug", [.traps], secondary: [.forearms], equipment: .other),
        d("Élévation Y sur banc", "Incline Y Raise", [.traps, .shoulders], secondary: [.upperBack], equipment: .dumbbell),
        d("Extensions lombaires", "Back Extension", [.lowerBack], secondary: [.glutes, .hamstrings], equipment: .bodyweight),
        d("Extensions lombaires lestées", "Weighted Back Extension", [.lowerBack], secondary: [.glutes, .hamstrings], equipment: .other),
        d("Rack pull", "Rack Pull", [.lowerBack, .traps], secondary: [.glutes, .hamstrings, .forearms], equipment: .barbell, category: .strength),

        // Épaules
        d("Développé militaire barre", "Barbell Overhead Press", [.shoulders], secondary: [.triceps, .core], equipment: .barbell, category: .strength, aliases: ["OHP"]),
        d("Développé épaules haltères", "Dumbbell Shoulder Press", [.shoulders], secondary: [.triceps], equipment: .dumbbell),
        d("Développé Arnold", "Arnold Press", [.shoulders], secondary: [.triceps], equipment: .dumbbell),
        d("Développé épaules machine", "Machine Shoulder Press", [.shoulders], secondary: [.triceps], equipment: .machine),
        d("Développé militaire Smith", "Smith Machine Shoulder Press", [.shoulders], secondary: [.triceps], equipment: .smithMachine),
        d("Landmine press unilatéral", "Single-Arm Landmine Press", [.shoulders], secondary: [.chest, .triceps, .core], equipment: .barbell),
        d("Élévations latérales haltères", "Dumbbell Lateral Raise", [.shoulders], equipment: .dumbbell, aliases: ["Élévations latérales"]),
        d("Élévations latérales poulie", "Cable Lateral Raise", [.shoulders], equipment: .cable),
        d("Élévations latérales machine", "Machine Lateral Raise", [.shoulders], equipment: .machine),
        d("Élévations frontales haltères", "Dumbbell Front Raise", [.shoulders], equipment: .dumbbell),
        d("Oiseau haltères", "Bent-Over Reverse Fly", [.shoulders], secondary: [.upperBack], equipment: .dumbbell),
        d("Oiseau sur banc incliné", "Incline Bench Reverse Fly", [.shoulders], secondary: [.upperBack], equipment: .dumbbell),
        d("Reverse pec deck", "Reverse Pec Deck", [.shoulders], secondary: [.upperBack], equipment: .machine),
        d("Face pull", "Cable Face Pull", [.shoulders, .upperBack], secondary: [.traps], equipment: .cable),
        d("Rowing menton", "Upright Row", [.shoulders], secondary: [.traps, .biceps], equipment: .barbell),
        d("Rotation externe à la poulie", "Cable External Rotation", [.shoulders], equipment: .cable, category: .mobility),
        d("Rotation externe élastique", "Band External Rotation", [.shoulders], equipment: .bands, category: .mobility),

        // Bras
        d("Curl barre droite", "Barbell Curl", [.biceps], equipment: .barbell),
        d("Curl barre EZ", "EZ-Bar Curl", [.biceps], equipment: .barbell),
        d("Curl haltères alterné", "Alternating Dumbbell Curl", [.biceps], equipment: .dumbbell),
        d("Curl incliné haltères", "Incline Dumbbell Curl", [.biceps], equipment: .dumbbell),
        d("Curl marteau", "Hammer Curl", [.biceps], secondary: [.forearms], equipment: .dumbbell),
        d("Curl pupitre barre EZ", "EZ-Bar Preacher Curl", [.biceps], equipment: .barbell),
        d("Curl pupitre machine", "Machine Preacher Curl", [.biceps], equipment: .machine),
        d("Curl câble", "Cable Curl", [.biceps], equipment: .cable),
        d("Curl câble unilatéral", "Single-Arm Cable Curl", [.biceps], equipment: .cable),
        d("Curl Bayesian", "Bayesian Cable Curl", [.biceps], equipment: .cable),
        d("Curl concentration", "Concentration Curl", [.biceps], equipment: .dumbbell),
        d("Curl araignée", "Spider Curl", [.biceps], equipment: .dumbbell),
        d("Curl inversé barre EZ", "EZ-Bar Reverse Curl", [.forearms], secondary: [.biceps], equipment: .barbell),
        d("Curl poignets", "Wrist Curl", [.forearms], equipment: .dumbbell),
        d("Extension poignets", "Wrist Extension", [.forearms], equipment: .dumbbell),
        d("Curl poignets derrière le dos", "Behind-the-Back Wrist Curl", [.forearms], equipment: .barbell),
        d("Rotation pronation-supination", "Dumbbell Pronation Supination", [.forearms], equipment: .dumbbell),
        d("Rouleau à poignets", "Wrist Roller", [.forearms], equipment: .other),
        d("Suspension passive", "Dead Hang", [.forearms], secondary: [.lats, .shoulders], equipment: .bodyweight, category: .strength),
        d("Pincement de disques", "Plate Pinch Hold", [.forearms], equipment: .other, category: .strength),
        d("Farmer walk", "Farmer's Walk", [.fullBody], secondary: [.core, .traps, .forearms], equipment: .dumbbell, category: .strength),
        d("Dips triceps", "Triceps Dip", [.triceps], secondary: [.chest, .shoulders], equipment: .bodyweight, category: .strength),
        d("Dips assistés", "Assisted Dip", [.triceps], secondary: [.chest], equipment: .machine),
        d("Extension triceps poulie corde", "Rope Triceps Pushdown", [.triceps], equipment: .cable),
        d("Extension triceps poulie barre", "Straight-Bar Triceps Pushdown", [.triceps], equipment: .cable),
        d("Extension triceps poulie unilatérale", "Single-Arm Triceps Pushdown", [.triceps], equipment: .cable),
        d("Extension triceps au-dessus de la tête corde", "Overhead Rope Triceps Extension", [.triceps], equipment: .cable),
        d("Extension triceps haltère au-dessus de la tête", "Dumbbell Overhead Triceps Extension", [.triceps], equipment: .dumbbell),
        d("Barre au front", "EZ-Bar Skull Crusher", [.triceps], equipment: .barbell, aliases: ["Skull crusher"]),
        d("Extension triceps couché haltères", "Dumbbell Skull Crusher", [.triceps], equipment: .dumbbell),
        d("Kickback triceps haltère", "Dumbbell Triceps Kickback", [.triceps], equipment: .dumbbell),
        d("Pompes diamant", "Diamond Push-Up", [.triceps], secondary: [.chest, .shoulders], equipment: .bodyweight),
        d("Extension triceps machine", "Machine Triceps Extension", [.triceps], equipment: .machine),

        // Jambes et fessiers
        d("Squat barre", "Barbell Back Squat", [.quadriceps, .glutes], secondary: [.hamstrings, .core], equipment: .barbell, category: .strength, aliases: ["Back squat"]),
        d("Squat avant", "Front Squat", [.quadriceps], secondary: [.glutes, .core], equipment: .barbell, category: .strength),
        d("Squat gobelet", "Goblet Squat", [.quadriceps, .glutes], secondary: [.core], equipment: .dumbbell),
        d("Squat Smith", "Smith Machine Squat", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .smithMachine),
        d("Hack squat", "Hack Squat", [.quadriceps, .glutes], equipment: .machine, category: .strength),
        d("Pendulum squat", "Pendulum Squat", [.quadriceps, .glutes], equipment: .machine),
        d("Belt squat", "Belt Squat", [.quadriceps, .glutes], equipment: .machine),
        d("Presse à cuisses", "Leg Press", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .machine, category: .strength),
        d("Presse à cuisses unilatérale", "Single-Leg Press", [.quadriceps, .glutes], equipment: .machine),
        d("Leg extension", "Leg Extension", [.quadriceps], equipment: .machine),
        d("Leg extension unilatéral", "Single-Leg Extension", [.quadriceps], equipment: .machine),
        d("Fentes avant", "Forward Lunge", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .dumbbell),
        d("Fentes arrière", "Reverse Lunge", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .dumbbell),
        d("Fentes marchées", "Walking Lunge", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .dumbbell),
        d("Fentes bulgares", "Bulgarian Split Squat", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .dumbbell),
        d("Split squat Smith", "Smith Machine Split Squat", [.quadriceps, .glutes], equipment: .smithMachine),
        d("Step-up haltères", "Dumbbell Step-Up", [.quadriceps, .glutes], secondary: [.hamstrings], equipment: .dumbbell),
        d("Sissy squat", "Sissy Squat", [.quadriceps], equipment: .bodyweight),
        d("Spanish squat", "Spanish Squat", [.quadriceps], equipment: .bands),
        d("Wall sit", "Wall Sit", [.quadriceps], secondary: [.glutes], equipment: .bodyweight),
        d("Soulevé de terre conventionnel", "Conventional Deadlift", [.lowerBack, .hamstrings, .glutes], secondary: [.quadriceps, .core, .traps], equipment: .barbell, category: .strength, aliases: ["Deadlift"]),
        d("Soulevé de terre sumo", "Sumo Deadlift", [.glutes, .hamstrings, .adductors], secondary: [.quadriceps, .lowerBack], equipment: .barbell, category: .strength),
        d("Soulevé de terre roumain", "Romanian Deadlift", [.hamstrings, .glutes], secondary: [.lowerBack], equipment: .barbell, category: .strength, aliases: ["RDL"]),
        d("Soulevé de terre roumain haltères", "Dumbbell Romanian Deadlift", [.hamstrings, .glutes], secondary: [.lowerBack], equipment: .dumbbell),
        d("Soulevé de terre jambes tendues", "Stiff-Leg Deadlift", [.hamstrings], secondary: [.glutes, .lowerBack], equipment: .barbell),
        d("Good morning", "Barbell Good Morning", [.hamstrings, .glutes], secondary: [.lowerBack, .core], equipment: .barbell),
        d("Leg curl allongé", "Lying Leg Curl", [.hamstrings], equipment: .machine),
        d("Leg curl assis", "Seated Leg Curl", [.hamstrings], equipment: .machine),
        d("Leg curl debout unilatéral", "Standing Single-Leg Curl", [.hamstrings], equipment: .machine),
        d("Nordic curl", "Nordic Hamstring Curl", [.hamstrings], secondary: [.glutes], equipment: .bodyweight, category: .strength),
        d("Glute ham raise", "Glute Ham Raise", [.hamstrings, .glutes], secondary: [.lowerBack], equipment: .machine),
        d("Hip thrust barre", "Barbell Hip Thrust", [.glutes], secondary: [.hamstrings], equipment: .barbell, category: .strength),
        d("Hip thrust Smith", "Smith Machine Hip Thrust", [.glutes], secondary: [.hamstrings], equipment: .smithMachine),
        d("Hip thrust machine", "Machine Hip Thrust", [.glutes], secondary: [.hamstrings], equipment: .machine),
        d("Glute bridge", "Glute Bridge", [.glutes], secondary: [.hamstrings], equipment: .bodyweight),
        d("Kickback fessier poulie", "Cable Glute Kickback", [.glutes], equipment: .cable),
        d("Abduction de hanche machine", "Machine Hip Abduction", [.abductors], secondary: [.glutes], equipment: .machine),
        d("Adduction de hanche machine", "Machine Hip Adduction", [.adductors], equipment: .machine),
        d("Abduction de hanche élastique", "Band Hip Abduction", [.abductors], secondary: [.glutes], equipment: .bands),
        d("Adduction de hanche à la poulie", "Cable Hip Adduction", [.adductors], equipment: .cable),
        d("Planche de Copenhague", "Copenhagen Plank", [.adductors, .obliques], equipment: .bodyweight, category: .strength),
        d("Cossack squat", "Cossack Squat", [.adductors, .quadriceps, .glutes], equipment: .bodyweight, category: .mobility),
        d("Marche latérale élastique", "Lateral Band Walk", [.abductors, .glutes], equipment: .bands),
        d("Clamshell élastique", "Banded Clamshell", [.abductors, .glutes], equipment: .bands),
        d("Fire hydrant", "Fire Hydrant", [.abductors, .glutes], equipment: .bodyweight),
        d("Abduction de hanche à la poulie", "Cable Hip Abduction", [.abductors], secondary: [.glutes], equipment: .cable),
        d("Pull-through à la poulie", "Cable Pull-Through", [.glutes, .hamstrings], equipment: .cable),
        d("Reverse hyperextension", "Reverse Hyperextension", [.glutes, .hamstrings], secondary: [.lowerBack], equipment: .machine),

        // Mollets et core
        d("Mollets debout machine", "Standing Calf Raise", [.calves], equipment: .machine),
        d("Mollets assis machine", "Seated Calf Raise", [.calves], equipment: .machine),
        d("Mollets à la presse", "Leg Press Calf Raise", [.calves], equipment: .machine),
        d("Mollets debout haltères", "Dumbbell Standing Calf Raise", [.calves], equipment: .dumbbell),
        d("Mollets unilatéraux", "Single-Leg Calf Raise", [.calves], equipment: .bodyweight),
        d("Donkey calf raise", "Donkey Calf Raise", [.calves], equipment: .machine),
        d("Tibialis raise", "Tibialis Raise", [.calves], equipment: .bodyweight),
        d("Crunch", "Crunch", [.core], equipment: .bodyweight),
        d("Crunch à la poulie", "Cable Crunch", [.core], equipment: .cable),
        d("Crunch machine", "Machine Crunch", [.core], equipment: .machine),
        d("Relevé de jambes suspendu", "Hanging Leg Raise", [.core], secondary: [.lats], equipment: .bodyweight),
        d("Relevé de genoux suspendu", "Hanging Knee Raise", [.core], secondary: [.lats], equipment: .bodyweight),
        d("Relevé de jambes au sol", "Lying Leg Raise", [.core], equipment: .bodyweight),
        d("Ab wheel", "Ab Wheel Rollout", [.core], secondary: [.shoulders, .lats], equipment: .other),
        d("Planche", "Plank", [.core], secondary: [.shoulders], equipment: .bodyweight),
        d("Planche latérale", "Side Plank", [.obliques], secondary: [.core, .shoulders], equipment: .bodyweight),
        d("Dead bug", "Dead Bug", [.core], equipment: .bodyweight),
        d("Bird dog", "Bird Dog", [.core], secondary: [.glutes], equipment: .bodyweight),
        d("Pallof press", "Pallof Press", [.obliques], secondary: [.core], equipment: .cable),
        d("Woodchop à la poulie", "Cable Woodchop", [.obliques], secondary: [.core, .shoulders], equipment: .cable),
        d("Russian twist", "Russian Twist", [.obliques], secondary: [.core], equipment: .bodyweight),
        d("Crunch bicyclette", "Bicycle Crunch", [.obliques, .core], equipment: .bodyweight),
        d("Essuie-glaces suspendu", "Hanging Windshield Wiper", [.obliques, .core], secondary: [.lats], equipment: .bodyweight),
        d("Crunch inversé", "Reverse Crunch", [.core], equipment: .bodyweight),
        d("Dragon flag", "Dragon Flag", [.core], secondary: [.lats], equipment: .bodyweight, category: .strength),
        d("Suitcase carry", "Suitcase Carry", [.obliques], secondary: [.core, .fullBody, .forearms], equipment: .dumbbell, category: .strength),
        d("Hollow body hold", "Hollow Body Hold", [.core], equipment: .bodyweight),

        // Puissance et pliométrie
        d("Épaulé", "Power Clean", [.fullBody], secondary: [.upperBack, .traps, .quadriceps, .glutes], equipment: .barbell, category: .power),
        d("Épaulé-jeté", "Clean and Jerk", [.fullBody], equipment: .barbell, category: .power),
        d("Arraché", "Snatch", [.fullBody], equipment: .barbell, category: .power),
        d("Hang clean", "Hang Power Clean", [.fullBody], secondary: [.glutes, .upperBack, .traps], equipment: .barbell, category: .power),
        d("High pull", "Barbell High Pull", [.fullBody], secondary: [.upperBack, .traps, .shoulders], equipment: .barbell, category: .power),
        d("Push press", "Push Press", [.shoulders, .fullBody], secondary: [.triceps, .quadriceps], equipment: .barbell, category: .power),
        d("Thruster", "Barbell Thruster", [.fullBody], equipment: .barbell, category: .power),
        d("Kettlebell swing", "Kettlebell Swing", [.glutes, .hamstrings], secondary: [.lowerBack, .core], equipment: .other, category: .power),
        d("Saut sur box", "Box Jump", [.quadriceps, .glutes], secondary: [.calves], equipment: .bodyweight, category: .plyometric),
        d("Depth jump", "Depth Jump", [.quadriceps, .glutes], secondary: [.calves], equipment: .bodyweight, category: .plyometric),
        d("Pogo jumps", "Pogo Jumps", [.calves], secondary: [.quadriceps], equipment: .bodyweight, category: .plyometric),
        d("Squat jump", "Squat Jump", [.quadriceps, .glutes], secondary: [.calves], equipment: .bodyweight, category: .plyometric),
        d("Broad jump", "Standing Broad Jump", [.glutes, .quadriceps], secondary: [.hamstrings, .calves], equipment: .bodyweight, category: .plyometric),
        d("Sauts latéraux", "Lateral Bounds", [.glutes, .quadriceps], secondary: [.calves], equipment: .bodyweight, category: .plyometric),
        d("Saut unipodal", "Single-Leg Hop", [.quadriceps, .glutes], secondary: [.calves], equipment: .bodyweight, category: .plyometric),
        d("Fentes sautées", "Jumping Lunge", [.quadriceps, .glutes], equipment: .bodyweight, category: .plyometric),
        d("Pompes pliométriques", "Plyometric Push-Up", [.chest], secondary: [.triceps, .shoulders], equipment: .bodyweight, category: .plyometric),
        d("Lancer medecine-ball poitrine", "Medicine Ball Chest Pass", [.chest, .triceps], equipment: .other, category: .power),
        d("Slam medecine-ball", "Medicine Ball Slam", [.fullBody], secondary: [.core, .lats], equipment: .other, category: .power),

        // Mobilité et cardio
        d("Squat profond mobilité", "Deep Squat Hold", [.quadriceps, .glutes], secondary: [.core], equipment: .bodyweight, category: .mobility),
        d("Étirement fléchisseur de hanche", "Hip Flexor Stretch", [.quadriceps], secondary: [.glutes], equipment: .bodyweight, category: .mobility),
        d("90/90 hanches", "90/90 Hip Switch", [.glutes], equipment: .bodyweight, category: .mobility),
        d("Ouverture thoracique", "Thoracic Rotation", [.upperBack], secondary: [.shoulders, .obliques], equipment: .bodyweight, category: .mobility),
        d("Wall slide", "Wall Slide", [.shoulders, .upperBack], equipment: .bodyweight, category: .mobility),
        d("Dislocation épaules élastique", "Band Shoulder Dislocate", [.shoulders], equipment: .bands, category: .mobility),
        d("Scapular pull-up", "Scapular Pull-Up", [.lats, .upperBack, .shoulders], equipment: .bodyweight, category: .mobility),
        d("Burpees", "Burpee", [.fullBody], equipment: .bodyweight, category: .cardio),
        d("Mountain climbers", "Mountain Climber", [.core, .fullBody], equipment: .bodyweight, category: .cardio),
        d("Jumping jacks", "Jumping Jack", [.fullBody], equipment: .bodyweight, category: .cardio),
        d("Corde à sauter", "Jump Rope", [.calves, .fullBody], equipment: .other, category: .cardio),
        d("Rameur", "Rowing Ergometer", [.fullBody], secondary: [.upperBack, .lats, .quadriceps], equipment: .machine, category: .cardio),
        d("Vélo stationnaire", "Stationary Bike", [.quadriceps], secondary: [.glutes, .calves], equipment: .machine, category: .cardio),
        d("Vélo elliptique", "Elliptical Trainer", [.fullBody], equipment: .machine, category: .cardio),
        d("Tapis de course", "Treadmill Run", [.fullBody], secondary: [.quadriceps, .calves], equipment: .machine, category: .cardio),
        d("Stair climber", "Stair Climber", [.quadriceps, .glutes], secondary: [.calves], equipment: .machine, category: .cardio),
        d("Sled push", "Sled Push", [.fullBody], secondary: [.quadriceps, .glutes], equipment: .other, category: .power),
        d("Sled pull", "Sled Pull", [.fullBody], secondary: [.upperBack, .lats, .quadriceps], equipment: .other, category: .strength),
        d("Battle ropes", "Battle Ropes", [.fullBody], secondary: [.shoulders, .core], equipment: .other, category: .cardio),
        d("Marche inclinée", "Incline Treadmill Walk", [.glutes, .calves], secondary: [.quadriceps], equipment: .machine, category: .cardio)
    ]
}
