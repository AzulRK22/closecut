//
//  Array+Cleaning.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 24/05/26.
//

import Foundation

extension Array where Element == String {
    var cleanedUniqueIds: [String] {
        Array(
            Set(
                map(\.trimmed)
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }

    var cleanedUniqueTexts: [String] {
        Array(
            Set(
                map(\.trimmed)
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }

    var cleanedUniqueLowercasedTexts: [String] {
        Array(
            Set(
                map { $0.lowercasedTrimmed }
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }
}
