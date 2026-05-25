//
//  TMDBConfiguration.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBConfiguration {
    static var readAccessToken: String {
        guard let token = Bundle.main.object(
            forInfoDictionaryKey: "TMDBReadAccessToken"
        ) as? String else {
            return ""
        }

        let cleaned = token.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned == "$(TMDB_READ_ACCESS_TOKEN)" {
            return ""
        }

        return cleaned
    }

    static var hasValidReadAccessToken: Bool {
        readAccessToken.isEmpty == false
    }

    static let apiBaseURL = URL(string: "https://api.themoviedb.org/3")!

    static let requestTimeout: TimeInterval = 20

    static let defaultPage = 1

    static let defaultLanguage = "en-US"

    static let discoverMinimumVoteAverage: Double = 6.8

    static let discoverMinimumVoteCount = 80
}
