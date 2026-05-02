//
//  CircleInviteCodeGenerator.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

enum CircleInviteCodeGenerator {
    static func generateCandidate(
        circleName: String,
        ownerDisplayName: String
    ) -> String {
        let preferredBase = circleName.normalizedInviteCode
        let fallbackBase = ownerDisplayName.normalizedInviteCode

        let base: String

        if preferredBase.isEmpty == false {
            base = String(preferredBase.prefix(5))
        } else if fallbackBase.isEmpty == false {
            base = String(fallbackBase.prefix(5))
        } else {
            base = "CLOSE"
        }

        return "\(base)-\(randomSuffix())"
    }

    static func generate(displayName: String, userId: String) -> String {
        let base = displayName.normalizedInviteCode

        let prefix: String

        if base.isEmpty {
            prefix = "CLOSE"
        } else {
            prefix = String(base.prefix(5))
        }

        return "\(prefix)-\(randomSuffix())"
    }

    private static func randomSuffix(length: Int = 5) -> String {
        let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

        return String(
            (0..<length).compactMap { _ in
                characters.randomElement()
            }
        )
    }
}
