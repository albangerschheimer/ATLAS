import Charts
import SwiftData
import SwiftUI

struct ExerciseDetailView: View {
    @Bindable var exercise: ExerciseRecord
    @Query(sort: \WorkoutRecord.startedAt, order: .reverse) private var workouts: [WorkoutRecord]
    @State private var metric = ExerciseProgressMetric.e1RM
    @State private var period = ExerciseProgressPeriod.days90
    @State private var showingEdit = false

    private var performances: [ExercisePerformance] {
        workouts.filter { $0.state == .completed }.compactMap { workout in
            guard let entry = workout.exercises.first(where: { $0.exerciseIDSnapshot == exercise.id }) else { return nil }
            return ExercisePerformance(exerciseID: exercise.id, exerciseName: entry.displayName, date: workout.startedAt, sets: entry.orderedSets.map(\.snapshot))
        }.sorted { $0.date < $1.date }
    }
    private var points: [ExerciseProgressPoint] { ExerciseProgressAnalytics.points(from: performances) }
    private var visiblePoints: [ExerciseProgressPoint] { ExerciseProgressAnalytics.filtered(points, period: period) }
    private var records: ExerciseRecords { TrainingAnalytics.records(from: performances) }
    private var workingSets: [TrainingSetSnapshot] { performances.flatMap(\.sets).filter { $0.isCompleted && $0.kind == .working } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                muscles
                history
                recordsSection
                progress
                statistics
            }.padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Modifier") { showingEdit = true } }
        .sheet(isPresented: $showingEdit) { NavigationStack { ExerciseEditView(exercise: exercise) } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(exercise.displayName).font(.largeTitle.bold())
            HStack { pill(exercise.category.frenchName, AtlasTheme.accent); pill(exercise.equipment.frenchName, .secondary) }
        }
    }

    private var muscles: some View {
        section("MUSCLES") {
            VStack(alignment: .leading, spacing: 12) {
                muscleRows("PRINCIPAUX", exercise.primaryMuscles, opacity: 1)
                muscleRows("SECONDAIRES", exercise.secondaryMuscles, opacity: 0.48)
            }
        }
    }

    private var history: some View {
        section("DERNIÈRE SÉANCE") {
            if let last = performances.last {
                Text(last.date.formatted(date: .long, time: .omitted)).font(.caption).foregroundStyle(.secondary)
                ForEach(Array(last.sets.filter { $0.isCompleted }.enumerated()), id: \.offset) { _, set in
                    Text("\((set.loadKilograms ?? 0).formatted(.number.precision(.fractionLength(0...2)))) kg × \(set.repetitions ?? 0) · RIR \((set.rir ?? 0).formatted(.number.precision(.fractionLength(0...1))))")
                        .font(.body.monospacedDigit())
                }
            } else { Text("Aucun historique pour cet exercice.").foregroundStyle(.secondary) }
        }
    }

    private var recordsSection: some View {
        section("RECORDS PERSONNELS") {
            HStack {
                record("Charge", records.heaviestLoadKilograms, "kg")
                record("e1RM", records.estimatedOneRepMaxKilograms, "kg")
                VStack(alignment: .leading) { Text("Répétitions").font(.caption).foregroundStyle(.secondary); Text(records.bestRepetitions.map(String.init) ?? "—").font(.headline.monospacedDigit()) }.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var progress: some View {
        section("PROGRESSION") {
            Picker("Métrique", selection: $metric) { ForEach(ExerciseProgressMetric.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            Picker("Période", selection: $period) { ForEach(ExerciseProgressPeriod.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
            if visiblePoints.isEmpty { Text("Pas encore assez de séries de travail.").foregroundStyle(.secondary).frame(height: 150) }
            else {
                Chart(visiblePoints) { point in
                    LineMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value(for: metric))).interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", point.date), y: .value(metric.rawValue, point.value(for: metric)))
                }.foregroundStyle(exercise.primaryMuscles.compactMap(MuscleGroup.init).first?.atlasColor ?? AtlasTheme.accent).frame(height: 210)
            }
        }
    }

    private var statistics: some View {
        section("STATISTIQUES") {
            HStack { stat("SÉANCES", performances.count); stat("SÉRIES", workingSets.count); stat("REPS", workingSets.compactMap(\.repetitions).reduce(0, +)) }
            if let first = performances.first, let last = performances.last {
                LabeledContent("Première séance", value: first.date.formatted(date: .abbreviated, time: .omitted))
                LabeledContent("Dernière séance", value: last.date.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View { VStack(alignment: .leading, spacing: 10) { Text(title).font(.caption.bold()).foregroundStyle(.secondary); AtlasCard { VStack(alignment: .leading, spacing: 10) { content() } } } }
    private func pill(_ text: String, _ color: Color) -> some View { Text(text.uppercased()).font(.caption2.bold()).padding(.horizontal, 10).padding(.vertical, 6).background(color.opacity(0.14), in: Capsule()).foregroundStyle(color) }
    private func muscleRows(_ label: String, _ values: [String], opacity: Double) -> some View { VStack(alignment: .leading, spacing: 7) { Text(label).font(.caption2.bold()).foregroundStyle(.secondary); FlowLayout(items: values.compactMap(MuscleGroup.init), opacity: opacity) } }
    private func record(_ label: String, _ value: Double?, _ suffix: String) -> some View { VStack(alignment: .leading) { Text(label).font(.caption).foregroundStyle(.secondary); Text(value.map { "\($0.formatted(.number.precision(.fractionLength(1)))) \(suffix)" } ?? "—").font(.headline.monospacedDigit()) }.frame(maxWidth: .infinity, alignment: .leading) }
    private func stat(_ label: String, _ value: Int) -> some View { VStack { Text("\(value)").font(.title2.bold().monospacedDigit()); Text(label).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth: .infinity) }
}

private struct FlowLayout: View {
    let items: [MuscleGroup]; let opacity: Double
    var body: some View { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(items, id: \.self) { muscle in Text(muscle.frenchName).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 7).background(muscle.atlasColor.opacity(0.16 * opacity), in: Capsule()).foregroundStyle(muscle.atlasColor.opacity(opacity)) } } } }
}
