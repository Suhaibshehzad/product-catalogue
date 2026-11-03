import CatalogueCore
import SwiftUI

struct ProductTile: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ProductImage(url: product.imageUrl)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
            Text(product.title)
                .font(.subheadline)
                .lineLimit(2, reservesSpace: true)
                .foregroundStyle(.primary)
            HStack {
                Text(product.price.formatted).font(.subheadline.bold())
                Spacer()
                RatingLabel(rating: product.rating)
            }
        }
        .padding(10)
        .background(.background, in: .rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("productTile-\(product.id)")
    }
}

/// Two-column grid of tappable product tiles.
struct ProductGrid: View {
    let products: [Product]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(products) { product in
                NavigationLink(value: Route.product(id: product.id)) {
                    ProductTile(product: product)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ProductImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFit()
        } placeholder: {
            Image(systemName: "photo").font(.largeTitle).foregroundStyle(.tertiary)
        }
        .accessibilityHidden(true)
    }
}

struct RatingLabel: View {
    let rating: Product.Rating

    var body: some View {
        Label(rating.average.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
            .font(.caption)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Rated \(rating.average, format: .number) out of 5")
    }
}

extension Product.Price {
    var formatted: String { amount.formatted(.currency(code: currency)) }
}
