//
//  CirclePreview.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

struct CirclePreview: Identifiable, Equatable {
    var id: String { circle.id }

    let circle: CloseCircle
    let currentUserMembership: CircleMember?

    var isAlreadyMember: Bool {
        currentUserMembership?.status == .active
    }

    var memberCountText: String {
        let count = circle.memberIds.count
        return count == 1 ? "1 member" : "\(count) members"
    }
}
