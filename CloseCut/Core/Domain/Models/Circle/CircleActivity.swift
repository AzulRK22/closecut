//
//  CircleActivity.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation

struct CircleActivity: Identifiable, Codable, Equatable {
    let id: String
    let circleId: String

    var type: CircleActivityType
    var actorId: String
    var actorDisplayName: String
    var message: String

    var entryId: String?
    var entryTitle: String?

    var createdAt: Date

    var displayActorName: String {
        let cleaned = actorDisplayName.trimmed
        return cleaned.isEmpty ? "Someone" : cleaned
    }

    var displayMessage: String {
        let cleaned = message.trimmed

        if cleaned.isEmpty == false {
            return cleaned
        }

        return type.defaultMessage(
            actorDisplayName: displayActorName,
            entryTitle: entryTitle
        )
    }

    var hasEntryReference: Bool {
        entryId?.trimmed.isEmpty == false ||
        entryTitle?.trimmed.isEmpty == false
    }
}

enum CircleActivityType: String, Codable, CaseIterable {
    case circleCreated
    case circleUpdated
    case circleDeleted
    case memberJoined
    case memberLeft

    case entryShared
    case entryUnshared
    case reactionAdded
    case commentAdded
    case battleCreated
    case battleCompleted

    var displayName: String {
        switch self {
        case .circleCreated:
            return "Circle created"
        case .circleUpdated:
            return "Circle updated"
        case .circleDeleted:
            return "Circle deleted"
        case .memberJoined:
            return "Member joined"
        case .memberLeft:
            return "Member left"
        case .entryShared:
            return "Entry shared"
        case .entryUnshared:
            return "Entry unshared"
        case .reactionAdded:
            return "Reaction added"
        case .commentAdded:
            return "Comment added"
        case .battleCreated:
            return "Battle started"
        case .battleCompleted:
            return "Battle completed"
        }
    }

    var systemImage: String {
        switch self {
        case .circleCreated:
            return "plus.circle.fill"
        case .circleUpdated:
            return "pencil.circle.fill"
        case .circleDeleted:
            return "trash.circle.fill"
        case .memberJoined:
            return "person.crop.circle.badge.plus"
        case .memberLeft:
            return "person.crop.circle.badge.minus"
        case .entryShared:
            return "square.and.arrow.up.fill"
        case .entryUnshared:
            return "eye.slash.fill"
        case .reactionAdded:
            return "face.smiling.fill"
        case .commentAdded:
            return "text.bubble.fill"
        case .battleCreated:
            return "gamecontroller.fill"
        case .battleCompleted:
            return "trophy.fill"
        }
    }

    var isDestructive: Bool {
        switch self {
        case .circleDeleted, .memberLeft, .entryUnshared:
            return true
        default:
            return false
        }
    }

    var isSocialSignal: Bool {
        switch self {
        case .memberJoined,
             .memberLeft,
             .entryShared,
             .entryUnshared,
             .reactionAdded,
             .commentAdded,
             .battleCreated,
             .battleCompleted:
            return true
        case .circleCreated, .circleUpdated, .circleDeleted:
            return false
        }
    }

    func defaultMessage(
        actorDisplayName: String,
        entryTitle: String?
    ) -> String {
        let actor = actorDisplayName.trimmed.isEmpty ? "Someone" : actorDisplayName.trimmed
        let title = entryTitle?.trimmed

        switch self {
        case .circleCreated:
            return "\(actor) created this Circle."
        case .circleUpdated:
            return "\(actor) updated this Circle."
        case .circleDeleted:
            return "\(actor) deleted this Circle."
        case .memberJoined:
            return "\(actor) joined this Circle."
        case .memberLeft:
            return "\(actor) left this Circle."
        case .entryShared:
            if let title, title.isEmpty == false {
                return "\(actor) shared \(title)."
            }
            return "\(actor) shared a memory."
        case .entryUnshared:
            if let title, title.isEmpty == false {
                return "\(actor) removed \(title) from this Circle."
            }
            return "\(actor) removed a shared memory."
        case .reactionAdded:
            if let title, title.isEmpty == false {
                return "\(actor) reacted to \(title)."
            }
            return "\(actor) reacted to a memory."
        case .commentAdded:
            if let title, title.isEmpty == false {
                return "\(actor) commented on \(title)."
            }
            return "\(actor) commented on a memory."
        case .battleCreated:
            return "\(actor) started a Battle."
        case .battleCompleted:
            return "\(actor) completed a Battle."
        }
    }
}
