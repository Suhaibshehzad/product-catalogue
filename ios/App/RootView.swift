import CatalogueCore
import SwiftUI

enum Route: Hashable {
    case category(ProductCategory)
    case product(id: String)
    case search(term: String)
}

struct RootView: View {
    let repository: CatalogueRepository
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(repository: repository) { term in path.append(.search(term: term)) }
                .navigationDestination(for: Route.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case let .category(category):
            CategoryView(category: category, repository: repository)
        case let .product(id):
            ProductDetailView(productId: id, repository: repository)
        case let .search(term):
            SearchResultsView(term: term, repository: repository)
        }
    }
}
