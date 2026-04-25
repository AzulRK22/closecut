//
//  Circle.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct Circle: Identifiable, Codable, Equatable {
    let id: String

    var ownerId: String
    var memberIds: [String]
    var inviteCode: String?

    var createdAt: Date
    var updatedAt: Date

    func contains(userId: String) -> Bool {
        memberIds.contains(userId)
    }
}
