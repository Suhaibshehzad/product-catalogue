import CatalogueCore
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var searchTerm = ""
    private let onSearch: (String) -> Void

    init(repository: CatalogueRepository, onSearch: @escaping (String) -> Void) {
        _viewModel = State(initialValue: HomeViewModel(repository: repository))
        self.onSearch = onSearch
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                searchBar
                LoadableContent(state: viewModel.state, retry: viewModel.load) { content in
                    VStack(alignment: .leading, spacing: 20) {
                        categories(content.categories)
                        Text("Top rated").font(.title2.bold())
                        ProductGrid(products: content.featured)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Catalogue")
        .task { if viewModel.state.value == nil { await viewModel.load() } }
        .refreshable { await viewModel.load() }
    }

    private var searchBar: some View {
        HStack {
            TextField("Search products", text: $searchTerm)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit(search)
                .accessibilityIdentifier("searchField")
            Button("Search", action: search)
                .buttonStyle(.borderedProminent)
                .disabled(!SearchViewModel.isSearchable(searchTerm))
                .accessibilityIdentifier("searchButton")
        }
    }

    private func categories(_ categories: [ProductCategory]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(categories) { category in
                    NavigationLink(value: Route.category(category)) {
                        Text(category.name.capitalized)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("category-\(category.slug)")
                }
            }
        }
    }

    private func search() {
        guard SearchViewModel.isSearchable(searchTerm) else { return }
        onSearch(searchTerm)
    }
}

#Preview {
    NavigationStack { HomeView(repository: PreviewCatalogueRepository()) { _ in } }
}
