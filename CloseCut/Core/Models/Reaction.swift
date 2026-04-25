//
//  Reaction.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//


import Foundation

struct Reaction: Identifiable, Codable, Equatable {
    var id: String {
        "\(entryId)_\(userId)"
    }

    let entryId: String
    let userId: String

    var type: ReactionType

    var createdAt: Date
    var updatedAt: Date

    var syncStatus: SyncStatus
}
