import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public static let maxTermLength = 100

    public let term: String
    public private(set) var state: Loadable<[Product]> = .idle
    private let repository: CatalogueRepository

    public init(term: String, repository: CatalogueRepository) {
        self.term = term
        self.repository = repository
    }

    /// Whether a typed term is worth sending; used to enable the Search button.
    public static func isSearchable(_ term: String) -> Bool {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= maxTermLength
    }

    public func load() async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        state = .loading
        state = await .load { () async throws(APIError) in
            try await repository.search(trimmed)
        }
    }
}
