import Foundation

/// Mirrors the backend's `Product` contract — not the Fake Store shape.
public struct Product: Codable, Hashable, Identifiable, Sendable {
    public struct Price: Codable, Hashable, Sendable {
        public let amount: Double
        public let currency: String

        public init(amount: Double, currency: String) {
            self.amount = amount
            self.currency = currency
        }
    }

    public struct Rating: Codable, Hashable, Sendable {
        public let average: Double
        public let count: Int

        public init(average: Double, count: Int) {
            self.average = average
            self.count = count
        }
    }

    public let id: String
    public let title: String
    public let description: String
    public let price: Price
    public let imageUrl: URL
    public let category: ProductCategory
    public let rating: Rating

    public init(
        id: String, title: String, description: String, price: Price,
        imageUrl: URL, category: ProductCategory, rating: Rating
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.price = price
        self.imageUrl = imageUrl
        self.category = category
        self.rating = rating
    }
}

public struct ProductCategory: Codable, Hashable, Identifiable, Sendable {
    public let slug: String
    public let name: String
    public var id: String { slug }

    public init(slug: String, name: String) {
        self.slug = slug
        self.name = name
    }
}

public struct CategoryPage: Codable, Hashable, Sendable {
    public let category: ProductCategory
    public let topRated: [Product]
    public let others: [Product]

    public init(category: ProductCategory, topRated: [Product], others: [Product]) {
        self.category = category
        self.topRated = topRated
        self.others = others
    }
}
