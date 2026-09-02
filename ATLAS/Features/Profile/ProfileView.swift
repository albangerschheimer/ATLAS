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

                Section {
                    NavigationLink {
                        DataExportView()
                    } label: {
                        Label("Exporter les données", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Données")
                } footer: {
                    Text("Tout est stocké sur cet iPhone : ni compte, ni serveur ATLAS.")
                }

                Section("Nutrition") {
                    NavigationLink {
                        NutritionView()
                    } label: {
                        Label("Journal et objectifs", systemImage: "fork.knife.circle.fill")
                    }
                    .accessibilityIdentifier("profile.nutrition")
                }

                Section {
                    NavigationLink {
                        HealthSettingsView()
                    } label: {
                        Label {
                            Text("Apple Santé")
                        } icon: {
                            Image(systemName: "heart.text.square.fill").foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Intégrations")
                } footer: {
                    Text("Foodvisor et Strava arrivent via Apple Santé, facultatif et lu seulement après votre action. La caméra sert uniquement au scan de code-barres et les requêtes Open Food Facts ne contiennent aucune donnée de santé.")
                }

                Section {
                    LabeledContent(
                        "Version",
                        value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AtlasTheme.canvas)
            .navigationTitle("Profil")
        }
    }
}
