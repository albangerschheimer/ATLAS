import SwiftData
import SwiftUI

@main
struct ATLASApp: App {
    @StateObject private var feedback = AppFeedback()
    @StateObject private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup {
            Group {
                if let modelContainer = bootstrap.modelContainer {
                    RootTabView()
                        .modelContainer(modelContainer)
                } else if bootstrap.error != nil {
                    DataUnavailableView(retry: bootstrap.load)
                } else {
                    ProgressView("Préparation des données…")
                }
            }
            .environmentObject(feedback)
            .task {
                bootstrap.loadIfNeeded()
            }
        }
    }
}

@MainActor
private final class AppBootstrap: ObservableObject {
    @Published private(set) var modelContainer: ModelContainer?
    @Published private(set) var error: Error?
    private var isLoading = false

    func loadIfNeeded() {
        guard modelContainer == nil, error == nil else { return }
        load()
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        error = nil

        do {
            let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            modelContainer = try ModelContainerFactory.make(inMemory: isUITesting)
        } catch {
            self.error = error
        }

        isLoading = false
    }
}

private struct DataUnavailableView: View {
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Données indisponibles", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("ATLAS n’a pas pu ouvrir son stockage local. Aucune donnée n’a été supprimée.")
        } actions: {
            Button("Réessayer", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
