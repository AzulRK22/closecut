//
//  TMDBEndpoint.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBEndpoint {
    case searchMulti(
        query: String,
        page: Int = TMDBConfiguration.defaultPage,
        language: String = TMDBConfiguration.defaultLanguage
    )

    case movieDetails(
        id: Int,
        language: String = TMDBConfiguration.defaultLanguage
    )

    case tvDetails(
        id: Int,
        language: String = TMDBConfiguration.defaultLanguage
    )

    case discoverMovies(
        genreIds: [Int],
        page: Int = TMDBConfiguration.defaultPage,
        language: String = TMDBConfiguration.defaultLanguage,
        minimumVoteAverage: Double = TMDBConfiguration.discoverMinimumVoteAverage
    )

    case discoverTV(
        genreIds: [Int],
        page: Int = TMDBConfiguration.defaultPage,
        language: String = TMDBConfiguration.defaultLanguage,
        minimumVoteAverage: Double = TMDBConfiguration.discoverMinimumVoteAverage
    )

    case trending(
        timeWindow: TMDBTrendingTimeWindow = .week,
        page: Int = TMDBConfiguration.defaultPage,
        language: String = TMDBConfiguration.defaultLanguage
    )

    case popularMovies(
        page: Int = TMDBConfiguration.defaultPage,
        language: String = TMDBConfiguration.defaultLanguage
    )

    case popularTV(
        page: Int = TMDBConfiguration.defaultPage,
        language: String = TMDBConfiguration.defaultLanguage
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

        case .trending(let timeWindow, _, _):
            return "/trending/all/\(timeWindow.rawValue)"

        case .popularMovies:
            return "/movie/popular"

        case .popularTV:
            return "/tv/popular"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .searchMulti(let query, let page, let language):
            return [
                URLQueryItem(name: "query", value: query.trimmed),
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
                URLQueryItem(name: "vote_count.gte", value: "\(TMDBConfiguration.discoverMinimumVoteCount)"),
                URLQueryItem(name: "vote_average.gte", value: "\(minimumVoteAverage)"),
                URLQueryItem(name: "with_genres", value: genreIds.uniqued().map(String.init).joined(separator: ","))
            ]

        case .discoverTV(let genreIds, let page, let language, let minimumVoteAverage):
            return [
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "sort_by", value: "vote_average.desc"),
                URLQueryItem(name: "vote_count.gte", value: "\(TMDBConfiguration.discoverMinimumVoteCount)"),
                URLQueryItem(name: "vote_average.gte", value: "\(minimumVoteAverage)"),
                URLQueryItem(name: "with_genres", value: genreIds.uniqued().map(String.init).joined(separator: ","))
            ]

        case .trending(_, let page, let language):
            return [
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)")
            ]

        case .popularMovies(let page, let language):
            return [
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)")
            ]

        case .popularTV(let page, let language):
            return [
                URLQueryItem(name: "language", value: language),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        }
    }

    func url(
        baseURL: URL = TMDBConfiguration.apiBaseURL
    ) throws -> URL {
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

enum TMDBTrendingTimeWindow: String {
    case day
    case week
}
