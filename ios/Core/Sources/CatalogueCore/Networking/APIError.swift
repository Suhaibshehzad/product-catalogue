import Foundation

public enum APIError: Error, Equatable, Sendable {
    public struct FieldError: Codable, Equatable, Sendable {
        public let field: String
        public let message: String
    }

    /// The backend could not be reached at all.
    case unreachable
    /// The backend answered with its `{ error: { code, message, details? } }` shape.
    case server(status: Int, code: String, message: String, fieldErrors: [FieldError])
    /// The backend answered with something we could not understand.
    case invalidResponse

    /// Copy suitable for showing to a customer.
    public var userMessage: String {
        switch self {
        case .unreachable:
            "We can't reach the catalogue right now. Check your connection and try again."
        case let .server(status, _, message, _) where status < 500:
            message
        case .server, .invalidResponse:
            "Something went wrong on our side. Please try again."
        }
    }
}
