import XCTest

/// Full flow against the real backend and Mailpit. Skipped unless enabled:
///   TEST_RUNNER_LIVE_BACKEND=1 xcodebuild test -only-testing:CatalogueUITests/LiveBackendUITests ...
@MainActor
final class LiveBackendUITests: XCTestCase {
    private let mailpit = URL(string: ProcessInfo.processInfo.environment["MAILPIT_URL"] ?? "http://localhost:8025")!

    override func setUp() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["LIVE_BACKEND"] == "1",
            "Set TEST_RUNNER_LIVE_BACKEND=1 with the backend and Mailpit running"
        )
        continueAfterFailure = false
    }

    func testBrowseCategoryAndEnquireSendsEmail() async throws {
        let app = XCUIApplication()
        app.launch()

        // Home: featured products come from the backend.
        XCTAssertTrue(app.staticTexts["Top rated"].waitForExistence(timeout: 15))

        // Category: top rated plus more products.
        app.buttons["category-electronics"].tap()
        XCTAssertTrue(app.staticTexts["More in electronics"].waitForExistence(timeout: 15))

        // Product page.
        let tile = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'productTile-'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()

        // Enquiry.
        let enquire = app.buttons["enquireButton"]
        XCTAssertTrue(enquire.waitForExistence(timeout: 10))
        enquire.tap()
        let marker = "UITest \(Int(Date().timeIntervalSince1970))"
        fill(app, "enquiry.name", with: marker)
        fill(app, "enquiry.email", with: "uitest@example.com")
        app.buttons["enquiry.submit"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["enquiry.thankYou"].waitForExistence(timeout: 15))
        let received = try await mailpitMessageCount(matching: marker)
        XCTAssertEqual(received, 1, "Sales inbox should have received exactly one email")
    }

    private func fill(_ app: XCUIApplication, _ identifier: String, with text: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    private func mailpitMessageCount(matching query: String) async throws -> Int {
        struct SearchResult: Decodable { let messages_count: Int }
        let url = mailpit.appending(path: "api/v1/search").appending(queryItems: [.init(name: "query", value: "\"\(query)\"")])
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(SearchResult.self, from: data).messages_count
    }
}
