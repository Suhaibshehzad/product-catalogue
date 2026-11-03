import Foundation
import Observation

@MainActor
@Observable
public final class EnquiryViewModel {
    public enum Field: String, CaseIterable, Sendable {
        case name, email, phone, message
    }

    public enum Phase: Equatable, Sendable {
        case editing
        case submitting
        /// Only reached once the backend confirms the sales inbox accepted the email.
        case sent
    }

    public let product: Product
    public var name = ""
    public var email = ""
    public var phone = ""
    public var message = ""

    public private(set) var phase: Phase = .editing
    public private(set) var fieldErrors: [Field: String] = [:]
    /// A form-level error, e.g. the email could not be delivered.
    public private(set) var submitError: String?

    private let repository: CatalogueRepository

    public init(product: Product, repository: CatalogueRepository) {
        self.product = product
        self.repository = repository
    }

    public func submit() async {
        guard phase == .editing else { return }
        submitError = nil
        fieldErrors = validate()
        guard fieldErrors.isEmpty else { return }

        phase = .submitting
        do {
            try await repository.submitEnquiry(request())
            phase = .sent
        } catch {
            phase = .editing
            apply(error)
        }
    }

    // Mirrors the backend rules so customers get instant feedback; the backend
    // remains the source of truth and its field errors are shown too.
    private func validate() -> [Field: String] {
        var errors: [Field: String] = [:]
        let name = trimmed(name)
        if name.isEmpty {
            errors[.name] = "Name is required"
        } else if name.count > 100 {
            errors[.name] = "Name must be 100 characters or fewer"
        }
        if !Self.isValidEmail(trimmed(email)) {
            errors[.email] = "Enter a valid email address"
        }
        let phone = trimmed(phone)
        if !phone.isEmpty, phone.range(of: #"^\+?[0-9 ()-]{6,20}$"#, options: .regularExpression) == nil {
            errors[.phone] = "Enter a valid phone number"
        }
        if trimmed(message).count > 2000 {
            errors[.message] = "Message must be 2000 characters or fewer"
        }
        return errors
    }

    private func request() -> EnquiryRequest {
        EnquiryRequest(
            productId: product.id,
            name: trimmed(name),
            email: trimmed(email),
            phone: trimmed(phone).nilIfEmpty,
            message: trimmed(message).nilIfEmpty
        )
    }

    private func apply(_ error: APIError) {
        if case let .server(_, _, _, details) = error, !details.isEmpty {
            for detail in details {
                if let field = Field(rawValue: detail.field) {
                    fieldErrors[field] = detail.message
                }
            }
            if !fieldErrors.isEmpty { return }
        }
        submitError = error.userMessage
    }

    /// Deliberately loose: the server does strict validation; this catches typos.
    static func isValidEmail(_ email: String) -> Bool {
        email.count <= 254
            && email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
