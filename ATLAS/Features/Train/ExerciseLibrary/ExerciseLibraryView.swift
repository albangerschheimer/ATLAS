import SwiftData
import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Query(sort: \ExerciseRecord.nameFrench)
    private var exercises: [ExerciseRecord]
    @State private var searchText = ""
    @State private var showingNewExercise = false
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedEquipment: EquipmentKind?
    @State private var favoritesOnly = false

    private var filteredExercises: [ExerciseRecord] {
        let query = searchText.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        return exercises.filter { exercise in
            let matchesSearch: Bool
            if query.isEmpty {
                matchesSearch = true
            } else {
                let searchable = ([exercise.nameFrench, exercise.nameEnglish, exercise.equipment.frenchName, exercise.muscleSummary] + exercise.aliases)
                .joined(separator: " ")
                .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                matchesSearch = searchable.contains(query)
            }
            let matchesMuscle = selectedMuscle.map {
                exercise.primaryMuscles.contains($0.rawValue) || exercise.secondaryMuscles.contains($0.rawValue)
            } ?? true
            let matchesEquipment = selectedEquipment.map { exercise.equipment == $0 } ?? true
            return matchesSearch && matchesMuscle && matchesEquipment && (!favoritesOnly || exercise.isFavorite)
        }
    }

    private var hasActiveFilters: Bool {
        selectedMuscle != nil || selectedEquipment != nil || favoritesOnly
    }

    var body: some View {
        List {
            Section("Explorer") {
                NavigationLink {
                    MuscleCatalogView()
                } label: {
                    HStack(spacing: 16) {
                        AnatomyMapView(muscles: [.fullBody])
                            .frame(width: 92, height: 92)
                            .padding(4)
                            .background(AtlasTheme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Explorer par muscle")
                                .font(.headline)
                            Text("Bras, dos, jambes, abdominaux… puis choisis le muscle précis.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityIdentifier("exercise.library.muscleBrowser")
            }

            Section {
                TextField("Rechercher un exercice", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("exercise.library.search")
                LabeledContent("Résultats", value: "\(filteredExercises.count) / \(exercises.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if filteredExercises.isEmpty {
                ContentUnavailableView(
                    "Aucun exercice",
                    systemImage: "magnifyingglass",
                    description: Text("Modifiez la recherche ou créez un exercice personnalisé.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(filteredExercises) { exercise in
                    NavigationLink {
                        ExerciseDetailView(exercise: exercise)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: exercise.isFavorite ? "star.fill" : "dumbbell")
                                .frame(width: 28)
                                .foregroundStyle(exercise.isFavorite ? .yellow : AtlasTheme.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(exercise.displayName)
                                Text("\(exercise.muscleSummary) · \(exercise.equipment.frenchName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            exercise.isFavorite.toggle()
                            feedback.save(modelContext, action: "La modification du favori")
                        } label: {
                            Label("Favori", systemImage: "star")
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
        .navigationTitle("Exercices")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Toggle("Favoris uniquement", isOn: $favoritesOnly)
                    Picker("Muscle", selection: $selectedMuscle) {
                        Text("Tous les muscles").tag(nil as MuscleGroup?)
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Text(muscle.frenchName).tag(muscle as MuscleGroup?)
                        }
                    }
                    Picker("Équipement", selection: $selectedEquipment) {
                        Text("Tous les équipements").tag(nil as EquipmentKind?)
                        ForEach(EquipmentKind.allCases, id: \.self) { equipment in
                            Text(equipment.frenchName).tag(equipment as EquipmentKind?)
                        }
                    }
                    if hasActiveFilters {
                        Button("Réinitialiser les filtres", role: .destructive) {
                            selectedMuscle = nil
                            selectedEquipment = nil
                            favoritesOnly = false
                        }
                    }
                } label: {
                    Label("Filtrer", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Ajouter", systemImage: "plus") {
                    showingNewExercise = true
                }
                .accessibilityIdentifier("exercise.new")
            }
        }
        .sheet(isPresented: $showingNewExercise) {
            NavigationStack {
                NewExerciseView()
            }
        }
    }
}

struct ExerciseEditView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var exercise: ExerciseRecord

    var body: some View {
        Form {
            Section("Identité") {
                TextField("Nom français", text: $exercise.nameFrench)
                TextField("Nom anglais", text: $exercise.nameEnglish)
            }

            Section("Classification") {
                Picker("Équipement", selection: Binding(
                    get: { exercise.equipment },
                    set: { exercise.equipment = $0 }
                )) {
                    ForEach(EquipmentKind.allCases, id: \.self) { equipment in
                        Text(equipment.frenchName).tag(equipment)
                    }
                }
                Picker("Catégorie", selection: Binding(
                    get: { exercise.category },
                    set: { exercise.category = $0 }
                )) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { category in
                        Text(category.frenchName).tag(category)
                    }
                }
                LabeledContent("Muscles", value: exercise.muscleSummary)
            }

            Toggle("Favori", isOn: $exercise.isFavorite)
        }
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            feedback.save(modelContext, action: "La modification de l’exercice")
        }
    }
}

struct NewExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @State private var nameFrench = ""
    @State private var nameEnglish = ""
    @State private var primaryMuscle = MuscleGroup.chest
    @State private var equipment = EquipmentKind.dumbbell
    @State private var category = ExerciseCategory.hypertrophy

    var body: some View {
        Form {
            Section("Nom") {
                TextField("Français", text: $nameFrench)
                    .accessibilityIdentifier("exercise.name.fr")
                TextField("Anglais (optionnel)", text: $nameEnglish)
            }
            Section("Classification") {
                Picker("Muscle principal", selection: $primaryMuscle) {
                    ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                        Text(muscle.frenchName).tag(muscle)
                    }
                }
                Picker("Équipement", selection: $equipment) {
                    ForEach(EquipmentKind.allCases, id: \.self) { item in
                        Text(item.frenchName).tag(item)
                    }
                }
                Picker("Catégorie", selection: $category) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { item in
                        Text(item.frenchName).tag(item)
                    }
                }
            }
        }
        .navigationTitle("Nouvel exercice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Ajouter") {
                    let exercise = ExerciseRecord(
                        nameFrench: nameFrench.trimmingCharacters(in: .whitespacesAndNewlines),
                        nameEnglish: nameEnglish.trimmingCharacters(in: .whitespacesAndNewlines),
                        primaryMuscles: [primaryMuscle],
                        equipment: equipment,
                        category: category,
                        isCustom: true
                    )
                    modelContext.insert(exercise)
                    feedback.save(modelContext, action: "La création de l’exercice") {
                        dismiss()
                    }
                }
                .disabled(nameFrench.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("exercise.save")
            }
        }
    }
}
