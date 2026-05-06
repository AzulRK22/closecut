//
//  TMDBEndpoint.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBEndpoint {
    case searchMulti(query: String, page: Int = 1, language: String = "en-US")
    case movieDetails(id: Int, language: String = "en-US")
    case tvDetails(id: Int, language: String = "en-US")

    var path: String {
        switch self {
        case .searchMulti:
            return "/search/multi"
        case .movieDetails(let id, _):
            return "/movie/\(id)"
        case .tvDetails(let id, _):
            return "/tv/\(id)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchMulti(let query, let page, let language):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)")
            ]

        case .movieDetails(_, let language):
            return [
                URLQueryItem(name: "language", value: language)
            ]

        case .tvDetails(_, let language):
            return [
                URLQueryItem(name: "language", value: language)
            ]
        }
    }

    func url(baseURL: URL = TMDBConfiguration.apiBaseURL) throws -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw TMDBClientError.invalidURL
        }

        return url
    }
}
