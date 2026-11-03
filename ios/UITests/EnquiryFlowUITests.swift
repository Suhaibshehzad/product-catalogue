import XCTest

/// Runs against the in-memory catalogue (`-useStubData`) so it needs no backend.
@MainActor
final class EnquiryFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-useStubData"]
        app.launch()
    }

    func testHomeShowsFeaturedProducts() {
        XCTAssertTrue(app.staticTexts["Top rated"].waitForExistence(timeout: 5))
        for id in 1...5 {
            XCTAssertTrue(app.descendants(matching: .any)["productTile-\(id)"].exists, "Missing featured product \(id)")
        }
    }

    func testSearchShowsOnlyMatchingProducts() {
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("drive")
        app.buttons["searchButton"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["productTile-2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["productTile-4"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["productTile-1"].exists)
    }

    func testEnquiryShowsThankYouAfterSubmitting() {
        let tile = app.descendants(matching: .any)["productTile-1"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.tap()

        app.buttons["enquireButton"].tap()
        fill("enquiry.name", with: "Ada Lovelace")
        fill("enquiry.email", with: "ada@example.com")
        app.buttons["enquiry.submit"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["enquiry.thankYou"].waitForExistence(timeout: 5))
    }

    private func fill(_ identifier: String, with text: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }
}
