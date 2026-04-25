//
//  FirestorePaths.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

enum FirestorePaths {
    static let users = "users"
    static let entries = "entries"
    static let circles = "circles"
    static let inviteCodes = "inviteCodes"
    static let reactions = "reactions"
    static let comments = "comments"

    static func user(_ userId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(users)
            .document(userId)
    }

    static func entry(_ entryId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(entries)
            .document(entryId)
    }

    static func entryReactions(_ entryId: String) -> CollectionReference {
        entry(entryId)
            .collection(reactions)
    }

    static func reaction(entryId: String, userId: String) -> DocumentReference {
        entryReactions(entryId)
            .document(userId)
    }

    static func entryComments(_ entryId: String) -> CollectionReference {
        entry(entryId)
            .collection(comments)
    }

    static func comment(entryId: String, commentId: String) -> DocumentReference {
        entryComments(entryId)
            .document(commentId)
    }

    static func circle(_ circleId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(circles)
            .document(circleId)
    }

    static func inviteCode(_ code: String) -> DocumentReference {
        Firestore.firestore()
            .collection(inviteCodes)
            .document(code)
    }
}
