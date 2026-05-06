//
//  TMDBClient.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBClientError: LocalizedError {
    case missingAccessToken
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed

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
        request.timeoutInterval = 20
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            #if DEBUG
            print("❌ TMDB status:", httpResponse.statusCode)
            print("❌ TMDB body:", String(data: data, encoding: .utf8) ?? "No body")
            #endif

            throw TMDBClientError.requestFailed(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            #if DEBUG
            print("❌ TMDB decoding error:", error.localizedDescription)
            print("❌ TMDB body:", String(data: data, encoding: .utf8) ?? "No body")
            #endif

            throw TMDBClientError.decodingFailed
        }
    }
}
