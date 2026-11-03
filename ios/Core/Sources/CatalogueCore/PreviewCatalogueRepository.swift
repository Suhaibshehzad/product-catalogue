import Foundation

/// In-memory repository for SwiftUI previews and UI tests, so neither needs a
/// running backend. Behaviour follows the backend's rules closely enough to demo.
public struct PreviewCatalogueRepository: CatalogueRepository {
    public static let electronics = ProductCategory(slug: "electronics", name: "electronics")
    public static let jewelery = ProductCategory(slug: "jewelery", name: "jewelery")

    public static let products: [Product] = [
        sample("1", "Wireless Mouse", 24.99, electronics, 4.8, "Ergonomic mouse with silent clicks."),
        sample("2", "1TB Portable SSD", 109.0, electronics, 4.6, "Fast solid state drive, USB-C."),
        sample("3", "27-inch Monitor", 229.5, electronics, 3.4, "IPS panel with thin bezels."),
        sample("4", "USB Hard Drive", 64.0, electronics, 3.1, "Reliable external storage."),
        sample("5", "Gold Ring", 168.0, jewelery, 4.2, "Solid gold band."),
        sample("6", "Silver Necklace", 95.0, jewelery, 3.9, "Sterling silver chain."),
    ]

    public init() {}

    public func featuredProducts() async throws(APIError) -> [Product] {
        Array(Self.products.prefix(5))
    }

    public func categories() async throws(APIError) -> [ProductCategory] {
        [Self.electronics, Self.jewelery]
    }

    public func categoryPage(slug: String) async throws(APIError) -> CategoryPage {
        guard let category = try await categories().first(where: { $0.slug == slug }) else {
            throw .server(status: 404, code: "NOT_FOUND", message: "ProductCategory not found", fieldErrors: [])
        }
        let products = Self.products.filter { $0.category == category }
        let topRated = Array(products.sorted { $0.rating.average > $1.rating.average }.prefix(3))
        let others = products.filter { !topRated.contains($0) }
        return CategoryPage(category: category, topRated: topRated, others: others)
    }

    public func search(_ term: String) async throws(APIError) -> [Product] {
        let terms = term.lowercased().split(whereSeparator: \.isWhitespace)
        return Self.products.filter { product in
            let haystack = "\(product.title) \(product.description) \(product.category.name)".lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    public func product(id: String) async throws(APIError) -> Product {
        guard let product = Self.products.first(where: { $0.id == id }) else {
            throw .server(status: 404, code: "NOT_FOUND", message: "Product not found", fieldErrors: [])
        }
        return product
    }

    public func submitEnquiry(_: EnquiryRequest) async throws(APIError) {}

    private static func sample(
        _ id: String, _ title: String, _ price: Double, _ category: ProductCategory, _ rating: Double, _ description: String
    ) -> Product {
        Product(
            id: id,
            title: title,
            description: description,
            price: .init(amount: price, currency: "USD"),
            imageUrl: URL(string: "https://example.invalid/\(id).png")!,
            category: category,
            rating: .init(average: rating, count: 100)
        )
    }
}
