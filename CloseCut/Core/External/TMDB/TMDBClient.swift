//
//  TMDBClient.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBClientError: LocalizedError, Equatable {
    case missingAccessToken
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed
    case networkUnavailable
    case requestTimedOut
    case requestCancelled
    case emptyData

    var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            return "TMDB access token is missing."

        case .invalidURL:
            return "TMDB request URL is invalid."

        case .invalidResponse:
            return "TMDB returned an invalid response."

        case .requestFailed(let statusCode):
            return "TMDB request failed with status code \(statusCode)."

        case .decodingFailed:
            return "TMDB response could not be decoded."

        case .networkUnavailable:
            return "Network unavailable. Please check your connection."

        case .requestTimedOut:
            return "TMDB request timed out. Please try again."

        case .requestCancelled:
            return "TMDB request was cancelled."

        case .emptyData:
            return "TMDB returned an empty response."
        }
    }
}

final class TMDBClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    func send<Response: Decodable>(
        _ endpoint: TMDBEndpoint
    ) async throws -> Response {
        let token = TMDBConfiguration.readAccessToken

        guard token.isEmpty == false else {
            throw TMDBClientError.missingAccessToken
        }

        let url = try endpoint.url()

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = TMDBConfiguration.requestTimeout
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw mapNetworkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            logFailedResponse(
                statusCode: httpResponse.statusCode,
                data: data
            )

            throw TMDBClientError.requestFailed(
                statusCode: httpResponse.statusCode
            )
        }

        guard data.isEmpty == false else {
            throw TMDBClientError.emptyData
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            logDecodingError(
                error: error,
                data: data
            )

            throw TMDBClientError.decodingFailed
        }
    }

    private func mapNetworkError(
        _ error: Error
    ) -> Error {
        let nsError = error as NSError

        guard nsError.domain == NSURLErrorDomain else {
            return error
        }

        switch nsError.code {
        case NSURLErrorTimedOut:
            return TMDBClientError.requestTimedOut

        case NSURLErrorCancelled:
            return TMDBClientError.requestCancelled

        case NSURLErrorNotConnectedToInternet,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorDNSLookupFailed:
            return TMDBClientError.networkUnavailable

        default:
            return error
        }
    }

    private func logFailedResponse(
        statusCode: Int,
        data: Data
    ) {
        #if DEBUG
        print("❌ TMDB status:", statusCode)
        print("❌ TMDB body:", debugBody(from: data))
        #endif
    }

    private func logDecodingError(
        error: Error,
        data: Data
    ) {
        #if DEBUG
        print("❌ TMDB decoding error:", error.localizedDescription)
        print("❌ TMDB body:", debugBody(from: data))
        #endif
    }

    private func debugBody(
        from data: Data,
        limit: Int = 2_000
    ) -> String {
        let body = String(data: data, encoding: .utf8) ?? "No body"

        guard body.count > limit else {
            return body
        }

        return String(body.prefix(limit)) + "…"
    }
}
