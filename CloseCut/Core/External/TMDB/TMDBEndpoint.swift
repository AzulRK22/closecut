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
    case discoverMovies(
        genreIds: [Int],
        page: Int = 1,
        language: String = "en-US",
        minimumVoteAverage: Double = 6.8
    )
    case discoverTV(
        genreIds: [Int],
        page: Int = 1,
        language: String = "en-US",
        minimumVoteAverage: Double = 6.8
    )

    var path: String {
        switch self {
        case .searchMulti:
            return "/search/multi"
        case .movieDetails(let id, _):
            return "/movie/\(id)"
        case .tvDetails(let id, _):
            return "/tv/\(id)"
        case .discoverMovies:
            return "/discover/movie"
        case .discoverTV:
            return "/discover/tv"
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

        case .discoverMovies(let genreIds, let page, let language, let minimumVoteAverage):
            return [
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "include_video", value: "false"),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "sort_by", value: "vote_average.desc"),
                URLQueryItem(name: "vote_count.gte", value: "80"),
                URLQueryItem(name: "vote_average.gte", value: "\(minimumVoteAverage)"),
                URLQueryItem(name: "with_genres", value: genreIds.map(String.init).joined(separator: ","))
            ]

        case .discoverTV(let genreIds, let page, let language, let minimumVoteAverage):
            return [
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "sort_by", value: "vote_average.desc"),
                URLQueryItem(name: "vote_count.gte", value: "80"),
                URLQueryItem(name: "vote_average.gte", value: "\(minimumVoteAverage)"),
                URLQueryItem(name: "with_genres", value: genreIds.map(String.init).joined(separator: ","))
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
