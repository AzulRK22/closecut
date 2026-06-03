//
//  FirestoreWatchPlanDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreWatchPlanDTO: Codable {
    let id: String

    let ownerId: String
    let ownerDisplayName: String

    let circleId: String
    let circleName: String

    let title: String
    let note: String?

    let media: FirestoreWatchPlanMediaSnapshotDTO

    let proposedStartAt: Timestamp?
    let proposedEndAt: Timestamp?
    let proposedDateText: String?

    let locationTypeRaw: String
    let locationName: String?
    let locationAddress: String?
    let streamingService: String?

    let statusRaw: String
    let sourceRaw: String

    let invitedMemberIds: [String]
    let acceptedMemberIds: [String]
    let declinedMemberIds: [String]
    let maybeMemberIds: [String]

    let confirmedStartAt: Timestamp?
    let confirmedEndAt: Timestamp?

    let createdAt: Timestamp
    let updatedAt: Timestamp
    let deletedAt: Timestamp?

    init(plan: WatchPlan) {
        self.id = plan.id

        self.ownerId = plan.ownerId
        self.ownerDisplayName = plan.ownerDisplayName

        self.circleId = plan.circleId
        self.circleName = plan.circleName

        self.title = plan.title
        self.note = plan.note

        self.media = FirestoreWatchPlanMediaSnapshotDTO(
            media: plan.media
        )

        self.proposedStartAt = plan.proposedStartAt.map(Timestamp.init(date:))
        self.proposedEndAt = plan.proposedEndAt.map(Timestamp.init(date:))
        self.proposedDateText = plan.proposedDateText

        self.locationTypeRaw = plan.locationType.rawValue
        self.locationName = plan.locationName
        self.locationAddress = plan.locationAddress
        self.streamingService = plan.streamingService

        self.statusRaw = plan.status.rawValue
        self.sourceRaw = plan.source.rawValue

        self.invitedMemberIds = WatchPlan.cleanIds(plan.invitedMemberIds)
        self.acceptedMemberIds = WatchPlan.cleanIds(plan.acceptedMemberIds)
        self.declinedMemberIds = WatchPlan.cleanIds(plan.declinedMemberIds)
        self.maybeMemberIds = WatchPlan.cleanIds(plan.maybeMemberIds)

        self.confirmedStartAt = plan.confirmedStartAt.map(Timestamp.init(date:))
        self.confirmedEndAt = plan.confirmedEndAt.map(Timestamp.init(date:))

        self.createdAt = Timestamp(date: plan.createdAt)
        self.updatedAt = Timestamp(date: plan.updatedAt)
        self.deletedAt = plan.deletedAt.map(Timestamp.init(date:))
    }

    var domain: WatchPlan {
        WatchPlan(
            id: id,
            ownerId: ownerId,
            ownerDisplayName: ownerDisplayName,
            circleId: circleId,
            circleName: circleName,
            title: title,
            note: note,
            media: media.domain,
            proposedStartAt: proposedStartAt?.dateValue(),
            proposedEndAt: proposedEndAt?.dateValue(),
            proposedDateText: proposedDateText,
            locationType: WatchPlanLocationType(rawValue: locationTypeRaw) ?? .notDecided,
            locationName: locationName,
            locationAddress: locationAddress,
            streamingService: streamingService,
            status: WatchPlanStatus(rawValue: statusRaw) ?? .proposed,
            source: WatchPlanSource(rawValue: sourceRaw) ?? .circle,
            invitedMemberIds: WatchPlan.cleanIds(invitedMemberIds),
            acceptedMemberIds: WatchPlan.cleanIds(acceptedMemberIds),
            declinedMemberIds: WatchPlan.cleanIds(declinedMemberIds),
            maybeMemberIds: WatchPlan.cleanIds(maybeMemberIds),
            confirmedStartAt: confirmedStartAt?.dateValue(),
            confirmedEndAt: confirmedEndAt?.dateValue(),
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: .synced
        )
    }
}

struct FirestoreWatchPlanMediaSnapshotDTO: Codable {
    let id: String

    let title: String
    let normalizedTitle: String
    let typeRaw: String
    let releaseYear: Int?

    let sourceRaw: String
    let sourceId: String?

    let externalSourceRaw: String?
    let tmdbId: Int?
    let tmdbMediaTypeRaw: String?
    let posterPath: String?
    let backdropPath: String?
    let overview: String?
    let tmdbRating: Double?
    let tmdbPopularity: Double?
    let tmdbGenreIds: [Int]

    init(media: WatchPlanMediaSnapshot) {
        self.id = media.id

        self.title = media.title
        self.normalizedTitle = media.normalizedTitle
        self.typeRaw = media.type.rawValue
        self.releaseYear = media.releaseYear

        self.sourceRaw = media.sourceRaw
        self.sourceId = media.sourceId

        self.externalSourceRaw = media.externalSourceRaw
        self.tmdbId = media.tmdbId
        self.tmdbMediaTypeRaw = media.tmdbMediaTypeRaw
        self.posterPath = media.posterPath
        self.backdropPath = media.backdropPath
        self.overview = media.overview
        self.tmdbRating = media.tmdbRating
        self.tmdbPopularity = media.tmdbPopularity
        self.tmdbGenreIds = media.tmdbGenreIds
    }

    var domain: WatchPlanMediaSnapshot {
        let externalMetadata: EntryExternalMetadata? = {
            guard let tmdbId,
                  let tmdbMediaTypeRaw else {
                return nil
            }

            return EntryExternalMetadata(
                source: ExternalMediaSource(rawValue: externalSourceRaw ?? "") ?? .tmdb,
                tmdbId: tmdbId,
                tmdbMediaTypeRaw: tmdbMediaTypeRaw,
                posterPath: posterPath,
                backdropPath: backdropPath,
                overview: overview,
                tmdbRating: tmdbRating,
                tmdbPopularity: tmdbPopularity,
                tmdbGenreIds: tmdbGenreIds
            )
        }()

        return WatchPlanMediaSnapshot(
            id: id,
            title: title,
            normalizedTitle: normalizedTitle,
            type: EntryType(rawValue: typeRaw) ?? .movie,
            releaseYear: releaseYear,
            source: WatchPlanMediaSource(rawValue: sourceRaw) ?? .manual,
            sourceId: sourceId,
            externalMetadata: externalMetadata,
            overview: overview,
            tmdbRating: tmdbRating,
            tmdbPopularity: tmdbPopularity,
            tmdbGenreIds: tmdbGenreIds
        )
    }
}
