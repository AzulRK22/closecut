//
//  CirclePreview.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

struct CirclePreview: Identifiable, Equatable {
    var id: String {
        circle.id
    }

    let circle: CloseCircle
    let currentUserMembership: CircleMember?

    var isAlreadyMember: Bool {
        currentUserMembership?.status == .active
    }

    var isCurrentUserOwner: Bool {
        currentUserMembership?.role == .owner
    }

    var canJoin: Bool {
        circle.isActive && isAlreadyMember == false
    }

    var title: String {
        circle.displayName
    }

    var descriptionText: String {
        circle.displayDescription
    }

    var ownerText: String {
        circle.displayOwnerName
    }

    var memberCountText: String {
        circle.memberCountText
    }

    var accessStateTitle: String {
        if isAlreadyMember {
            return "You’re already in"
        }

        return "Circle found"
    }

    var accessStateMessage: String {
        if isCurrentUserOwner {
            return "You own this Circle."
        }

        if isAlreadyMember {
            return "You already have access to this Circle’s shared memories."
        }

        return "Joining gives you access to this Circle’s shared entries. It does not expose your Personal library."
    }

    var accessSystemImage: String {
        if isAlreadyMember {
            return "checkmark.circle.fill"
        }

        return "lock.fill"
    }
}
