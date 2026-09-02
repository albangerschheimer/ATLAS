import SwiftData
import SwiftUI

struct TodayView: View {
    @AppStorage("healthAccessRequested") private var healthAccessRequested = false
    @AppStorage(NutritionGoalKeys.energy) private var energyGoal = NutritionGoals.defaults.energyKilocalories
    @AppStorage(NutritionGoalKeys.protein) private var proteinGoal = NutritionGoals.defaults.proteinGrams
    @Query(
        filter: #Predicate<WorkoutRecord> { $0.stateRawValue == "draft" },
        sort: \WorkoutRecord.startedAt,
        order: .reverse
    )
    private var drafts: [WorkoutRecord]
    @Query(
        filter: #Predicate<WorkoutRecord> { $0.stateRawValue == "completed" },
        sort: \WorkoutRecord.startedAt,
        order: .reverse
    )
    private var completedWorkouts: [WorkoutRecord]
    @Query(sort: \NutritionEntryRecord.consumedAt, order: .reverse)
    private var nutritionEntries: [NutritionEntryRecord]
    @StateObject private var healthModel = HealthDashboardViewModel()

    private var draft: WorkoutRecord? { drafts.first }

    private var completedThisWeek: [WorkoutRecord] {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else { return [] }
        return completedWorkouts.filter { week.contains($0.startedAt) }
    }

    private var sportTiles: [WeeklySportTile] {
        [
            WeeklySportTile(id: "strength", title: "Musculation", icon: HealthSportKind.strength.systemImage, completed: completedThisWeek.count, target: 4),
            WeeklySportTile(id: "running", title: "Course", icon: HealthSportKind.running.systemImage, completed: count(.running), target: 1),
            WeeklySportTile(id: "cycling", title: "Vélo", icon: HealthSportKind.cycling.systemImage, completed: count(.cycling), target: 1),
            WeeklySportTile(id: "swimming", title: "Natation", icon: HealthSportKind.swimming.systemImage, completed: count(.swimming), target: 1),
            WeeklySportTile(id: "basketball", title: "Basket", icon: HealthSportKind.basketball.systemImage, completed: count(.basketball), target: nil)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AtlasTheme.sectionSpacing) {
                    header
                    trainingActionCard

                    if !healthAccessRequested || !healthModel.isHealthDataAvailable {
                        healthConnectionCard
                    }

                    readinessCard
                    AtlasSectionHeader(
                        title: "Cette semaine",
                        subtitle: "Musculation et activités synchronisées"
                    )

                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 145), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(sportTiles) { tile in
                            weeklySportTile(tile)
                        }
                    }

                    coachCard
                    recoveryCard
                    nutritionCard
                }
                .padding(.horizontal, AtlasTheme.screenPadding)
                .padding(.vertical, 16)
            }
            .background(AtlasTheme.canvas)
            .overlay {
                if healthModel.isLoading {
                    ProgressView()
                        .padding(18)
                        .background(.regularMaterial, in: Circle())
                        .accessibilityLabel("Actualisation Apple Santé")
                }
            }
            .refreshable {
                await healthModel.refresh(hasRequestedAccess: healthAccessRequested)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task(id: healthAccessRequested) {
                await healthModel.refresh(hasRequestedAccess: healthAccessRequested)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("ATLAS")
                .font(.caption.bold())
                .tracking(2.2)
                .foregroundStyle(AtlasTheme.accent)
            Text("Bonjour")
                .font(.largeTitle.bold())
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var trainingActionCard: some View {
        Button {
            NotificationCenter.default.post(name: .atlasSelectTrain, object: nil)
        } label: {
            AtlasCard(tint: draft == nil ? AtlasTheme.accent : AtlasTheme.warning) {
                HStack(spacing: 14) {
                    AtlasIconBadge(
                        systemImage: draft == nil ? "play.fill" : "arrow.clockwise",
                        tint: draft == nil ? AtlasTheme.accent : AtlasTheme.warning
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(draft == nil ? "Lancer une séance" : "Reprendre la séance")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text(draft.map { "\($0.name) · \($0.completedSetCount) séries enregistrées" } ?? "Séance libre ou programme personnalisé")
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
        .buttonStyle(.plain)
        .accessibilityIdentifier("today.workout.primaryAction")
    }

    private var healthConnectionCard: some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    AtlasIconBadge(systemImage: "heart.text.square.fill", tint: .red)
                    Text(healthModel.isHealthDataAvailable ? "Connecter Apple Santé" : "Apple Santé indisponible")
                        .font(.headline)
                }
                Text(
                    healthModel.isHealthDataAvailable
                        ? "Importez les activités, la récupération, la nutrition et les mesures de votre balance."
                        : "Le dashboard manuel reste utilisable sur cet appareil."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if healthModel.isHealthDataAvailable {
                    Button("Choisir les données Santé") {
                        Task {
                            if await healthModel.requestAccess() {
                                healthAccessRequested = true
                            }
                        }
                    }
                    .buttonStyle(AtlasPrimaryButtonStyle())
                    .accessibilityIdentifier("today.health.connect")
                }
            }
        }
    }

    private var readinessCard: some View {
        AtlasCard(tint: healthModel.readiness.map { readinessColor($0.level) }) {
            VStack(alignment: .leading, spacing: 10) {
                if let readiness = healthModel.readiness {
                    HStack(spacing: 15) {
                        ReadinessGauge(score: readiness.score, tint: readinessColor(readiness.level))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Disponibilité du jour").font(.headline)
                            AtlasStatusPill(
                                text: readiness.level.frenchName,
                                systemImage: readiness.level == .low ? "exclamationmark" : "checkmark",
                                tint: readinessColor(readiness.level)
                            )
                            Text("Confiance : \(readiness.confidence)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    ForEach(readiness.explanations, id: \.self) { explanation in
                        Text(explanation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        AtlasIconBadge(systemImage: "gauge.with.dots.needle.50percent")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Disponibilité en attente").font(.headline)
                            Text("Le sommeil reste optionnel.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text("Le score apparaîtra dès que Santé fournit une fréquence au repos récente et une référence sur plusieurs jours.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func weeklySportTile(_ tile: WeeklySportTile) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Image(systemName: tile.icon).foregroundStyle(tile.tint)
                Text(tile.title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
            }
            Text(tile.target.map { "\(tile.completed)/\($0)" } ?? "\(tile.completed)")
                .font(.title.bold().monospacedDigit())
                .foregroundStyle(tile.reachedTarget ? AtlasTheme.success : .primary)
            if let target = tile.target {
                ProgressView(value: min(Double(tile.completed) / Double(max(target, 1)), 1))
                    .tint(tile.reachedTarget ? AtlasTheme.success : tile.tint)
            }
            Text(tile.target == nil ? "séance(s) détectée(s)" : "objectif hebdomadaire")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(AtlasTheme.surface, in: RoundedRectangle(cornerRadius: AtlasTheme.compactCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AtlasTheme.compactCornerRadius, style: .continuous)
                .stroke(tile.tint.opacity(0.12), lineWidth: 0.75)
        }
        .accessibilityElement(children: .combine)
    }

    private var recoveryCard: some View {
        AtlasCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Récupération et activité", systemImage: "waveform.path.ecg")
                    .font(.headline)
                healthMetricRow("Sommeil", icon: "bed.double.fill", metric: healthModel.snapshot[.sleep], decimals: 1)
                healthMetricRow("Fréquence au repos", icon: "heart.fill", metric: healthModel.snapshot[.restingHeartRate], decimals: 0)
                healthMetricRow("Pas aujourd’hui", icon: "figure.walk", metric: healthModel.snapshot[.steps], decimals: 0)
                healthMetricRow("Énergie active", icon: "flame.fill", metric: healthModel.snapshot[.activeEnergy], decimals: 0)
            }
        }
    }

    private var nutritionCard: some View {
        let totals = NutritionSummaryCalculator.totals(
            for: .now,
            healthDays: healthModel.snapshot.nutritionDays,
            localEntries: nutritionEntries
        )
        let sources = healthModel.snapshot.nutritionDays
            .first(where: { Calendar.current.isDateInToday($0.day) })?
            .sources ?? []
        let availableMetrics = NutritionSummaryCalculator.availableMetrics(
            for: .now,
            healthDays: healthModel.snapshot.nutritionDays,
            localEntries: nutritionEntries
        )
        let hasLocalEntry = nutritionEntries.contains { Calendar.current.isDateInToday($0.consumedAt) }

        return AtlasCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Nutrition", systemImage: "fork.knife")
                        .font(.headline)
                    Spacer()
                    Text(sources.isEmpty ? (hasLocalEntry ? "ATLAS" : "Aucune donnée") : sources.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                nutritionProgress(
                    "Calories",
                    value: availableMetrics.contains(.dietaryEnergy) ? totals.energyKilocalories : nil,
                    goal: energyGoal,
                    unit: "kcal",
                    color: AtlasTheme.accent
                )
                nutritionProgress(
                    "Protéines",
                    value: availableMetrics.contains(.dietaryProtein) ? totals.proteinGrams : nil,
                    goal: proteinGoal,
                    unit: "g",
                    color: .blue
                )
                Text("Détails, objectifs et scanner dans Profile → Nutrition.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func nutritionProgress(
        _ title: String,
        value: Double?,
        goal: Double,
        unit: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(value.map { "\($0.formatted(.number.precision(.fractionLength(0)))) / \(goal.formatted(.number.precision(.fractionLength(0)))) \(unit)" } ?? "—")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }
            ProgressView(value: goal > 0 ? min((value ?? 0) / goal, 1) : 0)
                .tint(color)
        }
        .accessibilityElement(children: .combine)
    }

    private func healthMetricRow(
        _ title: String,
        icon: String,
        metric: HealthMetricValue,
        decimals: Int
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(AtlasTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                if let source = metric.source, metric.availability == .available {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(metricText(metric, decimals: decimals))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private var coachCard: some View {
        NavigationLink {
            AtlasCoachView(context: coachContext, insights: coachInsights)
        } label: {
            AtlasCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Label("Coach ATLAS", systemImage: "sparkles").font(.headline); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.tertiary) }
                    Text(coachInsights.first?.message ?? coachMessage).foregroundStyle(.secondary)
                    Text(AtlasOnDeviceCoach.availability().usesAppleIntelligence
                         ? "Analyse locale + conversation Apple Intelligence active."
                         : "Analyse locale active. L’état d’Apple Intelligence est visible dans le coach.")
                        .font(.caption).foregroundStyle(.tertiary)
                }
            }
        }.buttonStyle(.plain)
    }

    private var coachContext: AtlasCoachContext {
        let nutrition = NutritionSummaryCalculator.totals(for: .now, healthDays: healthModel.snapshot.nutritionDays, localEntries: nutritionEntries)
        return AtlasCoachContext(
            readinessScore: healthModel.readiness?.score,
            restingHeartRate: healthModel.snapshot[.restingHeartRate].value,
            restingBaseline: healthModel.snapshot[.restingHeartRateBaseline].value,
            sleepHours: healthModel.snapshot[.sleep].value,
            strengthSessionsThisWeek: completedThisWeek.count,
            enduranceSessionsThisWeek: count(.running) + count(.cycling) + count(.swimming) + count(.basketball),
            trainingDays: completedThisWeek.map(\.startedAt) + healthModel.snapshot.workouts.map(\.startedAt),
            proteinToday: nutrition.proteinGrams > 0 ? nutrition.proteinGrams : nil,
            proteinGoal: proteinGoal,
            currentHour: Calendar.current.component(.hour, from: .now)
        )
    }

    private var coachInsights: [AtlasCoachInsight] { AtlasCoachEngine.insights(for: coachContext) }

    private var coachMessage: String {
        if let readiness = healthModel.readiness, readiness.level == .low {
            return "Les signaux de récupération disponibles sont bas. Privilégiez une séance technique ou réduisez l’intensité, puis décidez vous-même de l’adaptation."
        }
        if !healthAccessRequested {
            return "Connectez Apple Santé pour mettre en contexte la musculation avec la course, le vélo, la natation, le basket et la récupération."
        }
        let enduranceCount = count(.running) + count(.cycling) + count(.swimming) + count(.basketball)
        if completedThisWeek.count >= 4 && enduranceCount >= 2 {
            return "Semaine déjà dense : \(completedThisWeek.count) séances de musculation et \(enduranceCount) activités complémentaires détectées. Gardez une journée légère si la fatigue monte."
        }
        if healthModel.snapshot.workouts.isEmpty {
            return "Aucune activité compatible n’est disponible cette semaine dans Apple Santé. Vérifiez la synchronisation Mi Fitness ou enregistrez vos sports manuellement."
        }
        return "La semaine combine \(completedThisWeek.count) séance(s) de musculation et \(enduranceCount) activité(s) complémentaires. Les prochaines alertes utiliseront aussi votre calendrier."
    }

    private func count(_ sport: HealthSportKind) -> Int {
        healthModel.snapshot.workouts.filter { $0.sport == sport }.count
    }

    private func metricText(_ metric: HealthMetricValue, decimals: Int) -> String {
        guard metric.availability == .available, let value = metric.value else {
            switch metric.availability {
            case .permissionNotRequested: return "Non connecté"
            case .noData: return "Aucune donnée"
            case .healthUnavailable: return "Indisponible"
            case .failed: return "Lecture impossible"
            case .available: return "Aucune donnée"
            }
        }
        return "\(value.formatted(.number.precision(.fractionLength(decimals)))) \(metric.unit)"
    }

    private func readinessColor(_ level: ReadinessResult.Level) -> Color {
        switch level {
        case .high: AtlasTheme.success
        case .moderate: AtlasTheme.warning
        case .low: .red
        }
    }
}

private struct WeeklySportTile: Identifiable {
    let id: String
    let title: String
    let icon: String
    let completed: Int
    let target: Int?

    var reachedTarget: Bool {
        guard let target else { return completed > 0 }
        return completed >= target
    }

    var tint: Color {
        switch id {
        case "strength": AtlasTheme.accent
        case "running": .orange
        case "cycling": .green
        case "swimming": .cyan
        case "basketball": .brown
        default: AtlasTheme.accent
        }
    }
}

private struct ReadinessGauge: View {
    let score: Int
    let tint: Color

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.13), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(Double(score) / 100, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)").font(.title2.bold().monospacedDigit())
        }
        .frame(width: 76, height: 76)
        .accessibilityLabel("Disponibilité \(score) sur 100")
    }
}
