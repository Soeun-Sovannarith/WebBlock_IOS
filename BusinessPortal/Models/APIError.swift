import Foundation

/// Error body returned by the backend: `{ "message": "..." }`.
struct APIError: Error, Codable, Hashable, Sendable, LocalizedError {
    let message: String

    var errorDescription: String? { message }
}

extension Error {
    /// The message to show the owner. API messages are shown as-is.
    var portalMessage: String {
        if let apiError = self as? APIError { return apiError.message }
        return "Something went wrong. Check your connection and try again."
    }
}

extension JSONDecoder {
    /// Decoder for API payloads: camelCase keys, ISO-8601 UTC dates.
    static var portalAPI: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var portalAPI: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
