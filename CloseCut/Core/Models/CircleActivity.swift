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

    var createdAt: Date
}

enum CircleActivityType: String, Codable, CaseIterable {
    case circleCreated
    case circleUpdated
    case circleDeleted
    case memberJoined
    case memberLeft

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
        }
    }
}
