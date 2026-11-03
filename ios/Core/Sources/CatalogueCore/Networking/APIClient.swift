import Foundation

/// Seam over `URLSession` so tests can supply canned responses.
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {}

/// Thin JSON client for our backend. Knows nothing about products.
public struct APIClient: Sendable {
    private let baseURL: URL
    private let transport: HTTPTransport
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(baseURL: URL, transport: HTTPTransport = URLSession.shared) {
        self.baseURL = baseURL
        self.transport = transport
    }

    public func get<Response: Decodable>(
        _ path: String, query: [URLQueryItem] = [], as _: Response.Type = Response.self
    ) async throws(APIError) -> Response {
        var request = URLRequest(url: url(path, query: query))
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await send(request)
    }

    public func post<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body, as _: Response.Type = Response.self
    ) async throws(APIError) -> Response {
        var request = URLRequest(url: url(path, query: []))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw .invalidResponse
        }
        return try await send(request)
    }

    private func url(_ path: String, query: [URLQueryItem]) -> URL {
        let url = baseURL.appending(path: path)
        return query.isEmpty ? url : url.appending(queryItems: query)
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws(APIError) -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw .unreachable
        }

        guard let http = response as? HTTPURLResponse else { throw .invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw serverError(status: http.statusCode, data: data)
        }
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw .invalidResponse
        }
    }

    private func serverError(status: Int, data: Data) -> APIError {
        struct Envelope: Decodable {
            struct Body: Decodable {
                let code: String
                let message: String
                let details: [APIError.FieldError]?
            }
            let error: Body
        }
        guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
            return .server(status: status, code: "UNKNOWN", message: "Unexpected error", fieldErrors: [])
        }
        let body = envelope.error
        return .server(status: status, code: body.code, message: body.message, fieldErrors: body.details ?? [])
    }
}
