import SwiftData
import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ExerciseRecord.nameFrench)
    private var exercises: [ExerciseRecord]
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup?
    @State private var selectedEquipment: EquipmentKind?

    let title: String
    let onSelect: (ExerciseRecord) -> Void

    private var filteredExercises: [ExerciseRecord] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.nameFrench.localizedCaseInsensitiveContains(searchText)
                || exercise.nameEnglish.localizedCaseInsensitiveContains(searchText)
                || exercise.equipment.frenchName.localizedCaseInsensitiveContains(searchText)
                || exercise.muscleSummary.localizedCaseInsensitiveContains(searchText)
                || exercise.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchesMuscle = selectedMuscle.map {
                exercise.primaryMuscles.contains($0.rawValue) || exercise.secondaryMuscles.contains($0.rawValue)
            } ?? true
            let matchesEquipment = selectedEquipment.map { exercise.equipment == $0 } ?? true
            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Rechercher un exercice", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("exercise.picker.search")
                    LabeledContent("Résultats", value: "\(filteredExercises.count) / \(exercises.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    ForEach(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.displayName)
                                        .foregroundStyle(.primary)
                                    Text("\(exercise.muscleSummary) · \(exercise.equipment.frenchName)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(AtlasTheme.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
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
                    } label: {
                        Label("Filtrer", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}
