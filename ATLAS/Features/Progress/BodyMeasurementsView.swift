import Charts
import SwiftData
import SwiftUI

struct BodyMeasurementsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Query(sort: \BodyMeasurementRecord.measuredAt, order: .reverse)
    private var measurements: [BodyMeasurementRecord]
    @State private var selectedMetric = BodyMetricKind.weight
    @State private var showingEntry = false
    @State private var syncState = HealthMeasurementSyncState.idle

    private var selectedMeasurements: [BodyMeasurementRecord] {
        measurements.filter { $0.metric == selectedMetric }.sorted { $0.measuredAt < $1.measuredAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Mesures corporelles").font(.title2.bold())
                    Text("Chaque mesure conserve sa date et sa source.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Ajouter", systemImage: "plus.circle.fill") { showingEntry = true }
                    .labelStyle(.iconOnly).font(.title2)
            }

            healthSyncBanner

            Picker("Mesure", selection: $selectedMetric) {
                ForEach(BodyMetricKind.allCases) { metric in Text(metric.frenchName).tag(metric) }
            }
            .pickerStyle(.menu)

            AtlasCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label(selectedMetric.frenchName, systemImage: selectedMetric.symbol)
                        .font(.headline)
                    if let latest = selectedMeasurements.last {
                        Text("\(latest.value.formatted(.number.precision(.fractionLength(0...2)))) \(selectedMetric.unit)")
                            .font(.largeTitle.bold().monospacedDigit())
                        Chart(selectedMeasurements) { item in
                            LineMark(x: .value("Date", item.measuredAt), y: .value("Valeur", item.value))
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", item.measuredAt), y: .value("Valeur", item.value))
                        }
                        .foregroundStyle(AtlasTheme.accent)
                        .frame(height: 170)
                        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                    } else {
                        ContentUnavailableView(
                            "Aucune mesure",
                            systemImage: selectedMetric.symbol,
                            description: Text("Ajoutez votre première valeur de \(selectedMetric.frenchName.lowercased()).")
                        )
                    }
                }
            }

            ForEach(selectedMeasurements.reversed()) { item in
                HStack {
                    Text(item.measuredAt.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                    Text("\(item.value.formatted(.number.precision(.fractionLength(0...2)))) \(selectedMetric.unit)")
                        .fontWeight(.semibold).monospacedDigit()
                }
                .font(.subheadline)
            }
        }
        .sheet(isPresented: $showingEntry) {
            NavigationStack { BodyMeasurementEditorView(initialMetric: selectedMetric) }
        }
        .task {
            guard syncState == .idle else { return }
            await syncHealthData()
        }
    }

    private var healthSyncBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: syncState.symbol)
                .foregroundStyle(syncState.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Santé").font(.subheadline.bold())
                Text(syncState.message).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await syncHealthData() }
            } label: {
                if syncState == .syncing { ProgressView() }
                else { Image(systemName: "arrow.triangle.2.circlepath") }
            }
            .disabled(syncState == .syncing)
            .accessibilityLabel("Synchroniser avec Apple Santé")
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    @MainActor
    private func syncHealthData() async {
        syncState = .syncing
        let provider = HealthDataProviderFactory.make()
        do {
            try await provider.requestAuthorization()
            let samples = await provider.loadBodyMeasurements(since: .distantPast, now: .now)
            var known = measurements
            var imported = 0
            for sample in samples where HealthBodyMeasurementSync.shouldImport(sample, existing: known) {
                let record = BodyMeasurementRecord(
                    metric: sample.metric,
                    value: sample.value,
                    measuredAt: sample.measuredAt,
                    source: .appleHealth,
                    note: "Importé depuis \(sample.source)"
                )
                modelContext.insert(record)
                known.append(record)
                imported += 1
            }
            if imported > 0 {
                let saved = feedback.save(modelContext, action: "La synchronisation avec Apple Santé")
                syncState = saved ? .imported(imported) : .failed
            } else {
                syncState = samples.isEmpty ? .noData : .upToDate
            }
        } catch {
            feedback.report(error, action: "La synchronisation avec Apple Santé")
            syncState = .failed
        }
    }
}

private enum HealthMeasurementSyncState: Equatable {
    case idle, syncing, noData, upToDate, imported(Int), failed

    var symbol: String {
        switch self {
        case .syncing: "arrow.triangle.2.circlepath"
        case .imported, .upToDate: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        default: "heart.text.square.fill"
        }
    }

    var tint: Color {
        switch self {
        case .imported, .upToDate: AtlasTheme.success
        case .failed: AtlasTheme.warning
        default: .red
        }
    }

    var message: String {
        switch self {
        case .idle: "Prêt à importer les mesures de votre balance."
        case .syncing: "Lecture des mesures autorisées…"
        case .noData: "Aucune mesure compatible accessible. Vérifiez Santé › Partage › Apps › ATLAS."
        case .upToDate: "Toutes les mesures compatibles sont à jour."
        case .imported(let count): "\(count) nouvelle\(count > 1 ? "s" : "") mesure\(count > 1 ? "s" : "") importée\(count > 1 ? "s" : "")."
        case .failed: "Synchronisation impossible. Touchez pour réessayer."
        }
    }
}

private struct BodyMeasurementEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @State private var metric: BodyMetricKind
    @State private var value = 0.0
    @State private var date = Date.now
    @State private var source = BodyMeasurementSource.manual
    @State private var note = ""

    init(initialMetric: BodyMetricKind) { _metric = State(initialValue: initialMetric) }

    var body: some View {
        Form {
            Picker("Mesure", selection: $metric) {
                ForEach(BodyMetricKind.allCases) { Text($0.frenchName).tag($0) }
            }
            LabeledContent("Valeur") {
                TextField("0", value: $value, format: .number)
                    .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                Text(metric.unit).foregroundStyle(.secondary)
            }
            DatePicker("Date", selection: $date)
            Picker("Source", selection: $source) {
                ForEach(BodyMeasurementSource.allCases, id: \.self) { Text($0.frenchName).tag($0) }
            }
            TextField("Note (optionnelle)", text: $note, axis: .vertical)
        }
        .navigationTitle("Nouvelle mesure")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Annuler") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") {
                    modelContext.insert(BodyMeasurementRecord(metric: metric, value: value, measuredAt: date, source: source, note: note))
                    feedback.save(modelContext, action: "L’enregistrement de la mesure") { dismiss() }
                }.disabled(value <= 0)
            }
        }
    }
}
