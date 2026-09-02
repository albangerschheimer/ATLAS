import SwiftData
import SwiftUI
import Charts

struct SportsCalendarView: View {
    @AppStorage("healthAccessRequested") private var healthAccessRequested = false
    @Query(
        filter: #Predicate<WorkoutRecord> { $0.stateRawValue == "completed" },
        sort: \WorkoutRecord.startedAt,
        order: .reverse
    )
    private var completedWorkouts: [WorkoutRecord]
    @StateObject private var healthModel = HealthDashboardViewModel()
    @State private var selectedDate = Date.now

    private var calendar: Calendar { .current }

    private var week: DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: selectedDate)
            ?? DateInterval(start: calendar.startOfDay(for: selectedDate), duration: 7 * 86_400)
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }
    }

    private var selectedActivities: [SportsCalendarActivity] {
        let local = completedWorkouts
            .filter { calendar.isDate($0.startedAt, inSameDayAs: selectedDate) }
            .map(SportsCalendarActivity.init)
        let health = healthModel.snapshot.workouts
            .filter { calendar.isDate($0.startedAt, inSameDayAs: selectedDate) }
            .map(SportsCalendarActivity.init)
        return (local + health).sorted { $0.startedAt < $1.startedAt }
    }

    private var weeklyMuscles: [WeeklyMuscleShare] {
        var counts: [MuscleGroup: Double] = [:]
        for workout in completedWorkouts where week.contains(workout.startedAt) {
            for entry in workout.exercises {
                let muscles = entry.exercise?.primaryMuscles.compactMap(MuscleGroup.init) ?? []
                let setCount = Double(entry.sets.filter { $0.isCompleted && $0.kind == .working }.count)
                guard setCount > 0, !muscles.isEmpty else { continue }
                for muscle in muscles { counts[muscle, default: 0] += setCount / Double(muscles.count) }
            }
        }
        let total = counts.values.reduce(0, +)
        return counts.map { WeeklyMuscleShare(muscle: $0.key, percentage: total > 0 ? $0.value / total * 100 : 0) }.sorted { $0.percentage > $1.percentage }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    weekHeader
                    dayPicker
                }

                if !weeklyMuscles.isEmpty {
                    Section("Répartition musculaire de la semaine") {
                        HStack(spacing: 20) {
                            Chart(weeklyMuscles) { item in
                                SectorMark(angle: .value("Part", item.percentage), innerRadius: .ratio(0.66), angularInset: 2)
                                    .cornerRadius(3)
                                    .foregroundStyle(item.muscle.atlasColor)
                            }
                            .frame(width: 130, height: 130)
                            .chartBackground { _ in
                                VStack(spacing: 1) {
                                    Text("\(weeklyMuscles.count)")
                                        .font(.title3.bold().monospacedDigit())
                                    Text("zones")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(weeklyMuscles.prefix(5)) { item in
                                    HStack {
                                        Circle().fill(item.muscle.atlasColor).frame(width: 8, height: 8)
                                        Text(item.muscle.frenchName).font(.caption)
                                        Spacer()
                                        Text("\(item.percentage.formatted(.number.precision(.fractionLength(0)))) %").font(.caption.bold().monospacedDigit())
                                    }
                                }
                            }
                        }.padding(.vertical, 4)
                    }
                }

                Section(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                    if selectedActivities.isEmpty {
                        ContentUnavailableView(
                            "Aucune activité",
                            systemImage: "calendar",
                            description: Text("Les séances terminées et les sports Apple Santé apparaîtront ici.")
                        )
                    } else {
                        ForEach(selectedActivities) { activity in
                            activityRow(activity)
                        }
                    }
                }

                if !healthAccessRequested {
                    Section("Sources externes") {
                        NavigationLink {
                            HealthSettingsView()
                        } label: {
                            Label("Connecter Strava et Mi Fitness via Apple Santé", systemImage: "heart.text.square")
                        }
                    }
                } else if let error = healthModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.canvas)
            .navigationTitle("Calendrier")
            .overlay {
                if healthModel.isLoading {
                    ProgressView()
                        .padding(16)
                        .background(.regularMaterial, in: Circle())
                }
            }
            .task(id: week.start) {
                await healthModel.refresh(hasRequestedAccess: healthAccessRequested, now: selectedDate)
            }
            .refreshable {
                await healthModel.refresh(hasRequestedAccess: healthAccessRequested, now: selectedDate)
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button {
                moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .accessibilityLabel("Semaine précédente")

            Spacer()
            Text(weekTitle)
                .font(.headline)
            Spacer()

            Button {
                moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .accessibilityLabel("Semaine suivante")
        }
        .buttonStyle(.plain)
    }

    private var dayPicker: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                let selected = calendar.isDate(day, inSameDayAs: selectedDate)
                Button {
                    selectedDate = day
                } label: {
                    VStack(spacing: 5) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2.weight(.semibold))
                        Text(day.formatted(.dateTime.day()))
                            .font(.headline.monospacedDigit())
                        Circle()
                            .fill(hasActivity(on: day) ? (selected ? Color.white : AtlasTheme.accent) : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .foregroundStyle(selected ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selected ? AtlasTheme.accent : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.formatted(.dateTime.weekday(.wide).day().month()))
            }
        }
    }

    private func activityRow(_ activity: SportsCalendarActivity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AtlasIconBadge(
                systemImage: activity.sport.systemImage,
                tint: activityTint(activity.sport)
            )
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(activity.title)
                        .font(.headline)
                    Spacer()
                    Text(activity.startedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(activity.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(activity.sources.joined(separator: " + "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var weekTitle: String {
        let end = week.end.addingTimeInterval(-1)
        if calendar.component(.month, from: week.start) == calendar.component(.month, from: end) {
            return week.start.formatted(.dateTime.month(.wide).year())
        }
        return "\(week.start.formatted(.dateTime.day().month(.abbreviated))) – \(end.formatted(.dateTime.day().month(.abbreviated)))"
    }

    private func hasActivity(on day: Date) -> Bool {
        completedWorkouts.contains { calendar.isDate($0.startedAt, inSameDayAs: day) }
            || healthModel.snapshot.workouts.contains { calendar.isDate($0.startedAt, inSameDayAs: day) }
    }

    private func moveWeek(by offset: Int) {
        guard let moved = calendar.date(byAdding: .weekOfYear, value: offset, to: selectedDate) else { return }
        selectedDate = moved
    }

    private func activityTint(_ sport: HealthSportKind) -> Color {
        switch sport {
        case .strength: AtlasTheme.accent
        case .running: .orange
        case .cycling: .green
        case .swimming: .cyan
        case .basketball: .brown
        case .other: .secondary
        }
    }
}

private struct WeeklyMuscleShare: Identifiable {
    let muscle: MuscleGroup
    let percentage: Double
    var id: MuscleGroup { muscle }
}

private struct SportsCalendarActivity: Identifiable {
    let id: String
    let title: String
    let sport: HealthSportKind
    let startedAt: Date
    let durationSeconds: TimeInterval
    let distanceMeters: Double?
    let energyKilocalories: Double?
    let sources: [String]

    init(_ workout: WorkoutRecord) {
        id = "atlas-\(workout.id.uuidString)"
        title = workout.name
        sport = .strength
        startedAt = workout.startedAt
        durationSeconds = workout.duration
        distanceMeters = nil
        energyKilocalories = nil
        sources = ["ATLAS"]
    }

    init(_ workout: HealthWorkoutValue) {
        id = "health-\(workout.id.uuidString)"
        title = workout.sport.frenchName
        sport = workout.sport
        startedAt = workout.startedAt
        durationSeconds = workout.durationSeconds
        distanceMeters = workout.distanceMeters
        energyKilocalories = workout.energyKilocalories
        sources = workout.contributingSources
    }

    var summary: String {
        var parts = [Duration.seconds(durationSeconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))]
        if let distanceMeters {
            parts.append("\((distanceMeters / 1_000).formatted(.number.precision(.fractionLength(1)))) km")
        }
        if let energyKilocalories {
            parts.append("\(energyKilocalories.formatted(.number.precision(.fractionLength(0)))) kcal")
        }
        return parts.joined(separator: " · ")
    }
}
