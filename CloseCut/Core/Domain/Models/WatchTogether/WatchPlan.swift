//
//  WatchPlan.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import Foundation

struct WatchPlan: Identifiable, Codable, Equatable {
    let id: String

    var ownerId: String
    var ownerDisplayName: String

    var circleId: String
    var circleName: String

    var title: String
    var note: String?

    var media: WatchPlanMediaSnapshot

    var proposedStartAt: Date?
    var proposedEndAt: Date?
    var proposedDateText: String?

    var locationType: WatchPlanLocationType
    var locationName: String?
    var locationAddress: String?
    var streamingService: String?

    var status: WatchPlanStatus
    var source: WatchPlanSource

    var invitedMemberIds: [String]
    var acceptedMemberIds: [String]
    var declinedMemberIds: [String]
    var maybeMemberIds: [String]

    var confirmedStartAt: Date?
    var confirmedEndAt: Date?

    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    // MARK: - State

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isActive: Bool {
        isDeleted == false
    }

    var isDraft: Bool {
        status == .draft
    }

    var isPending: Bool {
        status == .proposed
    }

    var isConfirmed: Bool {
        status == .confirmed
    }

    var isWatched: Bool {
        status == .watched
    }

    var isCanceled: Bool {
        status == .canceled
    }

    var hasConfirmedSchedule: Bool {
        confirmedStartAt != nil
    }

    var hasProposedSchedule: Bool {
        proposedStartAt != nil ||
        proposedDateText?.trimmed.isEmpty == false
    }

    var acceptedInviteeIds: [String] {
        acceptedMemberIds.filter { memberId in
            memberId.trimmed != ownerId.trimmed
        }
    }

    var hasAcceptedInvitees: Bool {
        acceptedInviteeIds.isEmpty == false
    }

    var pendingInviteeIds: [String] {
        let cleanedOwnerId = ownerId.trimmed

        let respondedIds = Set(
            WatchPlan.cleanIds(
                acceptedMemberIds + declinedMemberIds + maybeMemberIds
            )
        )

        return invitedMemberIds.filter { memberId in
            let cleanedMemberId = memberId.trimmed

            return cleanedMemberId.isEmpty == false &&
                cleanedMemberId != cleanedOwnerId &&
                respondedIds.contains(cleanedMemberId) == false
        }
    }

    var acceptedCountExcludingOwner: Int {
        acceptedInviteeIds.count
    }

    var pendingResponseCount: Int {
        pendingInviteeIds.count
    }

    var hasPendingResponses: Bool {
        pendingResponseCount > 0
    }

    var canBeConfirmed: Bool {
        isActive &&
        status == .proposed &&
        hasAcceptedInvitees
    }

    var canBeMarkedWatched: Bool {
        isActive &&
        status == .confirmed
    }

    // MARK: - Display

    var displayTitle: String {
        let cleaned = title.trimmed

        if cleaned.isEmpty == false {
            return cleaned
        }

        return "Watch \(media.displayTitle)"
    }

    var displayCircleName: String {
        let cleaned = circleName.trimmed
        return cleaned.isEmpty ? "Circle" : cleaned
    }

    var displayOwnerName: String {
        let cleaned = ownerDisplayName.trimmed
        return cleaned.isEmpty ? "Someone" : cleaned
    }

    var displayNote: String? {
        note?.trimmed.nilIfBlank
    }

    var scheduleText: String {
        if let confirmedStartAt {
            return confirmedStartAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
        }

        if let proposedStartAt {
            return proposedStartAt.formatted(
                date: .abbreviated,
                time: .shortened
            )
        }

        if let proposedDateText = proposedDateText?.trimmed.nilIfBlank {
            return proposedDateText
        }

        return "Date not set"
    }

    var locationText: String {
        switch locationType {
        case .inPerson:
            return locationName?.trimmed.nilIfBlank ?? "In person"

        case .streaming:
            return streamingService?.trimmed.nilIfBlank ?? "Streaming"

        case .hybrid:
            return "Hybrid"

        case .notDecided:
            return "Location not decided"
        }
    }

    var responseSummaryText: String {
        let accepted = acceptedCountExcludingOwner
        let declined = declinedMemberIds.filter { $0.trimmed != ownerId.trimmed }.count
        let maybe = maybeMemberIds.filter { $0.trimmed != ownerId.trimmed }.count

        var parts: [String] = []

        if accepted > 0 {
            parts.append("\(accepted) yes")
        }

        if maybe > 0 {
            parts.append("\(maybe) maybe")
        }

        if declined > 0 {
            parts.append("\(declined) no")
        }

        return parts.isEmpty ? "No responses yet" : parts.joined(separator: " • ")
    }

    var scheduleStatusText: String {
        switch status {
        case .draft:
            return "Draft"

        case .proposed:
            return "Waiting for responses"

        case .confirmed:
            return "Confirmed"

        case .watched:
            return "Watched"

        case .canceled:
            return "Canceled"
        }
    }

    var confirmationRequirementText: String {
        if status == .confirmed {
            return "Plan confirmed"
        }

        if status == .watched {
            return "Already watched together"
        }

        if status == .canceled {
            return "Plan canceled"
        }

        if hasAcceptedInvitees {
            return "Ready to confirm"
        }

        return "Waiting for at least one invited member to say yes"
    }

    var participantSummaryText: String {
        if acceptedCountExcludingOwner > 0 {
            return "\(acceptedCountExcludingOwner) accepted"
        }

        if pendingResponseCount > 0 {
            return "\(pendingResponseCount) waiting"
        }

        return "No invitee responses yet"
    }

    // MARK: - Helpers

    func responseType(
        for memberId: String
    ) -> WatchPlanResponseType? {
        let cleanedMemberId = memberId.trimmed

        if acceptedMemberIds.contains(cleanedMemberId) {
            return .accepted
        }

        if declinedMemberIds.contains(cleanedMemberId) {
            return .declined
        }

        if maybeMemberIds.contains(cleanedMemberId) {
            return .maybe
        }

        return nil
    }

    func isInvited(
        memberId: String
    ) -> Bool {
        invitedMemberIds.contains(memberId.trimmed)
    }

    func isParticipant(
        memberId: String
    ) -> Bool {
        acceptedMemberIds.contains(memberId.trimmed)
    }

    func isOwned(
        by userId: String
    ) -> Bool {
        ownerId.trimmed == userId.trimmed
    }

    mutating func normalizeForLocalUse() {
        ownerId = ownerId.trimmed
        ownerDisplayName = ownerDisplayName.trimmed
        circleId = circleId.trimmed
        circleName = circleName.trimmed
        title = displayTitle
        note = note?.trimmed.nilIfBlank

        locationName = locationName?.trimmed.nilIfBlank
        locationAddress = locationAddress?.trimmed.nilIfBlank
        streamingService = streamingService?.trimmed.nilIfBlank

        invitedMemberIds = Self.cleanIds(invitedMemberIds + [ownerId])
        acceptedMemberIds = Self.cleanIds(acceptedMemberIds)
        declinedMemberIds = Self.cleanIds(declinedMemberIds)
        maybeMemberIds = Self.cleanIds(maybeMemberIds)

        updatedAt = Date()
    }

    static func cleanIds(
        _ ids: [String]
    ) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmed }
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }
}

enum WatchPlanStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case proposed
    case confirmed
    case watched
    case canceled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .proposed:
            return "Proposed"
        case .confirmed:
            return "Confirmed"
        case .watched:
            return "Watched"
        case .canceled:
            return "Canceled"
        }
    }

    var systemImage: String {
        switch self {
        case .draft:
            return "pencil"
        case .proposed:
            return "paperplane.fill"
        case .confirmed:
            return "checkmark.seal.fill"
        case .watched:
            return "film.fill"
        case .canceled:
            return "xmark.circle.fill"
        }
    }
}

enum WatchPlanLocationType: String, Codable, CaseIterable, Identifiable {
    case notDecided
    case inPerson
    case streaming
    case hybrid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .notDecided:
            return "Not decided"
        case .inPerson:
            return "In person"
        case .streaming:
            return "Streaming"
        case .hybrid:
            return "Hybrid"
        }
    }

    var systemImage: String {
        switch self {
        case .notDecided:
            return "questionmark.circle"
        case .inPerson:
            return "mappin.and.ellipse"
        case .streaming:
            return "play.tv.fill"
        case .hybrid:
            return "person.2.wave.2.fill"
        }
    }
}

enum WatchPlanSource: String, Codable, CaseIterable, Identifiable {
    case circle
    case discover
    case watchlist
    case battle
    case entry
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circle:
            return "Circle"
        case .discover:
            return "Discover"
        case .watchlist:
            return "Want to Watch"
        case .battle:
            return "Battle"
        case .entry:
            return "Personal"
        case .manual:
            return "Manual"
        }
    }
}
