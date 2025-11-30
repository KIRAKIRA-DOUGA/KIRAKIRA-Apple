import Foundation
import OSLog

protocol APIServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func request<T: Decodable, U: Encodable>(_ endpoint: Endpoint, body: U?) async throws -> T
}

actor APIService: APIServiceProtocol {
    static let shared = APIService()

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private let logger = Logger(subsystem: "moe.kirakira", category: "API")

    private init() {
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        self.encoder = JSONEncoder()
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        return try await performRequest(endpoint, body: nil as String?)
    }

    func request<T: Decodable, U: Encodable>(_ endpoint: Endpoint, body: U?) async throws -> T {
        return try await performRequest(endpoint, body: body)
    }

    private func performRequest<T: Decodable, U: Encodable>(_ endpoint: Endpoint, body: U?) async throws -> T {
        guard let url = await endpoint.url else {
            logger.error("Invalid URL for endpoint")
            throw APIError.invalidURL
        }

        let endpointMethod = await endpoint.method
        logger.debug("\(endpointMethod.rawValue.uppercased()) \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = await endpoint.method.rawValue.uppercased()

        // Set body for POST requests
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (responseData, response) = try await URLSession.shared.data(for: request)
        logger.info("Received response from \(url.absoluteString)")

        // TODO: Handle 401 unauthorized globally

        guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("HTTP Error: \(statusCode) for URL \(url.absoluteString)")
            throw APIError.httpError(statusCode: statusCode)
        }

        do {
            let decodedResponse = try decoder.decode(T.self, from: responseData)
            logger.debug("Decoded response successfully for \(url.absoluteString)")
            return decodedResponse
        } catch {
           logger.error("Decoding error for URL \(url.absoluteString): \(error)")
            throw APIError.decodingError(error)
        }
    }
}
