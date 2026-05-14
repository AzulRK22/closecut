//
//  BattleCandidateSource.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import Foundation

enum BattleCandidateSource: String, Codable, Equatable {
    case archive
    case tmdb
    case manual

    var displayName: String {
        switch self {
        case .archive:
            return "From archive"
        case .tmdb:
            return "TMDB"
        case .manual:
            return "Manual"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .archive:
            return "Archive"
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
        case .tmdb:
            return "sparkles.tv"
        case .manual:
            return "plus.circle"
        }
    }
}
