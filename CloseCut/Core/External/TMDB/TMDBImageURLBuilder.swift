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
    case backdropLarge = "w1280"
    case original = "original"
}

enum TMDBImageURLBuilder {
    static func imageURL(
        path: String?,
        size: TMDBImageSize = .posterMedium
    ) -> URL? {
        guard let path else {
            return nil
        }

        let cleanedPath = path.trimmed

        guard cleanedPath.isEmpty == false else {
            return nil
        }

        let normalizedPath = cleanedPath.hasPrefix("/")
            ? String(cleanedPath.dropFirst())
            : cleanedPath

        return TMDBConfiguration.imageBaseURL
            .appendingPathComponent(size.rawValue)
            .appendingPathComponent(normalizedPath)
    }
}
