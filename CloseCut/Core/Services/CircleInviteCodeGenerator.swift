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

    private static let allowedSuffixCharacters = Array(
        "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    )

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

    // MARK: - Helpers

    private static func resolvedPrefix(
        preferredBase: String,
        fallbackBase: String
    ) -> String {
        let preferred = preferredBase.trimmed
        let fallback = fallbackBase.trimmed

        if preferred.isEmpty == false {
            return String(preferred.prefix(maxPrefixLength))
        }

        if fallback.isEmpty == false {
            return String(fallback.prefix(maxPrefixLength))
        }

        return fallbackPrefix
    }

    private static func randomSuffix(
        length: Int = defaultSuffixLength
    ) -> String {
        guard length > 0 else {
            return ""
        }

        return String(
            (0..<length).compactMap { _ in
                allowedSuffixCharacters.randomElement()
            }
        )
    }
}
