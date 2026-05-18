//
//  AvatarPreset.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 15/05/26.
//

import SwiftUI

enum AvatarPreset: String, CaseIterable, Identifiable {
    case midnight
    case cinema
    case spark
    case rose
    case ocean
    case forest
    case violet
    case ember

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .midnight:
            return "Midnight"
        case .cinema:
            return "Cinema"
        case .spark:
            return "Spark"
        case .rose:
            return "Rose"
        case .ocean:
            return "Ocean"
        case .forest:
            return "Forest"
        case .violet:
            return "Violet"
        case .ember:
            return "Ember"
        }
    }

    var systemImage: String {
        switch self {
        case .midnight:
            return "moon.stars.fill"
        case .cinema:
            return "film.fill"
        case .spark:
            return "sparkles"
        case .rose:
            return "heart.fill"
        case .ocean:
            return "water.waves"
        case .forest:
            return "leaf.fill"
        case .violet:
            return "star.fill"
        case .ember:
            return "flame.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .midnight:
            return [
                Color(red: 0.12, green: 0.12, blue: 0.20),
                Color(red: 0.36, green: 0.32, blue: 0.78)
            ]

        case .cinema:
            return [
                Color(red: 0.12, green: 0.10, blue: 0.10),
                Color(red: 0.88, green: 0.54, blue: 0.26)
            ]

        case .spark:
            return [
                Color(red: 0.44, green: 0.24, blue: 0.86),
                Color(red: 0.95, green: 0.55, blue: 0.86)
            ]

        case .rose:
            return [
                Color(red: 0.58, green: 0.18, blue: 0.32),
                Color(red: 0.96, green: 0.50, blue: 0.60)
            ]

        case .ocean:
            return [
                Color(red: 0.10, green: 0.35, blue: 0.60),
                Color(red: 0.16, green: 0.76, blue: 0.82)
            ]

        case .forest:
            return [
                Color(red: 0.10, green: 0.36, blue: 0.24),
                Color(red: 0.56, green: 0.78, blue: 0.42)
            ]

        case .violet:
            return [
                Color(red: 0.26, green: 0.18, blue: 0.58),
                Color(red: 0.66, green: 0.48, blue: 0.94)
            ]

        case .ember:
            return [
                Color(red: 0.54, green: 0.20, blue: 0.10),
                Color(red: 0.96, green: 0.58, blue: 0.22)
            ]
        }
    }

    static let defaultPreset: AvatarPreset = .midnight

    static func preset(
        from rawValue: String?
    ) -> AvatarPreset {
        guard let rawValue,
              let preset = AvatarPreset(rawValue: rawValue) else {
            return .defaultPreset
        }

        return preset
    }
}
