import CatalogueCore
import SwiftUI

/// Shows a spinner, an error with Retry, or the loaded content.
struct LoadableContent<Value: Sendable, Content: View>: View {
    let state: Loadable<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .failed(message):
            ContentUnavailableView {
                Label("Couldn't load", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await retry() } }
                    .buttonStyle(.borderedProminent)
            }
        case let .loaded(value):
            content(value)
        }
    }
}
