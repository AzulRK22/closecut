//
//  FirestoreCircleMemberDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreCircleMemberDTO: Codable {
    var userId: String
    var displayName: String
    var email: String?
    var role: String
    var status: String
    var joinedAt: Timestamp
    var updatedAt: Timestamp
}

extension FirestoreCircleMemberDTO {
    init(member: CircleMember) {
        self.userId = member.userId
        self.displayName = member.displayName
        self.email = member.email
        self.role = member.role.rawValue
        self.status = member.status.rawValue
        self.joinedAt = Timestamp(date: member.joinedAt)
        self.updatedAt = Timestamp(date: member.updatedAt)
    }

    func domain() -> CircleMember {
        CircleMember(
            userId: userId,
            displayName: displayName,
            email: email,
            role: CircleMemberRole(rawValue: role) ?? .member,
            status: CircleMemberStatus(rawValue: status) ?? .active,
            joinedAt: joinedAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}
