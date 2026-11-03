import Observation

@MainActor
@Observable
public final class HomeViewModel {
    public struct Content: Sendable {
        public let featured: [Product]
        public let categories: [ProductCategory]
    }

    public private(set) var state: Loadable<Content> = .idle
    private let repository: CatalogueRepository

    public init(repository: CatalogueRepository) {
        self.repository = repository
    }

    public func load() async {
        state = .loading
        // Fetched concurrently; `async let` erases typed throws, hence the cast.
        do {
            async let featured = repository.featuredProducts()
            async let categories = repository.categories()
            state = .loaded(try await Content(featured: featured, categories: categories))
        } catch {
            state = .failed(message: (error as? APIError ?? .invalidResponse).userMessage)
        }
    }
}
