import SwiftData
import SwiftUI

struct TrainingProgressView: View {
    @State private var section = 0
    @Query(
        filter: #Predicate<WorkoutRecord> { $0.stateRawValue == "completed" },
        sort: \WorkoutRecord.startedAt,
        order: .reverse
    )
    private var completed: [WorkoutRecord]

    private var totalVolume: Double {
        completed.reduce(0) { $0 + $1.totalVolume }
    }

    private var exerciseSummaries: [ExerciseProgressSummary] {
        let entries = completed.flatMap { workout in
            workout.exercises.map { entry in
                (
                    entry.exerciseIDSnapshot,
                    entry.displayName,
                    ExercisePerformance(
                        exerciseID: entry.exerciseIDSnapshot,
                        exerciseName: entry.displayName,
                        date: workout.startedAt,
                        sets: entry.orderedSets.map(\.snapshot)
                    )
                )
            }
        }
        let groups = Dictionary(grouping: entries, by: { $0.0 })

        return groups.map { _, values in
            ExerciseProgressSummary(
                id: values[0].0,
                name: values[0].1,
                records: TrainingAnalytics.records(from: values.map(\.2))
            )
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AtlasTheme.sectionSpacing) {
                    Picker("Progression", selection: $section) {
                        Text("Entraînement").tag(0)
                        Text("Mesures").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if section == 1 {
                        BodyMeasurementsView()
                    } else {
                        AtlasSectionHeader(
                            title: "Vue d’ensemble",
                            subtitle: "Vos données ATLAS, calculées sur les séries de travail"
                        )

                        HStack(spacing: 12) {
                            MetricTile(
                                title: "Séances",
                                value: "\(completed.count)",
                                detail: "terminées"
                            )
                            MetricTile(
                                title: "Volume total",
                                value: totalVolume.formatted(.number.notation(.compactName).precision(.fractionLength(1))),
                                detail: "kg",
                                tint: AtlasTheme.success
                            )
                        }

                        AtlasSectionHeader(
                            title: "Records par exercice",
                            subtitle: "Charge, répétitions et 1RM estimé"
                        )

                        if exerciseSummaries.isEmpty {
                            EmptyStateView(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Pas encore de records",
                                message: "Terminez une séance pour calculer vos premiers repères."
                            )
                        } else {
                            ForEach(exerciseSummaries) { summary in
                                AtlasCard {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            AtlasIconBadge(systemImage: "trophy.fill", tint: AtlasTheme.warning)
                                            Text(summary.name)
                                                .font(.headline)
                                            Spacer()
                                        }
                                        HStack {
                                            recordValue("Charge", summary.records.heaviestLoadKilograms, suffix: "kg")
                                            recordValue("1RM estimé", summary.records.estimatedOneRepMaxKilograms, suffix: "kg")
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text("Répétitions")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text(summary.records.bestRepetitions.map(String.init) ?? "—")
                                                    .font(.headline.monospacedDigit())
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                }
                            }
                        }

                        Label(
                            "Le 1RM est une estimation Epley calculée sur les séries de 1 à 12 répétitions.",
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, AtlasTheme.screenPadding)
                .padding(.vertical, 16)
            }
            .background(AtlasTheme.canvas)
            .navigationTitle("Progrès")
        }
    }

    private func recordValue(_ label: String, _ value: Double?, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.map { "\($0.formatted(.number.precision(.fractionLength(1)))) \(suffix)" } ?? "—")
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ExerciseProgressSummary: Identifiable {
    let id: UUID
    let name: String
    let records: ExerciseRecords
}
