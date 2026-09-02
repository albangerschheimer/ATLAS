import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.black)
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                        .frame(width: 58, height: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ATLAS")
                                .font(.title2.bold())
                                .tracking(1.4)
                            Text("Vos données. Votre entraînement.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                    .accessibilityElement(children: .combine)
                }

                Section("Données") {
                    profileRow("Stockage sur cet iPhone", detail: "Privé", icon: "iphone", tint: AtlasTheme.accent)
                    profileRow("Aucun compte ni backend", detail: "Local", icon: "icloud.slash", tint: AtlasTheme.success)
                    NavigationLink {
                        DataExportView()
                    } label: {
                        Label("Exporter les données", systemImage: "square.and.arrow.up")
                    }
                }

                Section("Nutrition") {
                    NavigationLink {
                        NutritionView()
                    } label: {
                        Label("Journal et objectifs", systemImage: "fork.knife.circle.fill")
                    }
                    .accessibilityIdentifier("profile.nutrition")
                }

                Section("Intégrations") {
                    NavigationLink {
                        HealthSettingsView()
                    } label: {
                        profileRow("Apple Santé", detail: "Disponible", icon: "heart.text.square.fill", tint: .red)
                    }
                    profileRow("Foodvisor", detail: "via Santé", icon: "fork.knife", tint: .green)
                    profileRow("Strava", detail: "via Santé", icon: "figure.run", tint: .orange)
                }

                Section("Confidentialité") {
                    Text("Apple Santé est facultatif et lu uniquement après votre action. La caméra sert seulement au scan de code-barres et les requêtes Open Food Facts ne contiennent aucune donnée de santé.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("ATLAS") {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
                    )
                    LabeledContent("Édition", value: "Coach + Santé + Controls")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.canvas)
            .navigationTitle("Profil")
        }
    }

    private func profileRow(_ title: String, detail: String, icon: String, tint: Color) -> some View {
        HStack {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon).foregroundStyle(tint)
            }
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
