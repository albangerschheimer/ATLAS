import SwiftData
import SwiftUI

struct WorkoutHistoryView: View {
    @Query(
        filter: #Predicate<WorkoutRecord> { $0.stateRawValue == "completed" },
        sort: \WorkoutRecord.startedAt,
        order: .reverse
    )
    private var completed: [WorkoutRecord]

    var body: some View {
        List {
            if completed.isEmpty {
                ContentUnavailableView(
                    "Aucune séance terminée",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Les séances enregistrées apparaîtront ici.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(completed) { workout in
                    NavigationLink {
                        WorkoutHistoryDetailView(workout: workout)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(workout.name)
                                    .font(.headline)
                                Spacer()
                                Text(workout.startedAt, format: .dateTime.day().month(.abbreviated))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(workout.completedSetCountLabel) · \(workout.totalVolume.formatted(.number.precision(.fractionLength(0)))) kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Historique")
    }
}

struct WorkoutHistoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    let workout: WorkoutRecord
    @State private var workoutToOpen: WorkoutRecord?

    var body: some View {
        List {
            Section {
                Button {
                    let draft = workout.repeatedDraft()
                    modelContext.insert(draft)
                    feedback.save(modelContext, action: "La répétition de la séance") {
                        workoutToOpen = draft
                    }
                } label: {
                    Label("Refaire cette séance", systemImage: "arrow.clockwise")
                        .font(.headline)
                }
            }

            Section {
                LabeledContent("Date", value: workout.startedAt.formatted(date: .long, time: .shortened))
                LabeledContent("Durée", value: Duration.seconds(workout.duration).formatted(.time(pattern: .hourMinute)))
                LabeledContent("Volume", value: "\(workout.totalVolume.formatted(.number.precision(.fractionLength(0)))) kg")
            }

            ForEach(workout.orderedExercises) { entry in
                Section(entry.displayName) {
                    if let exercise = entry.exercise {
                        NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                            Label("Voir la fiche exercice", systemImage: "info.circle")
                        }
                    }
                    ForEach(entry.orderedSets.filter(\.isCompleted)) { set in
                        HStack {
                            Text(set.kind == .warmup ? "Échauffement" : "Série \(set.sortIndex + 1)")
                            Spacer()
                            Text(setSummary(set))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $workoutToOpen) { draft in
            NavigationStack {
                WorkoutEditorView(workout: draft)
            }
        }
    }

    private func setSummary(_ set: WorkoutSetRecord) -> String {
        let load = set.loadKilograms.map { "\($0.formatted(.number.precision(.fractionLength(0...2)))) kg" } ?? "PDC"
        let reps = set.repetitions.map(String.init) ?? "—"
        return "\(load) × \(reps)"
    }
}
