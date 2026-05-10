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
    static let members = "members"
    static let activity = "activity"
    static let reactions = "reactions"
    static let comments = "comments"

    // MARK: - Users

    static func user(_ userId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(users)
            .document(userId)
    }

    // MARK: - Entries

    static func entry(_ entryId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(entries)
            .document(entryId)
    }

    static func entriesCollection() -> CollectionReference {
        Firestore.firestore()
            .collection(entries)
    }

    static func entryReactions(_ entryId: String) -> CollectionReference {
        entry(entryId)
            .collection(reactions)
    }

    static func entryReaction(
        entryId: String,
        userId: String
    ) -> DocumentReference {
        entryReactions(entryId)
            .document(userId)
    }

    static func entryComments(_ entryId: String) -> CollectionReference {
        entry(entryId)
            .collection(comments)
    }

    static func entryComment(
        entryId: String,
        commentId: String
    ) -> DocumentReference {
        entryComments(entryId)
            .document(commentId)
    }

    // MARK: - Circles

    static func circle(_ circleId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(circles)
            .document(circleId)
    }

    static func circlesCollection() -> CollectionReference {
        Firestore.firestore()
            .collection(circles)
    }

    static func circleMembers(_ circleId: String) -> CollectionReference {
        circle(circleId)
            .collection(members)
    }

    static func circleMember(
        circleId: String,
        userId: String
    ) -> DocumentReference {
        circleMembers(circleId)
            .document(userId)
    }

    static func circleActivity(_ circleId: String) -> CollectionReference {
        circle(circleId)
            .collection(activity)
    }

    static func circleActivityDocument(
        circleId: String,
        activityId: String
    ) -> DocumentReference {
        circleActivity(circleId)
            .document(activityId)
    }

    // MARK: - Collection Groups

    static func membersCollectionGroup() -> Query {
        Firestore.firestore()
            .collectionGroup(members)
    }
}
