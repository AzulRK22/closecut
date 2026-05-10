//
//  CircleComment.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation

struct CircleComment: Identifiable, Codable, Equatable {
    let id: String
    var entryId: String
    var circleId: String
    var userId: String
    var displayName: String
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var isDeleted: Bool {
        deletedAt != nil
    }
}
