import SwiftData
import SwiftUI
import UIKit

struct WorkoutEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var workout: WorkoutRecord
    @Query private var recentCompletedWorkouts: [WorkoutRecord]
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var restTimerEnd: Date?
    @State private var newPR: NewPRResult?

    init(workout: WorkoutRecord) {
        _workout = Bindable(wrappedValue: workout)
        var descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { $0.stateRawValue == "completed" },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        _recentCompletedWorkouts = Query(descriptor)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if workout.orderedExercises.isEmpty {
                    EmptyStateView(
                        icon: "dumbbell",
                        title: "Séance vide",
                        message: "Ajoutez un exercice pour commencer à enregistrer vos séries."
                    )
                    .padding(.top, 50)
                }

                ForEach(workout.orderedExercises) { entry in
                    WorkoutExerciseCard(
                        entry: entry,
                        history: recentHistory(for: entry),
                        onSetCompleted: { set in
                            newPR = NewPRResult.detect(set: set, exerciseName: entry.displayName, previous: TrainingAnalytics.records(from: recentHistory(for: entry)))
                            restTimerEnd = Date.now.addingTimeInterval(TimeInterval(entry.targetRestSeconds))
                            feedback.save(modelContext, action: "L’enregistrement de la série")
                        }
                    )
                }

                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Ajouter un exercice", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .padding(.bottom, restTimerEnd == nil ? 20 : 90)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer") {
                    feedback.save(modelContext, action: "L’enregistrement du brouillon") {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Terminer") {
                    showingFinishConfirmation = true
                }
                .fontWeight(.semibold)
                .disabled(workout.completedSetCount == 0)
                .accessibilityIdentifier("workout.finish")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Supprimer le brouillon", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let restTimerEnd {
                RestTimerBar(
                    endDate: restTimerEnd,
                    onAddTime: {
                        self.restTimerEnd = restTimerEnd.addingTimeInterval(30)
                    },
                    onStop: {
                        self.restTimerEnd = nil
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 6)
            }
        }
        .overlay(alignment: .top) {
            if let newPR {
                NewPRBanner(result: newPR).padding().transition(.move(edge: .top).combined(with: .opacity)).zIndex(4)
                    .task { try? await Task.sleep(for: .seconds(3)); withAnimation { self.newPR = nil } }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(title: "Ajouter à la séance") { exercise in
                let entry = WorkoutExerciseRecord(
                    exercise: exercise,
                    sortIndex: workout.exercises.count
                )
                entry.sets = [WorkoutSetRecord(sortIndex: 0)]
                workout.exercises.append(entry)
                feedback.save(modelContext, action: "L’ajout de l’exercice")
            }
        }
        .confirmationDialog(
            "Terminer la séance ?",
            isPresented: $showingFinishConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enregistrer la séance") {
                workout.state = .completed
                workout.endedAt = .now
                feedback.save(modelContext, action: "La finalisation de la séance") {
                    dismiss()
                }
            }
            Button("Continuer", role: .cancel) {}
        } message: {
            Text("\(workout.completedSetCount) séries seront conservées dans l’historique.")
        }
        .alert("Supprimer cette séance ?", isPresented: $showingDeleteConfirmation) {
            Button("Supprimer", role: .destructive) {
                modelContext.delete(workout)
                feedback.save(modelContext, action: "La suppression du brouillon") {
                    dismiss()
                }
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Le brouillon et ses séries seront définitivement supprimés.")
        }
    }

    private func recentHistory(for entry: WorkoutExerciseRecord) -> [ExercisePerformance] {
        recentCompletedWorkouts
            .filter { $0.id != workout.id }
            .flatMap { completedWorkout in
                completedWorkout.exercises
                    .filter { $0.exerciseIDSnapshot == entry.exerciseIDSnapshot }
                    .map { historicalEntry in
                        ExercisePerformance(
                            exerciseID: historicalEntry.exerciseIDSnapshot,
                            exerciseName: historicalEntry.displayName,
                            date: completedWorkout.startedAt,
                            sets: historicalEntry.orderedSets.map(\.snapshot)
                        )
                    }
            }
            .sorted { $0.date > $1.date }
    }
}

private struct WorkoutExerciseCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var entry: WorkoutExerciseRecord
    @Query(sort: \ExerciseRecord.nameFrench) private var allExercises: [ExerciseRecord]
    let history: [ExercisePerformance]
    let onSetCompleted: (TrainingSetSnapshot) -> Void
    @State private var showingReplacementPicker = false

    private var previousRecords: ExerciseRecords {
        TrainingAnalytics.records(from: history)
    }

    private var suggestedLoad: Double? {
        guard
            let latest = history.first,
            let prescribedSetCount = entry.targetSetCount,
            let topOfRange = entry.targetMaximumRepetitions,
            let targetRIR = entry.targetRIR,
            let currentLoad = latest.sets
                .filter({ $0.kind == .working && $0.isCompleted })
                .compactMap(\.loadKilograms)
                .max()
        else { return nil }

        let recommendation = ProgressionEngine.doubleProgression(
            sets: latest.sets,
            prescribedSetCount: prescribedSetCount,
            topOfRepRange: topOfRange,
            targetRIR: targetRIR,
            currentLoadKilograms: currentLoad,
            loadIncrementKilograms: 2.5
        )

        guard case let .increaseLoad(load) = recommendation.action else { return nil }
        return load
    }

    var body: some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.displayName)
                            .font(.title3.bold())
                            .onLongPressGesture { showingReplacementPicker = true }
                        if let targetSummary = entry.targetSummary {
                            Text(targetSummary)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AtlasTheme.accent)
                        }
                        if let latest = history.first {
                            Text("Dernière fois · \(latest.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Première séance enregistrée")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if let exercise = entry.exercise {
                        NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                            Image(systemName: "info.circle").padding(8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Informations sur \(entry.displayName)")
                    }
                    Menu {
                        Stepper("Repos \(entry.targetRestSeconds) s", value: $entry.targetRestSeconds, in: 30...600, step: 15)
                        Button("Remplacer l’exercice", systemImage: "arrow.triangle.2.circlepath") {
                            showingReplacementPicker = true
                        }
                        Button("Supprimer l’exercice", systemImage: "trash", role: .destructive) {
                            modelContext.delete(entry)
                            feedback.save(modelContext, action: "La suppression de l’exercice")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(8)
                    }
                }

                if let latest = history.first {
                    RecentPerformanceView(performance: latest)
                }

                if let estimate = previousRecords.estimatedOneRepMaxKilograms {
                    Label(
                        "Meilleur 1RM estimé : \(estimate.formatted(.number.precision(.fractionLength(1)))) kg",
                        systemImage: "trophy.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(AtlasTheme.warning)
                }

                if let suggestedLoad {
                    Label(
                        "Progression proposée : \(suggestedLoad.formatted(.number.precision(.fractionLength(0...2)))) kg",
                        systemImage: "arrow.up.right.circle.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AtlasTheme.success)
                }

                HStack(spacing: 8) {
                    Text("SÉRIE").frame(width: 38)
                    Text("KG").frame(maxWidth: .infinity)
                    Text("REPS").frame(maxWidth: .infinity)
                    Text("RIR").frame(maxWidth: .infinity)
                    Image(systemName: "checkmark").frame(width: 36)
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

                ForEach(entry.orderedSets) { set in
                    SwipeToDeleteSetRow(
                        deleteIdentifier: "workout.exercise.\(entry.sortIndex).set.\(set.sortIndex).delete"
                    ) {
                        delete(set)
                    } content: {
                        WorkoutSetRow(
                            set: set,
                            identifierPrefix: "workout.exercise.\(entry.sortIndex).set.\(set.sortIndex)"
                        ) {
                            if set.isCompleted {
                                onSetCompleted(set.snapshot)
                            } else {
                                feedback.save(modelContext, action: "La modification de la série")
                            }
                        }
                    }
                }

                Text("Glissez une série vers la droite pour la supprimer.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                TextField("Note sur l’exercice", text: $entry.notes, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...3)

                Button("Ajouter une série", systemImage: "plus") {
                    let previous = entry.orderedSets.last
                    let newSet = WorkoutSetRecord(
                        sortIndex: entry.sets.count,
                        loadKilograms: previous?.loadKilograms,
                        repetitions: previous?.repetitions,
                        rir: previous?.rir,
                        kind: previous?.kind ?? .working
                    )
                    entry.sets.append(newSet)
                    feedback.save(modelContext, action: "L’ajout de la série")
                }
                .font(.subheadline.weight(.semibold))
                .accessibilityIdentifier("workout.exercise.\(entry.sortIndex).set.add")
            }
        }
        .sheet(isPresented: $showingReplacementPicker) {
            if let source = entry.exercise {
                SmartExerciseReplacementView(source: source, exercises: allExercises) { replacement in
                    entry.replaceExercise(with: replacement)
                    feedback.save(modelContext, action: "Le remplacement de l’exercice")
                }
            } else {
                ExercisePickerView(title: "Remplacer l’exercice") { replacement in
                    entry.replaceExercise(with: replacement)
                    feedback.save(modelContext, action: "Le remplacement de l’exercice")
                }
            }
        }
    }

    private func delete(_ set: WorkoutSetRecord) {
        guard let removed = entry.removeSet(withID: set.id) else { return }
        modelContext.delete(removed)
        feedback.save(modelContext, action: "La suppression de la série")
    }
}

private struct SwipeToDeleteSetRow<Content: View>: View {
    private let actionWidth: CGFloat = 88
    let deleteIdentifier: String
    let onDelete: () -> Void
    let content: Content
    @State private var offset: CGFloat = 0

    init(
        deleteIdentifier: String,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.deleteIdentifier = deleteIdentifier
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            if offset >= actionWidth * 0.5 {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: actionWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color.red, in: RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("Supprimer la série")
                .accessibilityIdentifier(deleteIdentifier)
            } else {
                Color.red
                    .frame(width: actionWidth)
            }

            content
                .padding(.horizontal, 2)
                .background(Color(.secondarySystemGroupedBackground))
                .offset(x: offset)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 18)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            offset = min(actionWidth, max(0, value.translation.width))
                        }
                        .onEnded { value in
                            let predictedWidth = value.predictedEndTranslation.width
                            if predictedWidth > actionWidth * 1.4 {
                                onDelete()
                                return
                            }
                            let shouldReveal = predictedWidth > actionWidth * 0.55
                            withAnimation(.snappy) {
                                offset = shouldReveal ? actionWidth : 0
                            }
                        }
                )
                .accessibilityAction(named: "Supprimer la série", onDelete)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct WorkoutSetRow: View {
    @Bindable var set: WorkoutSetRecord
    let identifierPrefix: String
    let onCompletionChanged: () -> Void
    @State private var showingDetails = false

    var body: some View {
        HStack(spacing: 8) {
            Menu {
                Picker("Type de série", selection: Binding(
                    get: { set.kind },
                    set: { set.kind = $0 }
                )) {
                    ForEach(TrainingSetKind.allCases, id: \.self) { kind in
                        Text(kind.frenchName).tag(kind)
                    }
                }
                Button("Notes et métriques", systemImage: "slider.horizontal.3") {
                    showingDetails = true
                }
            } label: {
                Text(set.kind == .warmup ? "W" : "\(set.sortIndex + 1)")
                    .font(.caption.bold())
                    .frame(width: 34, height: 34)
                    .background(
                        set.kind == .warmup ? AtlasTheme.warning.opacity(0.18) : Color.secondary.opacity(0.12),
                        in: Circle()
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.kind.frenchName)

            OptionalDoubleField(
                placeholder: "0",
                value: $set.loadKilograms,
                accessibilityIdentifier: "\(identifierPrefix).load"
            )
            OptionalIntegerField(
                placeholder: "0",
                value: $set.repetitions,
                accessibilityIdentifier: "\(identifierPrefix).repetitions"
            )
            OptionalDoubleField(
                placeholder: "—",
                value: $set.rir,
                accessibilityIdentifier: "\(identifierPrefix).rir"
            )

            Button {
                set.isCompleted.toggle()
                set.completedAt = set.isCompleted ? .now : nil
                onCompletionChanged()
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? AtlasTheme.success : .secondary)
                    .frame(width: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(set.isCompleted ? "Série terminée" : "Marquer la série terminée")
            .accessibilityIdentifier("\(identifierPrefix).complete")
        }
        .padding(.vertical, 2)
        .opacity(set.isCompleted ? 0.75 : 1)
        .sheet(isPresented: $showingDetails) {
            NavigationStack {
                SetDetailsView(set: set)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private struct SetDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var set: WorkoutSetRecord

    var body: some View {
        Form {
            Section("Effort") {
                TextField("RPE optionnel", value: $set.rpe, format: .number)
                    .keyboardType(.decimalPad)
            }
            Section("Exercices chronométrés ou de distance") {
                TextField("Durée en secondes", value: $set.durationSeconds, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Distance en mètres", value: $set.distanceMeters, format: .number)
                    .keyboardType(.decimalPad)
            }
            Section("Notes") {
                TextEditor(text: $set.notes)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle("Détails de la série")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") {
                    feedback.save(modelContext, action: "L’enregistrement des détails de la série") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct OptionalDoubleField: View {
    let placeholder: String
    @Binding var value: Double?
    let accessibilityIdentifier: String

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct OptionalIntegerField: View {
    let placeholder: String
    @Binding var value: Int?
    let accessibilityIdentifier: String

    var body: some View {
        TextField(placeholder, value: $value, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct RecentPerformanceView: View {
    let performance: ExercisePerformance

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(performance.sets.filter(\.isCompleted).prefix(3).enumerated()), id: \.offset) { _, set in
                Text(summary(for: set))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func summary(for set: TrainingSetSnapshot) -> String {
        let load = set.loadKilograms.map { "\($0.formatted(.number.precision(.fractionLength(0...2)))) kg" } ?? "Poids du corps"
        let reps = set.repetitions.map(String.init) ?? "—"
        return "\(load) × \(reps)"
    }
}

private struct RestTimerBar: View {
    let endDate: Date
    let onAddTime: () -> Void
    let onStop: () -> Void
    @State private var notifiedThirty = false
    @State private var notifiedEnd = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(endDate.timeIntervalSince(context.date).rounded(.up)))
            HStack {
                Image(systemName: "timer")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Duration.seconds(remaining).formatted(.time(pattern: .minuteSecond)))
                        .font(.headline.monospacedDigit())
                }
                Spacer()
                Button("+30 s") { onAddTime() }
                    .buttonStyle(.bordered)
                Button(remaining == 0 ? "Fermer" : "Passer") { onStop() }
                    .buttonStyle(.bordered)
            }
            .padding(12)
            .background(.ultraThickMaterial, in: Capsule())
            .shadow(radius: 8, y: 3)
            .onChange(of: remaining) { _, value in
                if value <= 30, value > 0, !notifiedThirty { notifiedThirty = true; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                if value == 0, !notifiedEnd { notifiedEnd = true; UINotificationFeedbackGenerator().notificationOccurred(.success) }
            }
        }
    }
}

private struct SmartExerciseReplacementView: View {
    @Environment(\.dismiss) private var dismiss
    let source: ExerciseRecord
    let exercises: [ExerciseRecord]
    let onSelect: (ExerciseRecord) -> Void

    var body: some View {
        NavigationStack {
            List(ExerciseSimilarityEngine.recommendations(for: source, among: exercises).prefix(20)) { match in
                Button {
                    onSelect(match.exercise); dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(match.exercise.displayName).font(.headline).foregroundStyle(.primary)
                            Text("Mêmes muscles · \(match.exercise.equipment.frenchName)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(match.percentage) %").font(.headline.monospacedDigit()).foregroundStyle(AtlasTheme.success)
                    }
                }
            }
            .navigationTitle("Remplacer l’exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Fermer") { dismiss() } }
        }
    }
}

private struct NewPRResult: Equatable {
    let exerciseName: String
    let load: Double
    let reps: Int
    let estimate: Double
    let increase: Double

    static func detect(set: TrainingSetSnapshot, exerciseName: String, previous: ExerciseRecords) -> Self? {
        guard set.kind == .working, let load = set.loadKilograms, let reps = set.repetitions,
              let estimate = TrainingAnalytics.estimatedOneRepMax(loadKilograms: load, repetitions: reps),
              estimate > (previous.estimatedOneRepMaxKilograms ?? 0) else { return nil }
        return .init(exerciseName: exerciseName, load: load, reps: reps, estimate: estimate, increase: estimate - (previous.estimatedOneRepMaxKilograms ?? estimate))
    }
}

private struct NewPRBanner: View {
    let result: NewPRResult
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill").font(.title2).foregroundStyle(AtlasTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text("NOUVEAU PR").font(.caption.bold()).foregroundStyle(AtlasTheme.warning)
                Text(result.exerciseName).font(.headline)
                Text("\(result.load.formatted()) kg × \(result.reps) · e1RM \(result.estimate.formatted(.number.precision(.fractionLength(1)))) kg")
                    .font(.caption.monospacedDigit())
            }
        }.padding(14).background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 18)).shadow(radius: 12)
    }
}
