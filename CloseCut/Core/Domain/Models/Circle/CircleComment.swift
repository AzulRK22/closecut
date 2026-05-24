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

    var cleanedText: String {
        text.trimmed
    }

    var displayText: String {
        if isDeleted {
            return "Comment deleted"
        }

        return cleanedText.isEmpty ? "Empty comment" : cleanedText
    }

    var displayNameText: String {
        let cleaned = displayName.trimmed
        return cleaned.isEmpty ? "Circle member" : cleaned
    }

    var canDisplay: Bool {
        isDeleted == false && cleanedText.isEmpty == false
    }

    var isEdited: Bool {
        updatedAt.timeIntervalSince(createdAt) > 2
    }

    func isOwned(
        by userId: String
    ) -> Bool {
        self.userId.trimmed == userId.trimmed
    }
}
