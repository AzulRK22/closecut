//
//  Comment.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct Comment: Identifiable, Codable, Equatable {
    let id: String
    let entryId: String
    let userId: String

    var text: String

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    var isDeleted: Bool {
        deletedAt != nil
    }
}
