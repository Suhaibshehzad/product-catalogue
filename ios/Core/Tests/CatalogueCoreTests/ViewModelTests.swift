import Testing
@testable import CatalogueCore

@MainActor
@Suite struct BrowsingViewModelTests {
    let repository = StubRepository()

    @Test func homeShowsFeaturedProductsAndCategories() async {
        repository.featured = .success(Array(PreviewCatalogueRepository.products.prefix(5)))
        repository.categoryList = .success([PreviewCatalogueRepository.electronics])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state.value?.featured.count == 5)
        #expect(viewModel.state.value?.categories == [PreviewCatalogueRepository.electronics])
    }

    @Test func homeShowsAFriendlyErrorWhenTheBackendIsDown() async {
        repository.featured = .failure(.unreachable)
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        #expect(viewModel.state.errorMessage == APIError.unreachable.userMessage)
    }

    @Test func categoryShowsTopRatedAndOtherProducts() async {
        let products = PreviewCatalogueRepository.products
        let page = CategoryPage(category: PreviewCatalogueRepository.electronics, topRated: Array(products[0...2]), others: [products[3]])
        repository.page = .success(page)
        let viewModel = CategoryViewModel(category: PreviewCatalogueRepository.electronics, repository: repository)

        await viewModel.load()

        #expect(viewModel.state.value == page)
    }

    @Test func productDetailLoadsTheProduct() async {
        repository.productResult = .success(sampleProduct)
        let viewModel = ProductDetailViewModel(productId: sampleProduct.id, repository: repository)

        await viewModel.load()

        #expect(viewModel.state.value == sampleProduct)
    }

    @Test func searchSendsTheTrimmedTermAndShowsResults() async {
        repository.searchResults = .success([sampleProduct])
        let viewModel = SearchViewModel(term: "  mouse ", repository: repository)

        await viewModel.load()

        #expect(repository.searchedTerms == ["mouse"])
        #expect(viewModel.state.value == [sampleProduct])
    }

    @Test(arguments: [("mouse", true), ("   ", false), ("", false), (String(repeating: "a", count: 101), false)])
    func searchButtonIsOnlyEnabledForUsableTerms(term: String, expected: Bool) {
        #expect(SearchViewModel.isSearchable(term) == expected)
    }
}

@MainActor
@Suite struct EnquiryViewModelTests {
    let repository = StubRepository()

    func makeViewModel() -> EnquiryViewModel {
        let viewModel = EnquiryViewModel(product: sampleProduct, repository: repository)
        viewModel.name = " Ada Lovelace "
        viewModel.email = "ada@example.com"
        return viewModel
    }

    @Test func sendsTrimmedDetailsAndOnlyThenShowsThankYou() async {
        let viewModel = makeViewModel()
        viewModel.phone = "  "
        viewModel.message = "Is this in stock?"

        await viewModel.submit()

        #expect(viewModel.phase == .sent)
        #expect(repository.submittedEnquiries == [EnquiryRequest(
            productId: sampleProduct.id, name: "Ada Lovelace", email: "ada@example.com",
            phone: nil, message: "Is this in stock?"
        )])
    }

    @Test func blocksSubmissionWithInvalidFields() async {
        let viewModel = makeViewModel()
        viewModel.name = "  "
        viewModel.email = "ada@"
        viewModel.phone = "call me"

        await viewModel.submit()

        #expect(viewModel.phase == .editing)
        #expect(Set(viewModel.fieldErrors.keys) == [.name, .email, .phone])
        #expect(repository.submittedEnquiries.isEmpty)
    }

    @Test func staysOnTheFormWithAnErrorWhenDeliveryFails() async {
        repository.enquiryResult = .failure(.server(
            status: 502, code: "DELIVERY_FAILED", message: "Your enquiry could not be sent.", fieldErrors: []
        ))
        let viewModel = makeViewModel()

        await viewModel.submit()

        #expect(viewModel.phase == .editing)
        #expect(viewModel.submitError == "Something went wrong on our side. Please try again.")
    }

    @Test func showsFieldErrorsReturnedByTheServer() async {
        repository.enquiryResult = .failure(.server(
            status: 400, code: "VALIDATION_FAILED", message: "Request is invalid",
            fieldErrors: [.init(field: "email", message: "Email domain not accepted")]
        ))
        let viewModel = makeViewModel()

        await viewModel.submit()

        #expect(viewModel.fieldErrors == [.email: "Email domain not accepted"])
        #expect(viewModel.submitError == nil)
    }

    @Test func clearsAPreviousErrorWhenRetrying() async {
        repository.enquiryResult = .failure(.unreachable)
        let viewModel = makeViewModel()
        await viewModel.submit()
        #expect(viewModel.submitError != nil)

        repository.enquiryResult = .success(())
        await viewModel.submit()

        #expect(viewModel.submitError == nil)
        #expect(viewModel.phase == .sent)
    }
}
