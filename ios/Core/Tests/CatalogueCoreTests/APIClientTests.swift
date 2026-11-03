import Foundation
import Testing
@testable import CatalogueCore

@Suite struct APIClientTests {
    let transport = StubTransport()
    var repository: RemoteCatalogueRepository {
        RemoteCatalogueRepository(client: APIClient(baseURL: URL(string: "http://localhost:3000")!, transport: transport))
    }

    @Test func decodesTheBackendProductContract() async throws {
        transport.body = Data("""
        {"product":{"id":"1","title":"Backpack","description":"Bag","price":{"amount":109.95,"currency":"USD"},
        "imageUrl":"https://x/1.png","category":{"slug":"mens-clothing","name":"men's clothing"},
        "rating":{"average":3.9,"count":120}}}
        """.utf8)

        let product = try await repository.product(id: "1")

        #expect(transport.requests.first?.url?.absoluteString == "http://localhost:3000/api/products/1")
        #expect(product.title == "Backpack")
        #expect(product.price == .init(amount: 109.95, currency: "USD"))
        #expect(product.category == ProductCategory(slug: "mens-clothing", name: "men's clothing"))
    }

    @Test func encodesTheSearchTermAsAQueryParameter() async throws {
        transport.body = Data(#"{"products":[]}"#.utf8)
        _ = try await repository.search("gold & silver")
        #expect(transport.requests.first?.url?.absoluteString == "http://localhost:3000/api/products?q=gold%20%26%20silver")
    }

    @Test func postsEnquiriesAsJSON() async throws {
        transport.status = 202
        transport.body = Data(#"{"status":"sent"}"#.utf8)
        let enquiry = EnquiryRequest(productId: "1", name: "Ada", email: "ada@example.com", phone: nil, message: "Hi")

        try await repository.submitEnquiry(enquiry)

        let request = try #require(transport.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(try JSONDecoder().decode(EnquiryRequest.self, from: request.httpBody ?? Data()) == enquiry)
    }

    @Test func mapsTheBackendErrorEnvelopeIncludingFieldErrors() async {
        transport.status = 400
        transport.body = Data("""
        {"error":{"code":"VALIDATION_FAILED","message":"Request is invalid",
        "details":[{"field":"email","message":"Enter a valid email address"}]}}
        """.utf8)

        await #expect(throws: APIError.server(
            status: 400, code: "VALIDATION_FAILED", message: "Request is invalid",
            fieldErrors: [.init(field: "email", message: "Enter a valid email address")]
        )) {
            try await repository.submitEnquiry(.init(productId: "1", name: "A", email: "x", phone: nil, message: nil))
        }
    }

    @Test func reportsUnreachableWhenTheRequestFails() async {
        transport.failure = URLError(.cannotConnectToHost)
        await #expect(throws: APIError.unreachable) { try await repository.featuredProducts() }
    }

    @Test func reportsInvalidResponseForUnexpectedJSON() async {
        transport.body = Data(#"{"unexpected":true}"#.utf8)
        await #expect(throws: APIError.invalidResponse) { try await repository.featuredProducts() }
    }

    @Test func hidesServerDetailsFromCustomersOn5xx() {
        let error = APIError.server(status: 502, code: "UPSTREAM_UNAVAILABLE", message: "internal detail", fieldErrors: [])
        #expect(error.userMessage == "Something went wrong on our side. Please try again.")
        let notFound = APIError.server(status: 404, code: "NOT_FOUND", message: "Product not found", fieldErrors: [])
        #expect(notFound.userMessage == "Product not found")
    }
}
