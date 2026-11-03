import Foundation

/// Everything the app needs from the catalogue. Views and view models depend on
/// this protocol, never on networking, so the transport can change freely.
public protocol CatalogueRepository: Sendable {
    func featuredProducts() async throws(APIError) -> [Product]
    func categories() async throws(APIError) -> [ProductCategory]
    func categoryPage(slug: String) async throws(APIError) -> CategoryPage
    func search(_ term: String) async throws(APIError) -> [Product]
    func product(id: String) async throws(APIError) -> Product
    func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError)
}

public struct RemoteCatalogueRepository: CatalogueRepository {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    private struct ProductsResponse: Decodable { let products: [Product] }
    private struct CategoriesResponse: Decodable { let categories: [ProductCategory] }
    private struct ProductResponse: Decodable { let product: Product }
    private struct EnquiryResponse: Decodable { let status: String }

    public func featuredProducts() async throws(APIError) -> [Product] {
        try await client.get("api/products/featured", as: ProductsResponse.self).products
    }

    public func categories() async throws(APIError) -> [ProductCategory] {
        try await client.get("api/categories", as: CategoriesResponse.self).categories
    }

    public func categoryPage(slug: String) async throws(APIError) -> CategoryPage {
        try await client.get("api/categories/\(slug)")
    }

    public func search(_ term: String) async throws(APIError) -> [Product] {
        try await client.get("api/products", query: [URLQueryItem(name: "q", value: term)], as: ProductsResponse.self)
            .products
    }

    public func product(id: String) async throws(APIError) -> Product {
        try await client.get("api/products/\(id)", as: ProductResponse.self).product
    }

    public func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError) {
        _ = try await client.post("api/enquiries", body: enquiry, as: EnquiryResponse.self)
    }
}
