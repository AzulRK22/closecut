//
//  CircleInviteCodeGenerator.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

enum CircleInviteCodeGenerator {
    static func generate(displayName: String, userId: String) -> String {
        let base = displayName
            .normalizedInviteCode

        let prefix: String

        if base.isEmpty {
            prefix = "CLOSE"
        } else {
            prefix = String(base.prefix(5))
        }

        let suffix = String(userId.suffix(5)).uppercased()

        return "\(prefix)-\(suffix)"
    }
}
