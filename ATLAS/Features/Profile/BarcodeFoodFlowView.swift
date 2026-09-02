import SwiftUI

struct BarcodeFoodFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var product: OpenFoodProduct?
    @State private var isLoading = false
    @State private var errorMessage: String?
    private let client: any OpenFoodFactsFetching

    init(client: any OpenFoodFactsFetching = OpenFoodFactsClient()) {
        self.client = client
    }

    var body: some View {
        Group {
            if let product {
                NutritionEntryEditorView(product: product)
            } else {
                NavigationStack {
                    ZStack {
                        BarcodeScannerView(onCode: lookup, onFailure: { errorMessage = $0 })
                            .ignoresSafeArea()

                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white, lineWidth: 3)
                            .frame(width: 280, height: 150)
                            .shadow(color: .black.opacity(0.5), radius: 8)

                        VStack {
                            Spacer()
                            Text("Placez le code-barres dans le cadre")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding()
                                .background(.black.opacity(0.65), in: Capsule())
                                .padding(.bottom, 45)
                        }

                        if isLoading {
                            ProgressView("Recherche Open Food Facts…")
                                .padding(20)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fermer") { dismiss() }
                                .foregroundStyle(.white)
                        }
                    }
                    .alert("Produit indisponible", isPresented: Binding(
                        get: { errorMessage != nil },
                        set: { if !$0 { errorMessage = nil } }
                    )) {
                        Button("Réessayer") { errorMessage = nil }
                        Button("Fermer", role: .cancel) { dismiss() }
                    } message: {
                        Text(errorMessage ?? "Erreur inconnue")
                    }
                }
            }
        }
    }

    private func lookup(_ barcode: String) {
        guard !isLoading else { return }
        isLoading = true
        Task {
            do {
                product = try await client.product(barcode: barcode)
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "La recherche a échoué."
            }
            isLoading = false
        }
    }
}
