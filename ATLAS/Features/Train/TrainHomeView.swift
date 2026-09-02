import SwiftData
import SwiftUI

struct TrainHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Query(
        filter: #Predicate<WorkoutRecord> { $0.stateRawValue == "draft" },
        sort: \WorkoutRecord.startedAt,
        order: .reverse
    )
    private var drafts: [WorkoutRecord]
    @State private var workoutToOpen: WorkoutRecord?

    private var draft: WorkoutRecord? {
        drafts.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AtlasTheme.sectionSpacing) {
                    Text("Séance")
                        .font(.largeTitle.bold())

                    Button {
                        if let draft {
                            workoutToOpen = draft
                        } else {
                            let workout = WorkoutRecord(name: "Séance libre")
                            modelContext.insert(workout)
                            feedback.save(modelContext, action: "La création de la séance") {
                                workoutToOpen = workout
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: draft == nil ? "play.fill" : "arrow.clockwise")
                            VStack(alignment: .leading, spacing: 2) {
                                Text(draft == nil ? "Commencer une séance libre" : "Reprendre \(draft?.name ?? "la séance")")
                                    .font(.headline)
                                if let draft {
                                    Text(draft.completedSetSummary)
                                        .font(.caption)
                                        .opacity(0.82)
                                }
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .accessibilityIdentifier("train.startWorkout")

                    NavigationLink {
                        ExerciseLibraryView()
                    } label: {
                        TrainDestinationCard(
                            icon: "figure.strengthtraining.traditional",
                            title: "Bibliothèque d’exercices",
                            subtitle: "Muscles, historique, records et alternatives",
                            tint: MuscleGroup.chest.atlasColor
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ProgramsView()
                    } label: {
                        TrainDestinationCard(
                            icon: "list.bullet.clipboard",
                            title: "Programmes",
                            subtitle: "Jours, séries, répétitions et temps de repos",
                            tint: AtlasTheme.accent
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        WorkoutHistoryView()
                    } label: {
                        TrainDestinationCard(
                            icon: "clock.arrow.circlepath",
                            title: "Historique",
                            subtitle: "Séances terminées, volume et records",
                            tint: AtlasTheme.success
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AtlasTheme.screenPadding)
                .padding(.vertical, 18)
            }
            .background(AtlasTheme.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $workoutToOpen) { workout in
                NavigationStack {
                    WorkoutEditorView(workout: workout)
                }
            }
        }
    }
}

private struct TrainDestinationCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        AtlasCard(tint: tint) {
            HStack(spacing: 14) {
                AtlasIconBadge(systemImage: icon, tint: tint)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
