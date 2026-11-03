import Foundation

public struct EnquiryRequest: Codable, Equatable, Sendable {
    public let productId: String
    public let name: String
    public let email: String
    public let phone: String?
    public let message: String?

    public init(productId: String, name: String, email: String, phone: String?, message: String?) {
        self.productId = productId
        self.name = name
        self.email = email
        self.phone = phone
        self.message = message
    }
}
