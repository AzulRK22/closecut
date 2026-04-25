//
//  LocalCircle.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalCircle {
    @Attribute(.unique) var id: String

    var ownerId: String
    var memberIds: [String]
    var inviteCode: String?

    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        ownerId: String,
        memberIds: [String],
        inviteCode: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.memberIds = memberIds
        self.inviteCode = inviteCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension LocalCircle {
    var domain: Circle {
        Circle(
            id: id,
            ownerId: ownerId,
            memberIds: memberIds,
            inviteCode: inviteCode,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
