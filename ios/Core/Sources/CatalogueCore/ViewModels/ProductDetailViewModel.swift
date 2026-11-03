import Observation

@MainActor
@Observable
public final class ProductDetailViewModel {
    public let productId: String
    public private(set) var state: Loadable<Product> = .idle
    private let repository: CatalogueRepository

    public init(productId: String, repository: CatalogueRepository) {
        self.productId = productId
        self.repository = repository
    }

    public func load() async {
        state = .loading
        state = await .load { () async throws(APIError) in
            try await repository.product(id: productId)
        }
    }
}
