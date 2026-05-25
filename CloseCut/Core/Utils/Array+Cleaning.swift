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
}
