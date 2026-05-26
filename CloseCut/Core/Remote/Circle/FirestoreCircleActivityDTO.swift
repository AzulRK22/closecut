//
//  FirestoreCircleActivityDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreCircleActivityDTO: Codable {
    var circleId: String
    var type: String
    var actorId: String
    var actorDisplayName: String
    var message: String
    var createdAt: Timestamp
}

extension FirestoreCircleActivityDTO {
    init(activity: CircleActivity) {
        self.circleId = activity.circleId
        self.type = activity.type.rawValue
        self.actorId = activity.actorId
        self.actorDisplayName = activity.actorDisplayName
        self.message = activity.message
        self.createdAt = Timestamp(date: activity.createdAt)
    }

    func domain(id: String) -> CircleActivity {
        CircleActivity(
            id: id,
            circleId: circleId,
            type: CircleActivityType(rawValue: type) ?? .circleUpdated,
            actorId: actorId,
            actorDisplayName: actorDisplayName,
            message: message,
            createdAt: createdAt.dateValue()
        )
    }
}
