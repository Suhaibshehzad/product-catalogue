import CatalogueCore
import SwiftUI

struct SearchResultsView: View {
    @State private var viewModel: SearchViewModel

    init(term: String, repository: CatalogueRepository) {
        _viewModel = State(initialValue: SearchViewModel(term: term, repository: repository))
    }

    var body: some View {
        LoadableContent(state: viewModel.state, retry: viewModel.load) { products in
            if products.isEmpty {
                ContentUnavailableView.search(text: viewModel.term)
            } else {
                ScrollView { ProductGrid(products: products).padding() }
            }
        }
        .navigationTitle("“\(viewModel.term)”")
        .task { if viewModel.state.value == nil { await viewModel.load() } }
    }
}

#Preview {
    NavigationStack { SearchResultsView(term: "drive", repository: PreviewCatalogueRepository()) }
}
