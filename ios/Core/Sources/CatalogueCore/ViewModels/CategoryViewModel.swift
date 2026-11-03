import Observation

@MainActor
@Observable
public final class CategoryViewModel {
    public let category: ProductCategory
    public private(set) var state: Loadable<CategoryPage> = .idle
    private let repository: CatalogueRepository

    public init(category: ProductCategory, repository: CatalogueRepository) {
        self.category = category
        self.repository = repository
    }

    public func load() async {
        state = .loading
        state = await .load { () async throws(APIError) in
            try await repository.categoryPage(slug: category.slug)
        }
    }
}
