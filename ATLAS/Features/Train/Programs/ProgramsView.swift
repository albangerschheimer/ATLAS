import SwiftData
import SwiftUI

struct ProgramsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Query(sort: \ProgramRecord.createdAt, order: .reverse)
    private var programs: [ProgramRecord]
    @State private var showingCreateProgram = false
    @State private var programPendingDeletion: ProgramRecord?

    var body: some View {
        List {
            if programs.isEmpty {
                ContentUnavailableView(
                    "Aucun programme",
                    systemImage: "list.bullet.clipboard",
                    description: Text("Créez une structure qui correspond réellement à votre semaine.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(programs) { program in
                    NavigationLink {
                        ProgramDetailView(program: program)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(program.name)
                                .font(.headline)
                            Text("\(program.days.count) jour\(program.days.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            duplicate(program)
                        } label: {
                            Label("Dupliquer", systemImage: "plus.square.on.square")
                        }
                        .tint(AtlasTheme.accent)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            programPendingDeletion = program
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button("Dupliquer", systemImage: "plus.square.on.square") {
                            duplicate(program)
                        }
                    }
                }
            }
        }
        .navigationTitle("Programmes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Créer", systemImage: "plus") {
                    showingCreateProgram = true
                }
                .accessibilityIdentifier("program.new")
            }
        }
        .sheet(isPresented: $showingCreateProgram) {
            NavigationStack {
                CreateProgramView()
            }
        }
        .alert(
            "Supprimer ce programme ?",
            isPresented: Binding(
                get: { programPendingDeletion != nil },
                set: { if !$0 { programPendingDeletion = nil } }
            )
        ) {
            Button("Supprimer", role: .destructive) {
                guard let programPendingDeletion else { return }
                modelContext.delete(programPendingDeletion)
                feedback.save(modelContext, action: "La suppression du programme") {
                    self.programPendingDeletion = nil
                }
            }
            Button("Annuler", role: .cancel) {
                programPendingDeletion = nil
            }
        } message: {
            Text("Les jours et prescriptions associés seront également supprimés. L’historique des séances reste intact.")
        }
    }

    private func duplicate(_ program: ProgramRecord) {
        modelContext.insert(program.duplicated())
        feedback.save(modelContext, action: "La duplication du programme")
    }
}

private struct CreateProgramView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @State private var name = ""
    @State private var details = ""

    var body: some View {
        Form {
            TextField("Nom (ex. Upper / Lower)", text: $name)
                .accessibilityIdentifier("program.name")
            TextField("Description optionnelle", text: $details, axis: .vertical)
                .lineLimit(2...4)
        }
        .navigationTitle("Nouveau programme")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Créer") {
                    modelContext.insert(ProgramRecord(name: name, details: details))
                    feedback.save(modelContext, action: "La création du programme") {
                        dismiss()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("program.save")
            }
        }
    }
}

struct ProgramDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var program: ProgramRecord
    @State private var showingNewDay = false

    var body: some View {
        List {
            if !program.details.isEmpty {
                Section {
                    Text(program.details)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Jours") {
                if program.orderedDays.isEmpty {
                    Text("Ajoutez le premier jour du programme.")
                        .foregroundStyle(.secondary)
                }

                ForEach(program.orderedDays) { day in
                    NavigationLink {
                        ProgramDayDetailView(day: day)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.name)
                            Text("\(day.exercises.count) exercice\(day.exercises.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    let ordered = program.orderedDays
                    offsets.map { ordered[$0] }.forEach(modelContext.delete)
                    feedback.save(modelContext, action: "La suppression du jour")
                }

                Button("Ajouter un jour", systemImage: "plus") {
                    showingNewDay = true
                }
                .accessibilityIdentifier("program.day.new")
            }
        }
        .navigationTitle(program.name)
        .toolbar {
            EditButton()
        }
        .sheet(isPresented: $showingNewDay) {
            NavigationStack {
                CreateProgramDayView(program: program)
            }
        }
    }
}

private struct CreateProgramDayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    let program: ProgramRecord
    @State private var name = ""

    var body: some View {
        Form {
            TextField("Nom (ex. Upper A)", text: $name)
                .accessibilityIdentifier("program.day.name")
        }
        .navigationTitle("Nouveau jour")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Ajouter") {
                    let day = ProgramDayRecord(name: name, sortIndex: program.days.count)
                    program.days.append(day)
                    feedback.save(modelContext, action: "La création du jour") {
                        dismiss()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityIdentifier("program.day.save")
            }
        }
    }
}

struct ProgramDayDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var day: ProgramDayRecord
    @State private var showingExercisePicker = false
    @State private var workoutToOpen: WorkoutRecord?

    var body: some View {
        List {
            Section {
                Button {
                    guard let program = day.program else { return }
                    let workout = WorkoutRecord.from(program: program, day: day)
                    modelContext.insert(workout)
                    feedback.save(modelContext, action: "La création de la séance") {
                        workoutToOpen = workout
                    }
                } label: {
                    Label("Démarrer cette séance", systemImage: "play.fill")
                        .font(.headline)
                }
                .disabled(day.exercises.isEmpty || day.program == nil)
                .accessibilityIdentifier("program.day.start")
            }

            Section("Prescriptions") {
                if day.orderedExercises.isEmpty {
                    Text("Ajoutez les exercices dans l’ordre prévu.")
                        .foregroundStyle(.secondary)
                }

                ForEach(day.orderedExercises) { prescription in
                    ProgramExerciseEditor(prescription: prescription)
                }
                .onDelete { offsets in
                    let ordered = day.orderedExercises
                    offsets.map { ordered[$0] }.forEach(modelContext.delete)
                    feedback.save(modelContext, action: "La suppression de la prescription")
                }

                Button("Ajouter un exercice", systemImage: "plus") {
                    showingExercisePicker = true
                }
                .accessibilityIdentifier("program.day.exercise.add")
            }
        }
        .navigationTitle(day.name)
        .toolbar { EditButton() }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView(title: "Ajouter au programme") { exercise in
                let prescription = ProgramExerciseRecord(
                    exercise: exercise,
                    sortIndex: day.exercises.count
                )
                day.exercises.append(prescription)
                feedback.save(modelContext, action: "L’ajout de l’exercice au programme")
            }
        }
        .fullScreenCover(item: $workoutToOpen) { workout in
            NavigationStack {
                WorkoutEditorView(workout: workout)
            }
        }
    }
}

private struct ProgramExerciseEditor: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var feedback: AppFeedback
    @Bindable var prescription: ProgramExerciseRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(prescription.displayName).font(.headline)
                Spacer()
                if let exercise = prescription.exercise {
                    NavigationLink { ExerciseDetailView(exercise: exercise) } label: { Image(systemName: "info.circle") }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Informations sur \(prescription.displayName)")
                }
            }

            HStack {
                CompactIntegerField(label: "Séries", value: $prescription.setCount)
                CompactIntegerField(label: "Reps min", value: $prescription.minimumRepetitions)
                CompactIntegerField(label: "Reps max", value: $prescription.maximumRepetitions)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("RIR cible")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("RIR", value: $prescription.targetRIR, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                CompactIntegerField(label: "Repos (s)", value: $prescription.restSeconds)
            }
        }
        .padding(.vertical, 6)
        .onDisappear {
            feedback.save(modelContext, action: "La modification de la prescription")
        }
    }
}

private struct CompactIntegerField: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(label, value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}
