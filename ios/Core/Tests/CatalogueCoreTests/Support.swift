import Foundation
@testable import CatalogueCore

/// Records calls and returns canned results. Only touched from the main actor in tests.
final class StubRepository: CatalogueRepository, @unchecked Sendable {
    var featured: Result<[Product], APIError> = .success([])
    var categoryList: Result<[ProductCategory], APIError> = .success([])
    var page: Result<CategoryPage, APIError> = .failure(.invalidResponse)
    var searchResults: Result<[Product], APIError> = .success([])
    var productResult: Result<Product, APIError> = .failure(.invalidResponse)
    var enquiryResult: Result<Void, APIError> = .success(())

    private(set) var searchedTerms: [String] = []
    private(set) var submittedEnquiries: [EnquiryRequest] = []

    func featuredProducts() async throws(APIError) -> [Product] { try featured.get() }
    func categories() async throws(APIError) -> [ProductCategory] { try categoryList.get() }
    func categoryPage(slug _: String) async throws(APIError) -> CategoryPage { try page.get() }
    func product(id _: String) async throws(APIError) -> Product { try productResult.get() }

    func search(_ term: String) async throws(APIError) -> [Product] {
        searchedTerms.append(term)
        return try searchResults.get()
    }

    func submitEnquiry(_ enquiry: EnquiryRequest) async throws(APIError) {
        submittedEnquiries.append(enquiry)
        try enquiryResult.get()
    }
}

/// Serves one canned response per request and records what was asked for.
final class StubTransport: HTTPTransport, @unchecked Sendable {
    var status = 200
    var body = Data()
    var failure: URLError?
    private(set) var requests: [URLRequest] = []

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        if let failure { throw failure }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (body, response)
    }
}

let sampleProduct = PreviewCatalogueRepository.products[0]
