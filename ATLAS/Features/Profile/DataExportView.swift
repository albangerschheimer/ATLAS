import SwiftData
import SwiftUI

struct DataExportView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @State private var document: AtlasExportDocument?
    @State private var format = AtlasExportFormat.json
    @State private var showingExporter = false
    @State private var lastExportedFormat: AtlasExportFormat?
    @State private var showingResetConfirmation = false
    @State private var didResetData = false
    @AppStorage(NutritionGoalKeys.energy) private var energyGoal = NutritionGoals.defaults.energyKilocalories
    @AppStorage(NutritionGoalKeys.protein) private var proteinGoal = NutritionGoals.defaults.proteinGrams
    @AppStorage(NutritionGoalKeys.carbohydrates) private var carbohydrateGoal = NutritionGoals.defaults.carbohydrateGrams
    @AppStorage(NutritionGoalKeys.fat) private var fatGoal = NutritionGoals.defaults.fatGrams

    var body: some View {
        List {
            Section {
                ForEach(AtlasExportFormat.allCases) { exportFormat in
                    Button {
                        prepare(exportFormat)
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exportFormat.title)
                                    .foregroundStyle(.primary)
                                Text(exportFormat.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: exportFormat.systemImage)
                                .foregroundStyle(AtlasTheme.accent)
                        }
                        .padding(.vertical, 5)
                    }
                    .accessibilityIdentifier("data.export.\(exportFormat.rawValue)")
                }
            } header: {
                Text("Choisir un format")
            } footer: {
                Text("L’export est créé sur cet iPhone puis confié à la feuille système. ATLAS ne l’envoie vers aucun serveur.")
            }

            if let lastExportedFormat {
                Section {
                    Label(
                        "\(lastExportedFormat.title) créé",
                        systemImage: "checkmark.circle.fill"
                    )
                    .foregroundStyle(AtlasTheme.success)
                }
            }

            Section("Important") {
                Text("Le JSON est un export complet et versionné. La restauration dans ATLAS sera ajoutée dans une version ultérieure.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button("Supprimer mes données ATLAS", systemImage: "trash", role: .destructive) {
                    showingResetConfirmation = true
                }
                .accessibilityIdentifier("data.reset")
            } header: {
                Text("Zone sensible")
            } footer: {
                Text("Les séances, programmes, exercices personnalisés et notes seront supprimés. Le catalogue d’exercices intégré sera restauré.")
            }

            if didResetData {
                Section {
                    Label("Données personnelles supprimées", systemImage: "checkmark.shield.fill")
                        .foregroundStyle(AtlasTheme.success)
                }
            }
        }
        .navigationTitle("Exporter les données")
        .fileExporter(
            isPresented: $showingExporter,
            document: document,
            contentType: format.contentType,
            defaultFilename: defaultFilename
        ) { result in
            switch result {
            case .success:
                lastExportedFormat = format
            case let .failure(error):
                feedback.report(error, action: "L’export du fichier")
            }
        }
        .alert("Supprimer toutes vos données ?", isPresented: $showingResetConfirmation) {
            Button("Supprimer définitivement", role: .destructive) {
                feedback.run(action: "La suppression des données") {
                    try AtlasDataResetter.reset(modelContext)
                } onSuccess: {
                    didResetData = true
                    lastExportedFormat = nil
                    energyGoal = NutritionGoals.defaults.energyKilocalories
                    proteinGoal = NutritionGoals.defaults.proteinGrams
                    carbohydrateGoal = NutritionGoals.defaults.carbohydrateGrams
                    fatGoal = NutritionGoals.defaults.fatGrams
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Cette action est irréversible. Exportez d’abord le JSON si vous souhaitez conserver une copie portable.")
        }
    }

    private var defaultFilename: String {
        let date = Date.now.ISO8601Format().prefix(10)
        let stem = format == .json ? "ATLAS-export" : "ATLAS-historique"
        return "\(stem)-\(date).\(format.fileExtension)"
    }

    private func prepare(_ requestedFormat: AtlasExportFormat) {
        do {
            let exporter = AtlasDataExporter()
            let data: Data
            switch requestedFormat {
            case .json:
                data = try exporter.makeJSON(from: modelContext)
            case .csv:
                data = try exporter.makeCSV(from: modelContext)
            }
            format = requestedFormat
            document = AtlasExportDocument(data: data)
            showingExporter = true
        } catch {
            feedback.report(error, action: "La préparation de l’export")
        }
    }
}
