import SwiftData
import SwiftUI

struct AnatomyMapView: View {
    let muscles: [MuscleGroup]
    var tint: Color = AtlasTheme.accent

    private var accessibilityName: String {
        if muscles.contains(.fullBody) {
            return MuscleGroup.fullBody.frenchName
        }
        return muscles.map(\.frenchName).joined(separator: ", ")
    }

    var body: some View {
        ZStack {
            Image("AnatomyBase")
                .resizable()
                .scaledToFit()

            MuscleHighlightShape(muscles: Set(muscles))
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.95), tint.opacity(0.58)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .mask {
                    Image("AnatomyBase")
                        .resizable()
                        .scaledToFit()
                }
                .shadow(color: tint.opacity(0.45), radius: 5)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zone musculaire : \(accessibilityName)")
    }
}

private struct MuscleHighlightShape: Shape {
    let muscles: Set<MuscleGroup>

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let selected = resolvedMuscles

        func ellipse(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) {
            path.addEllipse(in: CGRect(
                x: rect.minX + (x - width / 2) * rect.width,
                y: rect.minY + (y - height / 2) * rect.height,
                width: width * rect.width,
                height: height * rect.height
            ))
        }

        func roundedRect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, radius: CGFloat = 0.02) {
            path.addRoundedRect(
                in: CGRect(
                    x: rect.minX + (x - width / 2) * rect.width,
                    y: rect.minY + (y - height / 2) * rect.height,
                    width: width * rect.width,
                    height: height * rect.height
                ),
                cornerSize: CGSize(width: radius * rect.width, height: radius * rect.height)
            )
        }

        if selected.contains(.chest) {
            ellipse(0.218, 0.232, 0.108, 0.085)
            ellipse(0.326, 0.232, 0.108, 0.085)
        }
        if selected.contains(.shoulders) {
            ellipse(0.151, 0.219, 0.072, 0.090)
            ellipse(0.397, 0.219, 0.072, 0.090)
            ellipse(0.620, 0.220, 0.069, 0.088)
            ellipse(0.825, 0.220, 0.069, 0.088)
        }
        if selected.contains(.biceps) {
            ellipse(0.137, 0.316, 0.050, 0.118)
            ellipse(0.413, 0.316, 0.050, 0.118)
        }
        if selected.contains(.triceps) {
            ellipse(0.592, 0.322, 0.046, 0.125)
            ellipse(0.856, 0.322, 0.046, 0.125)
        }
        if selected.contains(.forearms) {
            ellipse(0.102, 0.420, 0.047, 0.150)
            ellipse(0.448, 0.420, 0.047, 0.150)
            ellipse(0.558, 0.420, 0.043, 0.148)
            ellipse(0.894, 0.420, 0.043, 0.148)
        }
        if selected.contains(.lats) {
            ellipse(0.662, 0.327, 0.092, 0.190)
            ellipse(0.781, 0.327, 0.092, 0.190)
        }
        if selected.contains(.upperBack) {
            ellipse(0.722, 0.265, 0.190, 0.115)
        }
        if selected.contains(.traps) {
            ellipse(0.722, 0.173, 0.150, 0.110)
        }
        if selected.contains(.lowerBack) {
            roundedRect(0.722, 0.408, 0.137, 0.125, radius: 0.035)
        }
        if selected.contains(.core) {
            roundedRect(0.273, 0.355, 0.112, 0.166, radius: 0.035)
        }
        if selected.contains(.obliques) {
            ellipse(0.207, 0.371, 0.055, 0.160)
            ellipse(0.339, 0.371, 0.055, 0.160)
        }
        if selected.contains(.glutes) {
            ellipse(0.675, 0.517, 0.108, 0.107)
            ellipse(0.774, 0.517, 0.108, 0.107)
        }
        if selected.contains(.abductors) {
            ellipse(0.633, 0.558, 0.062, 0.130)
            ellipse(0.816, 0.558, 0.062, 0.130)
        }
        if selected.contains(.quadriceps) {
            ellipse(0.222, 0.621, 0.085, 0.205)
            ellipse(0.326, 0.621, 0.085, 0.205)
        }
        if selected.contains(.hamstrings) {
            ellipse(0.679, 0.627, 0.078, 0.210)
            ellipse(0.770, 0.627, 0.078, 0.210)
        }
        if selected.contains(.adductors) {
            ellipse(0.252, 0.613, 0.049, 0.190)
            ellipse(0.296, 0.613, 0.049, 0.190)
        }
        if selected.contains(.calves) {
            ellipse(0.223, 0.795, 0.064, 0.190)
            ellipse(0.328, 0.795, 0.064, 0.190)
            ellipse(0.681, 0.795, 0.069, 0.190)
            ellipse(0.772, 0.795, 0.069, 0.190)
        }

        return path
    }

    private var resolvedMuscles: Set<MuscleGroup> {
        var result = muscles
        if result.contains(.back) {
            result.formUnion([.lats, .upperBack, .traps, .lowerBack])
        }
        if result.contains(.fullBody) {
            result.formUnion(MuscleGroup.allCases.filter { $0 != .fullBody && $0 != .back })
        }
        return result
    }
}

struct MuscleCatalogView: View {
    @Query private var exercises: [ExerciseRecord]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                AtlasCard {
                    HStack(spacing: 16) {
                        AnatomyMapView(muscles: [.fullBody])
                            .frame(width: 116, height: 116)
                        VStack(alignment: .leading, spacing: 7) {
                            Label("Carte musculaire", systemImage: "figure.strengthtraining.traditional")
                                .font(.headline)
                                .foregroundStyle(AtlasTheme.accent)
                            Text("Choisis une zone, puis le muscle précis que tu veux travailler.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Zones du corps")
                        .font(.title2.bold())

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MuscleRegion.allCases) { region in
                            NavigationLink {
                                MuscleRegionDetailView(region: region)
                            } label: {
                                MuscleRegionCard(
                                    region: region,
                                    exerciseCount: exerciseCount(for: region.filterMuscles)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("muscle.region.\(region.rawValue)")
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Carte musculaire")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("muscle.browser")
    }

    private func exerciseCount(for muscles: [MuscleGroup]) -> Int {
        exercises.count { $0.involves(anyOf: muscles) }
    }
}

private struct MuscleRegionCard: View {
    let region: MuscleRegion
    let exerciseCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AnatomyMapView(muscles: region.subcategories)
                .frame(maxWidth: .infinity)
                .frame(height: 132)
            Text(region.frenchName)
                .font(.headline)
            Text("\(exerciseCount) exercice\(exerciseCount > 1 ? "s" : "")")
                .font(.caption.weight(.medium))
                .foregroundStyle(AtlasTheme.accent)
            Text(region.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(minHeight: 30, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AtlasTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AtlasTheme.cardCornerRadius)
                .stroke(AtlasTheme.accent.opacity(0.12), lineWidth: 1)
        }
    }
}

struct MuscleRegionDetailView: View {
    @Query private var exercises: [ExerciseRecord]
    let region: MuscleRegion

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    AnatomyMapView(muscles: region.subcategories)
                        .frame(height: 230)
                    Text(region.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section("Sous-catégories") {
                ForEach(region.subcategories, id: \.self) { muscle in
                    NavigationLink {
                        MuscleExerciseListView(
                            title: muscle.frenchName,
                            muscles: [muscle]
                        )
                    } label: {
                        MuscleSubcategoryRow(
                            muscle: muscle,
                            exerciseCount: exerciseCount(for: [muscle])
                        )
                    }
                    .accessibilityIdentifier("muscle.group.\(muscle.rawValue)")
                }
            }

            Section {
                NavigationLink {
                    MuscleExerciseListView(
                        title: "Tous — \(region.frenchName)",
                        muscles: region.filterMuscles
                    )
                } label: {
                    Label(
                        "Voir les \(exerciseCount(for: region.filterMuscles)) exercices",
                        systemImage: "list.bullet.rectangle"
                    )
                    .font(.headline)
                    .foregroundStyle(AtlasTheme.accent)
                }
            }
        }
        .navigationTitle(region.frenchName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exerciseCount(for muscles: [MuscleGroup]) -> Int {
        exercises.count { $0.involves(anyOf: muscles) }
    }
}

private struct MuscleSubcategoryRow: View {
    let muscle: MuscleGroup
    let exerciseCount: Int

    var body: some View {
        HStack(spacing: 14) {
            AnatomyMapView(muscles: [muscle])
                .frame(width: 74, height: 74)
                .padding(4)
                .background(AtlasTheme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(muscle.frenchName)
                    .font(.headline)
                Text("\(exerciseCount) exercice\(exerciseCount > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct MuscleExerciseListView: View {
    @Query(sort: \ExerciseRecord.nameFrench)
    private var exercises: [ExerciseRecord]
    @State private var searchText = ""

    let title: String
    let muscles: [MuscleGroup]

    private var filteredExercises: [ExerciseRecord] {
        exercises.filter { exercise in
            exercise.involves(anyOf: muscles)
                && (searchText.isEmpty
                    || exercise.displayName.localizedCaseInsensitiveContains(searchText)
                    || exercise.nameEnglish.localizedCaseInsensitiveContains(searchText)
                    || exercise.aliases.contains { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        List {
            Section {
                AnatomyMapView(muscles: muscles)
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .listRowBackground(Color.clear)
                TextField("Rechercher dans cette catégorie", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("muscle.exercise.search")
            }

            Section("\(filteredExercises.count) exercice\(filteredExercises.count > 1 ? "s" : "")") {
                if filteredExercises.isEmpty {
                    ContentUnavailableView.search(text: searchText)
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
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ExerciseRecord {
    func involves(anyOf muscles: [MuscleGroup]) -> Bool {
        let values = Set(muscles.map(\.rawValue))
        return !values.isDisjoint(with: primaryMuscles)
            || !values.isDisjoint(with: secondaryMuscles)
    }
}
