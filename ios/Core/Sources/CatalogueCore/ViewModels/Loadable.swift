/// The state of anything fetched from the backend.
public enum Loadable<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(message: String)

    public var value: Value? {
        if case let .loaded(value) = self { value } else { nil }
    }

    public var errorMessage: String? {
        if case let .failed(message) = self { message } else { nil }
    }

    public var isLoading: Bool {
        if case .loading = self { true } else { false }
    }
}

extension Loadable {
    /// Runs `operation`, moving through `.loading` to `.loaded` or `.failed`.
    @MainActor
    static func load(_ operation: () async throws(APIError) -> Value) async -> Loadable {
        do {
            return .loaded(try await operation())
        } catch {
            return .failed(message: error.userMessage)
        }
    }
}
