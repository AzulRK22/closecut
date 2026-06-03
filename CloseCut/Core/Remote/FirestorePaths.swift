//
//  FirestorePaths.swift
//  CloseCut
//

import Foundation
import FirebaseFirestore

enum FirestorePaths {
    static let users = "users"
    static let entries = "entries"
    static let watchlistItems = "watchlistItems"
    static let circles = "circles"
    static let members = "members"
    static let activity = "activity"
    static let reactions = "reactions"
    static let comments = "comments"

    static let watchPlans = "watchPlans"
    static let responses = "responses"

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

    // MARK: - Watchlist

    static func watchlistItem(_ itemId: String) -> DocumentReference {
        Firestore.firestore()
            .collection(watchlistItems)
            .document(itemId)
    }

    static func watchlistItemsCollection() -> CollectionReference {
        Firestore.firestore()
            .collection(watchlistItems)
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

    // MARK: - Watch Together

    static func circleWatchPlans(_ circleId: String) -> CollectionReference {
        circle(circleId)
            .collection(watchPlans)
    }

    static func circleWatchPlan(
        circleId: String,
        planId: String
    ) -> DocumentReference {
        circleWatchPlans(circleId)
            .document(planId)
    }

    static func watchPlanResponses(
        circleId: String,
        planId: String
    ) -> CollectionReference {
        circleWatchPlan(
            circleId: circleId,
            planId: planId
        )
        .collection(responses)
    }

    static func watchPlanResponse(
        circleId: String,
        planId: String,
        responseId: String
    ) -> DocumentReference {
        watchPlanResponses(
            circleId: circleId,
            planId: planId
        )
        .document(responseId)
    }

    // MARK: - Collection Groups

    static func membersCollectionGroup() -> Query {
        Firestore.firestore()
            .collectionGroup(members)
    }

    static func watchPlansCollectionGroup() -> Query {
        Firestore.firestore()
            .collectionGroup(watchPlans)
    }

    static func watchPlanResponsesCollectionGroup() -> Query {
        Firestore.firestore()
            .collectionGroup(responses)
    }
}
