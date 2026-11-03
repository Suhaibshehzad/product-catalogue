import CatalogueCore
import SwiftUI

@main
struct CatalogueApp: App {
    private let repository = Self.makeRepository()

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository)
        }
    }

    /// Composition root. UI tests pass `-useStubData` to run without a backend.
    private static func makeRepository() -> CatalogueRepository {
        if ProcessInfo.processInfo.arguments.contains("-useStubData") {
            return PreviewCatalogueRepository()
        }
        let configured = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
        let baseURL = configured.flatMap(URL.init(string:)) ?? URL(string: "http://localhost:3000")!
        return RemoteCatalogueRepository(client: APIClient(baseURL: baseURL))
    }
}
