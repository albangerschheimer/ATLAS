import Charts
import SwiftData
import SwiftUI

struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @AppStorage("healthAccessRequested") private var healthAccessRequested = false
    @AppStorage(NutritionGoalKeys.energy) private var energyGoal = NutritionGoals.defaults.energyKilocalories
    @AppStorage(NutritionGoalKeys.protein) private var proteinGoal = NutritionGoals.defaults.proteinGrams
    @AppStorage(NutritionGoalKeys.carbohydrates) private var carbohydrateGoal = NutritionGoals.defaults.carbohydrateGrams
    @AppStorage(NutritionGoalKeys.fat) private var fatGoal = NutritionGoals.defaults.fatGrams
    @Query(sort: \NutritionEntryRecord.consumedAt, order: .reverse)
    private var localEntries: [NutritionEntryRecord]
    @StateObject private var healthModel = HealthDashboardViewModel()
    @State private var showingManualEntry = false
    @State private var showingScanner = false

    private var todayTotals: NutritionTotals {
        NutritionSummaryCalculator.totals(
            for: .now,
            healthDays: healthModel.snapshot.nutritionDays,
            localEntries: localEntries
        )
    }

    private var todayAvailableMetrics: Set<HealthMetricKey> {
        NutritionSummaryCalculator.availableMetrics(
            for: .now,
            healthDays: healthModel.snapshot.nutritionDays,
            localEntries: localEntries
        )
    }

    private var todayEntries: [NutritionEntryRecord] {
        localEntries.filter { Calendar.current.isDateInToday($0.consumedAt) }
    }

    private var todaySources: [String] {
        healthModel.snapshot.nutritionDays
            .first(where: { Calendar.current.isDateInToday($0.day) })?
            .sources ?? []
    }

    private var weeklyDays: [NutritionChartDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return NutritionChartDay(
                day: day,
                totals: NutritionSummaryCalculator.totals(
                    for: day,
                    healthDays: healthModel.snapshot.nutritionDays,
                    localEntries: localEntries,
                    calendar: calendar
                ),
                energyAvailable: NutritionSummaryCalculator.availableMetrics(
                    for: day,
                    healthDays: healthModel.snapshot.nutritionDays,
                    localEntries: localEntries,
                    calendar: calendar
                ).contains(.dietaryEnergy)
            )
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    nutritionMetric("Calories", value: availableValue(.dietaryEnergy, todayTotals.energyKilocalories), goal: energyGoal, unit: "kcal", color: AtlasTheme.accent)
                    nutritionMetric("Protéines", value: availableValue(.dietaryProtein, todayTotals.proteinGrams), goal: proteinGoal, unit: "g", color: .blue)
                    nutritionMetric("Glucides", value: availableValue(.dietaryCarbohydrates, todayTotals.carbohydrateGrams), goal: carbohydrateGoal, unit: "g", color: .orange)
                    nutritionMetric("Lipides", value: availableValue(.dietaryFat, todayTotals.fatGrams), goal: fatGoal, unit: "g", color: .purple)
                }
                .padding(.vertical, 6)
            } header: {
                Text("Aujourd’hui")
            } footer: {
                if todaySources.isEmpty {
                    Text(healthAccessRequested ? "Aucune donnée nutritionnelle lisible dans Apple Santé aujourd’hui. Ajoutez une saisie locale ou revoyez les autorisations Foodvisor." : "Connectez Apple Santé pour lire les données écrites par Foodvisor.")
                } else {
                    Text("Apple Santé : \(todaySources.joined(separator: ", ")). Les saisies ATLAS sont ajoutées au total sans être réécrites dans Santé.")
                }
            }

            Section("7 derniers jours") {
                Chart(weeklyDays.filter(\.energyAvailable)) { item in
                    BarMark(
                        x: .value("Jour", item.day, unit: .day),
                        y: .value("Calories", item.totals.energyKilocalories)
                    )
                    .foregroundStyle(AtlasTheme.accent.gradient)
                }
                .chartYAxisLabel("kcal")
                .frame(height: 190)
                .accessibilityLabel("Calories consommées sur les sept derniers jours")
                if weeklyDays.allSatisfy({ !$0.energyAvailable }) {
                    Text("Aucune calorie disponible sur cette période.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Journal ATLAS aujourd’hui") {
                if todayEntries.isEmpty {
                    ContentUnavailableView(
                        "Aucune saisie locale",
                        systemImage: "fork.knife",
                        description: Text("Les données Foodvisor restent affichées dans le total Apple Santé.")
                    )
                } else {
                    ForEach(todayEntries) { entry in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(entry.name)
                                    .font(.headline)
                                Spacer()
                                Text("\(entry.energyKilocalories.formatted(.number.precision(.fractionLength(0)))) kcal")
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text("P \(macro(entry.proteinGrams)) · G \(macro(entry.carbohydrateGrams)) · L \(macro(entry.fatGrams)) · \(entry.source.frenchName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions {
                            Button("Supprimer", role: .destructive) {
                                delete(entry)
                            }
                        }
                    }
                }
            }

            Section("Connexions") {
                NavigationLink {
                    HealthSettingsView()
                } label: {
                    Label("Foodvisor via Apple Santé", systemImage: "heart.text.square")
                }
                if let weight = healthModel.snapshot[.bodyMass].value {
                    LabeledContent(
                        "Dernier poids",
                        value: "\(weight.formatted(.number.precision(.fractionLength(1)))) kg"
                    )
                }
                Link(destination: URL(string: "https://world.openfoodfacts.org")!) {
                    Label("Base Open Food Facts", systemImage: "link")
                }
                Text("Les fiches produits sont fournies par les contributeurs d’Open Food Facts (base ODbL). Vérifiez toujours l’étiquette.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Nutrition")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Saisie manuelle", systemImage: "square.and.pencil") {
                        showingManualEntry = true
                    }
                    .accessibilityIdentifier("nutrition.add.manual")
                    Button("Scanner un code-barres", systemImage: "barcode.viewfinder") {
                        showingScanner = true
                    }
                    .accessibilityIdentifier("nutrition.add.barcode")
                    NavigationLink {
                        NutritionGoalSettingsView()
                    } label: {
                        Label("Modifier les objectifs", systemImage: "target")
                    }
                } label: {
                    Label("Ajouter", systemImage: "plus")
                }
                .accessibilityIdentifier("nutrition.add")
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            NutritionEntryEditorView()
        }
        .fullScreenCover(isPresented: $showingScanner) {
            BarcodeFoodFlowView()
        }
        .task {
            await healthModel.refresh(hasRequestedAccess: healthAccessRequested)
        }
        .refreshable {
            await healthModel.refresh(hasRequestedAccess: healthAccessRequested)
        }
    }

    private func nutritionMetric(
        _ title: String,
        value: Double?,
        goal: Double,
        unit: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(value.map { "\($0.formatted(.number.precision(.fractionLength(0)))) / \(goal.formatted(.number.precision(.fractionLength(0)))) \(unit)" } ?? "—")
                    .font(.subheadline.monospacedDigit())
            }
            ProgressView(value: goal > 0 ? min((value ?? 0) / goal, 1) : 0)
                .tint(color)
        }
        .accessibilityElement(children: .combine)
    }

    private func availableValue(_ metric: HealthMetricKey, _ value: Double) -> Double? {
        todayAvailableMetrics.contains(metric) ? value : nil
    }

    private func macro(_ value: Double) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0)))) g"
    }

    private func delete(_ entry: NutritionEntryRecord) {
        modelContext.delete(entry)
        feedback.run(action: "La suppression de l’aliment") {
            try modelContext.save()
        }
    }
}

private struct NutritionChartDay: Identifiable {
    var id: Date { day }
    let day: Date
    let totals: NutritionTotals
    let energyAvailable: Bool
}
