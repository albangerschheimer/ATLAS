import SwiftData
import SwiftUI

struct NutritionEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @State private var name: String
    @State private var consumedAt = Date.now
    @State private var servingGrams: Double
    @State private var energyKilocalories: Double
    @State private var proteinGrams: Double
    @State private var carbohydrateGrams: Double
    @State private var fatGrams: Double
    private let product: OpenFoodProduct?

    init(product: OpenFoodProduct? = nil) {
        self.product = product
        let serving = product?.servingQuantityGrams ?? 100
        let factor = serving / 100
        _name = State(initialValue: product?.displayName ?? "")
        _servingGrams = State(initialValue: serving)
        _energyKilocalories = State(initialValue: (product?.perHundredGrams.energyKilocalories ?? 0) * factor)
        _proteinGrams = State(initialValue: (product?.perHundredGrams.proteinGrams ?? 0) * factor)
        _carbohydrateGrams = State(initialValue: (product?.perHundredGrams.carbohydrateGrams ?? 0) * factor)
        _fatGrams = State(initialValue: (product?.perHundredGrams.fatGrams ?? 0) * factor)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Aliment") {
                    TextField("Nom", text: $name)
                        .accessibilityIdentifier("nutrition.entry.name")
                    DatePicker("Consommé le", selection: $consumedAt)
                    if product != nil {
                        LabeledContent {
                            TextField("Grammes", value: $servingGrams, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        } label: {
                            Text("Quantité (g)")
                        }
                    }
                }

                Section("Valeurs consommées") {
                    nutrientField("Calories", value: $energyKilocalories, unit: "kcal")
                    nutrientField("Protéines", value: $proteinGrams, unit: "g")
                    nutrientField("Glucides", value: $carbohydrateGrams, unit: "g")
                    nutrientField("Lipides", value: $fatGrams, unit: "g")
                }

                if product != nil {
                    Section {
                        Text("Valeurs issues d’Open Food Facts. Vérifiez l’étiquette et ajustez la quantité : la base est contributive et peut être incomplète.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(product == nil ? "Ajouter un aliment" : "Produit scanné")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("nutrition.entry.save")
                }
            }
            .onChange(of: servingGrams) { _, newValue in
                guard let product else { return }
                let factor = max(0, newValue) / 100
                energyKilocalories = product.perHundredGrams.energyKilocalories * factor
                proteinGrams = product.perHundredGrams.proteinGrams * factor
                carbohydrateGrams = product.perHundredGrams.carbohydrateGrams * factor
                fatGrams = product.perHundredGrams.fatGrams * factor
            }
        }
    }

    private func nutrientField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        LabeledContent {
            HStack(spacing: 5) {
                TextField(label, value: value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier("nutrition.entry.\(label.lowercased())")
                Text(unit)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Text(label)
        }
    }

    private func save() {
        let entry = NutritionEntryRecord(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            consumedAt: consumedAt,
            energyKilocalories: max(0, energyKilocalories),
            proteinGrams: max(0, proteinGrams),
            carbohydrateGrams: max(0, carbohydrateGrams),
            fatGrams: max(0, fatGrams),
            servingGrams: product == nil ? nil : max(0, servingGrams),
            barcode: product?.barcode,
            source: product == nil ? .manual : .barcode
        )
        modelContext.insert(entry)
        feedback.run(action: "L’ajout de l’aliment") {
            try modelContext.save()
        } onSuccess: {
            dismiss()
        }
    }
}
