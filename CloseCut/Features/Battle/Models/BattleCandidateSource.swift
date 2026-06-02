//
//  BattleCandidateSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

enum BattleCandidateSource: String, Codable, Equatable {
    case archive
    case watchlist
    case tmdb
    case manual

    var displayName: String {
        switch self {
        case .archive:
            return "From Personal"
        case .watchlist:
            return "From Want to Watch"
        case .tmdb:
            return "TMDB"
        case .manual:
            return "Manual"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .archive:
            return "Personal"
        case .watchlist:
            return "Watchlist"
        case .tmdb:
            return "TMDB"
        case .manual:
            return "Manual"
        }
    }

    var systemImage: String {
        switch self {
        case .archive:
            return "film.stack"
        case .watchlist:
            return "bookmark.fill"
        case .tmdb:
            return "sparkles.tv"
        case .manual:
            return "plus.circle"
        }
    }
}
