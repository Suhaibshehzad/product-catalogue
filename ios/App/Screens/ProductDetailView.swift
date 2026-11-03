import CatalogueCore
import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    @State private var enquiringAbout: Product?
    private let repository: CatalogueRepository

    init(productId: String, repository: CatalogueRepository) {
        _viewModel = State(initialValue: ProductDetailViewModel(productId: productId, repository: repository))
        self.repository = repository
    }

    var body: some View {
        LoadableContent(state: viewModel.state, retry: viewModel.load) { product in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ProductImage(url: product.imageUrl)
                        .frame(height: 260)
                        .frame(maxWidth: .infinity)
                    Text(product.title).font(.title2.bold())
                    HStack {
                        Text(product.price.formatted).font(.title3)
                        Spacer()
                        RatingLabel(rating: product.rating)
                    }
                    Text(product.category.name.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(product.description)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                Button("Enquire") { enquiringAbout = product }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.bar)
                    .accessibilityIdentifier("enquireButton")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { if viewModel.state.value == nil { await viewModel.load() } }
        .sheet(item: $enquiringAbout) { product in
            EnquiryFormView(product: product, repository: repository)
        }
    }
}

#Preview {
    NavigationStack { ProductDetailView(productId: "1", repository: PreviewCatalogueRepository()) }
}
