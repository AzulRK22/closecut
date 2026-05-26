//
//  String+Circle.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

extension String {
    var normalizedInviteCode: String {
        trimmed
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    var isValidInviteCodeCandidate: Bool {
        normalizedInviteCode.count >= 5
    }

    func formattedInviteCode(groupSize: Int = 5) -> String {
        let normalized = normalizedInviteCode

        guard groupSize > 0 else {
            return normalized
        }

        var groups: [String] = []
        var currentIndex = normalized.startIndex

        while currentIndex < normalized.endIndex {
            let nextIndex = normalized.index(
                currentIndex,
                offsetBy: groupSize,
                limitedBy: normalized.endIndex
            ) ?? normalized.endIndex

            groups.append(String(normalized[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }

        return groups.joined(separator: "-")
    }
}
