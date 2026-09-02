import Foundation

struct OpenFoodProduct: Equatable, Codable, Sendable {
    let barcode: String
    let name: String
    let brand: String?
    let servingQuantityGrams: Double?
    let perHundredGrams: NutritionTotals

    var displayName: String {
        guard let brand, !brand.isEmpty else { return name }
        return "\(name) · \(brand)"
    }
}

protocol OpenFoodFactsFetching: Sendable {
    func product(barcode: String) async throws -> OpenFoodProduct
}

struct OpenFoodFactsClient: OpenFoodFactsFetching {
    private let session: URLSession
    private let cache: OpenFoodFactsProductCache

    init(
        session: URLSession = .shared,
        cache: OpenFoodFactsProductCache = .shared
    ) {
        self.session = session
        self.cache = cache
    }

    func product(barcode: String) async throws -> OpenFoodProduct {
        guard barcode.allSatisfy(\.isNumber), (8...14).contains(barcode.count) else {
            throw OpenFoodFactsError.invalidBarcode
        }
        if let cached = await cache.product(for: barcode, maximumAge: 30 * 86_400) {
            return cached
        }

        var components = URLComponents(
            string: "https://world.openfoodfacts.org/api/v3.6/product/\(barcode).json"
        )
        components?.queryItems = [
            URLQueryItem(name: "lc", value: "fr"),
            URLQueryItem(name: "cc", value: "fr"),
            URLQueryItem(
                name: "fields",
                value: "code,product_name,brands,serving_quantity,nutriments"
            )
        ]
        guard let url = components?.url else { throw OpenFoodFactsError.invalidBarcode }

        var request = URLRequest(url: url)
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.4.0"
        request.setValue("ATLAS/\(appVersion) (iOS; personal nutrition tracker)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if let cached = await cache.product(for: barcode) {
                return cached
            }
            throw error
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenFoodFactsError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 { throw OpenFoodFactsError.notFound }
            throw OpenFoodFactsError.invalidResponse
        }

        let product = try Self.decodeProduct(data, fallbackBarcode: barcode)
        await cache.store(product)
        return product
    }

    static func decodeProduct(_ data: Data, fallbackBarcode: String) throws -> OpenFoodProduct {
        let payload = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        guard let product = payload.product else { throw OpenFoodFactsError.notFound }
        let name = product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let name, !name.isEmpty else { throw OpenFoodFactsError.incompleteNutrition }
        let nutrients = product.nutriments

        return OpenFoodProduct(
            barcode: payload.code ?? fallbackBarcode,
            name: name,
            brand: product.brands,
            servingQuantityGrams: product.servingQuantity,
            perHundredGrams: NutritionTotals(
                energyKilocalories: nutrients?.energyKilocalories100g ?? 0,
                proteinGrams: nutrients?.protein100g ?? 0,
                carbohydrateGrams: nutrients?.carbohydrates100g ?? 0,
                fatGrams: nutrients?.fat100g ?? 0
            )
        )
    }
}

actor OpenFoodFactsProductCache {
    static let shared = OpenFoodFactsProductCache()

    private struct CachedProduct: Codable {
        let product: OpenFoodProduct
        let cachedAt: Date
    }

    private let fileURL: URL
    private var products: [String: CachedProduct]

    init(fileURL: URL? = nil) {
        let resolvedURL = fileURL ?? FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("open-food-facts-products.json")
        self.fileURL = resolvedURL
        if let data = try? Data(contentsOf: resolvedURL),
           let decoded = try? JSONDecoder().decode([String: CachedProduct].self, from: data) {
            products = decoded
        } else {
            products = [:]
        }
    }

    func product(for barcode: String, maximumAge: TimeInterval? = nil) -> OpenFoodProduct? {
        guard let cached = products[barcode] else { return nil }
        if let maximumAge, Date.now.timeIntervalSince(cached.cachedAt) > maximumAge {
            return nil
        }
        return cached.product
    }

    func store(_ product: OpenFoodProduct, now: Date = .now) {
        products[product.barcode] = CachedProduct(product: product, cachedAt: now)
        persist()
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(products)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // The scanner remains usable online if the non-critical cache cannot be written.
        }
    }
}

enum OpenFoodFactsError: LocalizedError {
    case invalidBarcode
    case notFound
    case incompleteNutrition
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidBarcode: "Ce code-barres n’est pas valide."
        case .notFound: "Ce produit n’existe pas dans Open Food Facts."
        case .incompleteNutrition: "Le produit ne contient pas assez d’informations nutritionnelles."
        case .invalidResponse: "Open Food Facts ne répond pas correctement. Réessayez plus tard."
        }
    }
}

private struct OpenFoodFactsResponse: Decodable {
    let code: String?
    let product: Product?

    struct Product: Decodable {
        let productName: String?
        let brands: String?
        let servingQuantity: Double?
        let nutriments: Nutriments?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
            case servingQuantity = "serving_quantity"
            case nutriments
        }
    }

    struct Nutriments: Decodable {
        let energyKilocalories100g: Double?
        let protein100g: Double?
        let carbohydrates100g: Double?
        let fat100g: Double?

        enum CodingKeys: String, CodingKey {
            case energyKilocalories100g = "energy-kcal_100g"
            case protein100g = "proteins_100g"
            case carbohydrates100g = "carbohydrates_100g"
            case fat100g = "fat_100g"
        }
    }
}
