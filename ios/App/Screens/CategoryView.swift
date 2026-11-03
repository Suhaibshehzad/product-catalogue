import CatalogueCore
import SwiftUI

struct CategoryView: View {
    @State private var viewModel: CategoryViewModel

    init(category: ProductCategory, repository: CatalogueRepository) {
        _viewModel = State(initialValue: CategoryViewModel(category: category, repository: repository))
    }

    var body: some View {
        ScrollView {
            LoadableContent(state: viewModel.state, retry: viewModel.load) { page in
                VStack(alignment: .leading, spacing: 20) {
                    Text("Top rated").font(.title2.bold())
                    ProductGrid(products: page.topRated)
                    if !page.others.isEmpty {
                        Text("More in \(page.category.name)").font(.title2.bold())
                        ProductGrid(products: page.others)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.category.name.capitalized)
        .task { if viewModel.state.value == nil { await viewModel.load() } }
    }
}

#Preview {
    NavigationStack {
        CategoryView(category: PreviewCatalogueRepository.electronics, repository: PreviewCatalogueRepository())
    }
}
