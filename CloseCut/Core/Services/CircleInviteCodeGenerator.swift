//
//  CircleInviteCodeGenerator.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

enum CircleInviteCodeGenerator {
    private static let fallbackPrefix = "CLOSE"
    private static let maxPrefixLength = 5
    private static let defaultSuffixLength = 5
    private static let separator = "-"

    static func generateCandidate(
        circleName: String,
        ownerDisplayName: String
    ) -> String {
        let preferredBase = circleName.normalizedInviteCode
        let fallbackBase = ownerDisplayName.normalizedInviteCode

        let prefix = resolvedPrefix(
            preferredBase: preferredBase,
            fallbackBase: fallbackBase
        )

        return "\(prefix)\(separator)\(randomSuffix())"
    }

    static func generate(
        displayName: String,
        userId: String
    ) -> String {
        let preferredBase = displayName.normalizedInviteCode
        let fallbackBase = userId.normalizedInviteCode

        let prefix = resolvedPrefix(
            preferredBase: preferredBase,
            fallbackBase: fallbackBase
        )

        return "\(prefix)\(separator)\(randomSuffix())"
    }

    private static func resolvedPrefix(
        preferredBase: String,
        fallbackBase: String
    ) -> String {
        if preferredBase.isEmpty == false {
            return String(preferredBase.prefix(maxPrefixLength))
        }

        if fallbackBase.isEmpty == false {
            return String(fallbackBase.prefix(maxPrefixLength))
        }

        return fallbackPrefix
    }

    private static func randomSuffix(length: Int = defaultSuffixLength) -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        return String(
            (0..<length).compactMap { _ in
                characters.randomElement()
            }
        )
    }
}
