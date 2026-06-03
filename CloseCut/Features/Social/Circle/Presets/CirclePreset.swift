//
//  CirclePreset.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import Foundation

struct CirclePreset: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let systemImage: String

    static let friends = CirclePreset(
        id: "friends",
        title: "Friends",
        description: "For movies, series, and watch memories with close friends.",
        systemImage: "person.2.fill"
    )

    static let family = CirclePreset(
        id: "family",
        title: "Family",
        description: "For shared family watches, recommendations, and reactions.",
        systemImage: "house.fill"
    )

    static let partner = CirclePreset(
        id: "partner",
        title: "Partner",
        description: "For the shows, movies, and rewatches you share together.",
        systemImage: "heart.fill"
    )

    static let movieClub = CirclePreset(
        id: "movie-club",
        title: "Movie Club",
        description: "For group picks, shared reactions, and watch discussions.",
        systemImage: "popcorn.fill"
    )

    static let all: [CirclePreset] = [
        .friends,
        .partner,
        .family,
        .movieClub
    ]
}
