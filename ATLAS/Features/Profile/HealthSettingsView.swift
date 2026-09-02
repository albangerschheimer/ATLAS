import SwiftUI

struct HealthSettingsView: View {
    @AppStorage("healthAccessRequested") private var healthAccessRequested = false
    @StateObject private var healthModel = HealthDashboardViewModel()

    var body: some View {
        List {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(connectionTitle)
                            .font(.headline)
                        Text(connectionDetail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: healthAccessRequested ? "heart.text.square.fill" : "heart.text.square")
                        .foregroundStyle(healthAccessRequested ? AtlasTheme.success : AtlasTheme.accent)
                }
            }

            Section("Données demandées en lecture") {
                healthTypeRow("Sommeil", icon: "bed.double.fill")
                healthTypeRow("Fréquence cardiaque et fréquence au repos", icon: "heart.fill")
                healthTypeRow("Pas, distance et calories actives", icon: "figure.walk")
                healthTypeRow("Poids", icon: "scalemass.fill")
                healthTypeRow("Calories alimentaires, protéines, glucides et lipides", icon: "fork.knife")
                healthTypeRow("Course, vélo, natation, basket et autres entraînements", icon: "figure.mixed.cardio")
            }

            Section {
                Button {
                    Task {
                        if await healthModel.requestAccess() {
                            healthAccessRequested = true
                        }
                    }
                } label: {
                    if healthModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Connexion…")
                        }
                    } else {
                        Label(
                            healthAccessRequested ? "Revoir les autorisations" : "Connecter Apple Santé",
                            systemImage: "heart.circle.fill"
                        )
                    }
                }
                .disabled(healthModel.isLoading || !healthModel.isHealthDataAvailable)
                .accessibilityIdentifier("health.connect")
            } footer: {
                Text("ATLAS demande uniquement la lecture. Apple ne révèle pas à une app quelles catégories de lecture ont été refusées : une valeur absente reste donc affichée comme indisponible, jamais comme zéro.")
            }

            if let errorMessage = healthModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            Section("Xiaomi Smart Band 9") {
                Text("Le chemin utilisé est Xiaomi Smart Band 9 → Mi Fitness → Apple Santé → ATLAS. ATLAS ne se connecte pas directement au bracelet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Foodvisor et Strava") {
                Text("ATLAS lit ce que Foodvisor et Strava écrivent dans Apple Santé. Les activités équivalentes provenant de plusieurs apps sont regroupées afin de ne compter qu’un seul entraînement.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Confidentialité") {
                Text("Les données lues restent traitées localement. Aucun compte, backend ou envoi vers une IA n’est activé.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Apple Santé")
    }

    private var connectionTitle: String {
        guard healthModel.isHealthDataAvailable else { return "Apple Santé indisponible" }
        return healthAccessRequested ? "Connexion demandée" : "Non connecté"
    }

    private var connectionDetail: String {
        guard healthModel.isHealthDataAvailable else {
            return "Utilisez un iPhone compatible pour connecter vos données."
        }
        return healthAccessRequested
            ? "Les catégories accordées seront affichées sur Today."
            : "Choisissez précisément les catégories à partager avec ATLAS."
    }

    private func healthTypeRow(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
    }
}
