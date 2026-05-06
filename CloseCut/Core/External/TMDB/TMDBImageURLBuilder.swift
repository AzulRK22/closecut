//
//  TMDBImageURLBuilder.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation

enum TMDBImageSize: String {
    case posterSmall = "w185"
    case posterMedium = "w342"
    case posterLarge = "w500"
    case backdropMedium = "w780"
    case original = "original"
}

enum TMDBImageURLBuilder {
    private static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!

    static func imageURL(
        path: String?,
        size: TMDBImageSize = .posterMedium
    ) -> URL? {
        guard let path,
              path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return nil
        }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path

        return imageBaseURL
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(normalizedPath)
    }
}
