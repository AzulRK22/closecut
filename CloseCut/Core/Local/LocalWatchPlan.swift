//
//  LocalWatchPlan.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation
import SwiftData

@Model
final class LocalWatchPlan {
    @Attribute(.unique) var id: String

    var ownerId: String
    var ownerDisplayName: String

    var circleId: String
    var circleName: String

    var title: String
    var note: String?

    var mediaId: String
    var mediaTitle: String
    var mediaNormalizedTitle: String
    var mediaTypeRaw: String
    var mediaReleaseYear: Int?

    var mediaSourceRaw: String
    var mediaSourceId: String?

    var mediaExternalSourceRaw: String?
    var mediaTMDBId: Int?
    var mediaTMDBMediaTypeRaw: String?
    var mediaPosterPath: String?
    var mediaBackdropPath: String?
    var mediaOverview: String?
    var mediaTMDBRating: Double?
    var mediaTMDBPopularity: Double?
    var mediaTMDBGenreIds: [Int]?

    var proposedStartAt: Date?
    var proposedEndAt: Date?
    var proposedDateText: String?

    var locationTypeRaw: String
    var locationName: String?
    var locationAddress: String?
    var streamingService: String?

    var statusRaw: String
    var sourceRaw: String

    var invitedMemberIds: [String]
    var acceptedMemberIds: [String]
    var declinedMemberIds: [String]
    var maybeMemberIds: [String]

    var confirmedStartAt: Date?
    var confirmedEndAt: Date?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        ownerDisplayName: String,
        circleId: String,
        circleName: String,
        title: String,
        note: String? = nil,
        media: WatchPlanMediaSnapshot,
        proposedStartAt: Date? = nil,
        proposedEndAt: Date? = nil,
        proposedDateText: String? = nil,
        locationType: WatchPlanLocationType = .notDecided,
        locationName: String? = nil,
        locationAddress: String? = nil,
        streamingService: String? = nil,
        status: WatchPlanStatus = .proposed,
        source: WatchPlanSource = .circle,
        invitedMemberIds: [String] = [],
        acceptedMemberIds: [String] = [],
        declinedMemberIds: [String] = [],
        maybeMemberIds: [String] = [],
        confirmedStartAt: Date? = nil,
        confirmedEndAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id

        self.ownerId = ownerId.trimmed
        self.ownerDisplayName = ownerDisplayName.trimmed

        self.circleId = circleId.trimmed
        self.circleName = circleName.trimmed

        self.title = title.trimmed
        self.note = note?.trimmed.nilIfBlank

        self.mediaId = media.id
        self.mediaTitle = media.title
        self.mediaNormalizedTitle = media.normalizedTitle
        self.mediaTypeRaw = media.type.rawValue
        self.mediaReleaseYear = media.releaseYear

        self.mediaSourceRaw = media.sourceRaw
        self.mediaSourceId = media.sourceId

        self.mediaExternalSourceRaw = media.externalSourceRaw
        self.mediaTMDBId = media.tmdbId
        self.mediaTMDBMediaTypeRaw = media.tmdbMediaTypeRaw
        self.mediaPosterPath = media.posterPath
        self.mediaBackdropPath = media.backdropPath
        self.mediaOverview = media.overview
        self.mediaTMDBRating = media.tmdbRating
        self.mediaTMDBPopularity = media.tmdbPopularity
        self.mediaTMDBGenreIds = media.tmdbGenreIds

        self.proposedStartAt = proposedStartAt
        self.proposedEndAt = proposedEndAt
        self.proposedDateText = proposedDateText?.trimmed.nilIfBlank

        self.locationTypeRaw = locationType.rawValue
        self.locationName = locationName?.trimmed.nilIfBlank
        self.locationAddress = locationAddress?.trimmed.nilIfBlank
        self.streamingService = streamingService?.trimmed.nilIfBlank

        self.statusRaw = status.rawValue
        self.sourceRaw = source.rawValue

        self.invitedMemberIds = WatchPlan.cleanIds(invitedMemberIds)
        self.acceptedMemberIds = WatchPlan.cleanIds(acceptedMemberIds)
        self.declinedMemberIds = WatchPlan.cleanIds(declinedMemberIds)
        self.maybeMemberIds = WatchPlan.cleanIds(maybeMemberIds)

        self.confirmedStartAt = confirmedStartAt
        self.confirmedEndAt = confirmedEndAt

        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt

        self.syncStatusRaw = syncStatus.rawValue
    }
}

extension LocalWatchPlan {
    var mediaSnapshot: WatchPlanMediaSnapshot {
        WatchPlanMediaSnapshot(
            id: mediaId,
            title: mediaTitle,
            normalizedTitle: mediaNormalizedTitle,
            type: EntryType(rawValue: mediaTypeRaw) ?? .movie,
            releaseYear: mediaReleaseYear,
            source: WatchPlanMediaSource(rawValue: mediaSourceRaw) ?? .manual,
            sourceId: mediaSourceId,
            externalMetadata: mediaExternalMetadata,
            overview: mediaOverview,
            tmdbRating: mediaTMDBRating,
            tmdbPopularity: mediaTMDBPopularity,
            tmdbGenreIds: mediaTMDBGenreIds ?? []
        )
    }

    var mediaExternalMetadata: EntryExternalMetadata? {
        guard let mediaTMDBId,
              let mediaTMDBMediaTypeRaw else {
            return nil
        }

        return EntryExternalMetadata(
            source: ExternalMediaSource(rawValue: mediaExternalSourceRaw ?? "") ?? .tmdb,
            tmdbId: mediaTMDBId,
            tmdbMediaTypeRaw: mediaTMDBMediaTypeRaw,
            posterPath: mediaPosterPath,
            backdropPath: mediaBackdropPath,
            overview: mediaOverview,
            tmdbRating: mediaTMDBRating,
            tmdbPopularity: mediaTMDBPopularity,
            tmdbGenreIds: mediaTMDBGenreIds ?? []
        )
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
            media: mediaSnapshot,
            proposedStartAt: proposedStartAt,
            proposedEndAt: proposedEndAt,
            proposedDateText: proposedDateText,
            locationType: WatchPlanLocationType(rawValue: locationTypeRaw) ?? .notDecided,
            locationName: locationName,
            locationAddress: locationAddress,
            streamingService: streamingService,
            status: WatchPlanStatus(rawValue: statusRaw) ?? .proposed,
            source: WatchPlanSource(rawValue: sourceRaw) ?? .circle,
            invitedMemberIds: invitedMemberIds,
            acceptedMemberIds: acceptedMemberIds,
            declinedMemberIds: declinedMemberIds,
            maybeMemberIds: maybeMemberIds,
            confirmedStartAt: confirmedStartAt,
            confirmedEndAt: confirmedEndAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(from plan: WatchPlan) {
        ownerId = plan.ownerId
        ownerDisplayName = plan.ownerDisplayName

        circleId = plan.circleId
        circleName = plan.circleName

        title = plan.title
        note = plan.note

        mediaId = plan.media.id
        mediaTitle = plan.media.title
        mediaNormalizedTitle = plan.media.normalizedTitle
        mediaTypeRaw = plan.media.type.rawValue
        mediaReleaseYear = plan.media.releaseYear

        mediaSourceRaw = plan.media.sourceRaw
        mediaSourceId = plan.media.sourceId

        mediaExternalSourceRaw = plan.media.externalSourceRaw
        mediaTMDBId = plan.media.tmdbId
        mediaTMDBMediaTypeRaw = plan.media.tmdbMediaTypeRaw
        mediaPosterPath = plan.media.posterPath
        mediaBackdropPath = plan.media.backdropPath
        mediaOverview = plan.media.overview
        mediaTMDBRating = plan.media.tmdbRating
        mediaTMDBPopularity = plan.media.tmdbPopularity
        mediaTMDBGenreIds = plan.media.tmdbGenreIds

        proposedStartAt = plan.proposedStartAt
        proposedEndAt = plan.proposedEndAt
        proposedDateText = plan.proposedDateText

        locationTypeRaw = plan.locationType.rawValue
        locationName = plan.locationName
        locationAddress = plan.locationAddress
        streamingService = plan.streamingService

        statusRaw = plan.status.rawValue
        sourceRaw = plan.source.rawValue

        invitedMemberIds = WatchPlan.cleanIds(plan.invitedMemberIds)
        acceptedMemberIds = WatchPlan.cleanIds(plan.acceptedMemberIds)
        declinedMemberIds = WatchPlan.cleanIds(plan.declinedMemberIds)
        maybeMemberIds = WatchPlan.cleanIds(plan.maybeMemberIds)

        confirmedStartAt = plan.confirmedStartAt
        confirmedEndAt = plan.confirmedEndAt

        createdAt = plan.createdAt
        updatedAt = plan.updatedAt
        deletedAt = plan.deletedAt

        syncStatusRaw = plan.syncStatus.rawValue
    }
}
