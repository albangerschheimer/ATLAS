import SwiftUI

struct NutritionGoalSettingsView: View {
    @AppStorage(NutritionGoalKeys.energy) private var energy = NutritionGoals.defaults.energyKilocalories
    @AppStorage(NutritionGoalKeys.protein) private var protein = NutritionGoals.defaults.proteinGrams
    @AppStorage(NutritionGoalKeys.carbohydrates) private var carbohydrates = NutritionGoals.defaults.carbohydrateGrams
    @AppStorage(NutritionGoalKeys.fat) private var fat = NutritionGoals.defaults.fatGrams

    var body: some View {
        Form {
            Section("Objectifs journaliers") {
                goalField("Calories", value: $energy, unit: "kcal")
                goalField("Protéines", value: $protein, unit: "g")
                goalField("Glucides", value: $carbohydrates, unit: "g")
                goalField("Lipides", value: $fat, unit: "g")
            }

            Section {
                Text("Ces objectifs sont personnels et ne constituent pas une prescription médicale. Ils restent uniquement sur cet iPhone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Objectifs nutrition")
    }

    private func goalField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        LabeledContent {
            HStack(spacing: 5) {
                TextField(label, value: value, format: .number.precision(.fractionLength(0)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text(label)
        }
    }
}
