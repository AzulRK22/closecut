//
//  TMDBConfiguration.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBConfiguration {
    // MARK: - Credentials

    static var readAccessToken: String {
        guard let token = Bundle.main.object(
            forInfoDictionaryKey: "TMDBReadAccessToken"
        ) as? String else {
            return ""
        }

        let cleanedToken = token.trimmed

        if cleanedToken == "$(TMDB_READ_ACCESS_TOKEN)" {
            return ""
        }

        return cleanedToken
    }

    static var hasValidReadAccessToken: Bool {
        readAccessToken.isEmpty == false
    }

    // MARK: - URLs

    static let apiBaseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!

    // MARK: - Request Defaults

    static let requestTimeout: TimeInterval = 20
    static let defaultPage = 1
    static let defaultLanguage = "en-US"

    // MARK: - Search

    static let minimumSearchQueryLength = 2
    static let maximumSearchResults = 10

    // MARK: - Discovery

    static let maximumDiscoveryGenreCount = 3

    // Preferred names.
    static let minimumDiscoveryVoteAverage = 6.8
    static let minimumDiscoveryVoteCount = 80

    // Compatibility aliases used by TMDBEndpoint.
    static let discoverMinimumVoteAverage = minimumDiscoveryVoteAverage
    static let discoverMinimumVoteCount = minimumDiscoveryVoteCount
}
