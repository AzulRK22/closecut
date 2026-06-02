//
//  BattleResultRepository.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation
import SwiftData

@MainActor
final class BattleResultRepository {

    // MARK: - Create Candidate-Backed Results

    func createCandidateResult(
        ownerId: String,
        mode: BattleMode,
        title: String? = nil,
        options: [BattleCandidate],
        winner: BattleCandidate,
        modelContext: ModelContext
    ) throws -> BattleResult {
        let cleanedOwnerId = ownerId.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            throw BattleResultRepositoryError.missingOwnerId
        }

        let cleanedOptions = cleanCandidates(options)

        guard cleanedOptions.count >= minimumOptionCount(for: mode) else {
            throw BattleResultRepositoryError.notEnoughOptions
        }

        guard cleanedOptions.contains(where: {
            $0.normalizedIdentityKey == winner.normalizedIdentityKey
        }) else {
            throw BattleResultRepositoryError.winnerNotInOptions
        }

        let optionCandidateIds = cleanedOptions.map(\.normalizedIdentityKey)
        let optionTitles = cleanedOptions.map(\.displayTitle)
        let optionSources = cleanedOptions.map { $0.source.rawValue }

        let optionEntryIds = cleanedOptions.compactMap { candidate in
            candidate.source == .archive ? candidate.sourceEntryId : nil
        }

        let winnerEntryId: String = {
            guard winner.source == .archive else {
                return ""
            }

            return winner.sourceEntryId ?? ""
        }()

        let isDuplicate = try hasRecentDuplicateCandidateResult(
            ownerId: cleanedOwnerId,
            mode: mode,
            optionCandidateIds: optionCandidateIds,
            winnerCandidateId: winner.normalizedIdentityKey,
            modelContext: modelContext
        )

        if isDuplicate {
            throw BattleResultRepositoryError.duplicateRecentResult
        }

        let cleanedTitle = title?.trimmed ?? ""

        let localResult = LocalBattleResult(
            ownerId: cleanedOwnerId,
            mode: mode,
            title: cleanedTitle.isEmpty ? mode.displayName : cleanedTitle,
            optionEntryIds: optionEntryIds,
            optionCandidateIds: optionCandidateIds,
            optionTitles: optionTitles,
            optionSources: optionSources,
            winnerEntryId: winnerEntryId,
            winnerCandidateId: winner.normalizedIdentityKey,
            winnerTitle: winner.displayTitle,
            winnerSourceRaw: winner.source.rawValue,
            createdAt: Date()
        )

        modelContext.insert(localResult)
        try modelContext.save()

        return localResult.domain
    }

    // MARK: - Legacy Entry-Backed Create API

    func createRandomPickResult(
        ownerId: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        try createResult(
            ownerId: ownerId,
            mode: .randomPick,
            title: BattleMode.randomPick.displayName,
            options: options,
            winner: winner,
            modelContext: modelContext
        )
    }

    func createHeadToHeadResult(
        ownerId: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        try createResult(
            ownerId: ownerId,
            mode: .headToHead,
            title: BattleMode.headToHead.displayName,
            options: options,
            winner: winner,
            modelContext: modelContext
        )
    }

    func createFriendResult(
        ownerId: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        try createResult(
            ownerId: ownerId,
            mode: .friend,
            title: BattleMode.friend.displayName,
            options: options,
            winner: winner,
            modelContext: modelContext
        )
    }

    func createCircleResult(
        ownerId: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        try createResult(
            ownerId: ownerId,
            mode: .circle,
            title: BattleMode.circle.displayName,
            options: options,
            winner: winner,
            modelContext: modelContext
        )
    }

    func createResult(
        ownerId: String,
        mode: BattleMode,
        title: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        let candidates = BattleCandidateMapper.candidates(from: options)

        guard let winnerCandidate = candidates.first(where: {
            $0.sourceEntryId == winner.id
        }) else {
            throw BattleResultRepositoryError.winnerNotInOptions
        }

        return try createCandidateResult(
            ownerId: ownerId,
            mode: mode,
            title: title,
            options: candidates,
            winner: winnerCandidate,
            modelContext: modelContext
        )
    }

    // MARK: - Read

    func fetchLocalResults(
        ownerId: String,
        limit: Int? = nil,
        modelContext: ModelContext
    ) throws -> [BattleResult] {
        let cleanedOwnerId = ownerId.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            return []
        }

        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.ownerId == cleanedOwnerId
            },
            sortBy: [
                SortDescriptor(\LocalBattleResult.createdAt, order: .reverse)
            ]
        )

        let results = try modelContext.fetch(descriptor).map { $0.domain }

        guard let limit, limit > 0 else {
            return results
        }

        return Array(results.prefix(limit))
    }

    func fetchRecentResult(
        ownerId: String,
        modelContext: ModelContext
    ) throws -> BattleResult? {
        try fetchLocalResults(
            ownerId: ownerId,
            limit: 1,
            modelContext: modelContext
        )
        .first
    }

    // MARK: - Delete

    func deleteResult(
        resultId: String,
        modelContext: ModelContext
    ) throws {
        let cleanedResultId = resultId.trimmed

        guard cleanedResultId.isEmpty == false else {
            return
        }

        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.id == cleanedResultId
            }
        )

        guard let result = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(result)
        try modelContext.save()
    }

    func deleteAllResults(
        ownerId: String,
        modelContext: ModelContext
    ) throws -> Int {
        let cleanedOwnerId = ownerId.trimmed

        guard cleanedOwnerId.isEmpty == false else {
            return 0
        }

        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.ownerId == cleanedOwnerId
            }
        )

        let results = try modelContext.fetch(descriptor)

        for result in results {
            modelContext.delete(result)
        }

        try modelContext.save()

        return results.count
    }

    // MARK: - Duplicate Protection

    private func hasRecentDuplicateCandidateResult(
        ownerId: String,
        mode: BattleMode,
        optionCandidateIds: [String],
        winnerCandidateId: String,
        within seconds: TimeInterval = 60,
        modelContext: ModelContext
    ) throws -> Bool {
        let cutoffDate = Date().addingTimeInterval(-seconds)
        let sortedOptionIds = optionCandidateIds.sorted()

        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.ownerId == ownerId &&
                result.modeRaw == mode.rawValue &&
                result.winnerCandidateId == winnerCandidateId &&
                result.createdAt >= cutoffDate
            }
        )

        let recentResults = try modelContext.fetch(descriptor)

        return recentResults.contains { result in
            result.optionCandidateIds.sorted() == sortedOptionIds
        }
    }

    // MARK: - Helpers

    private func cleanCandidates(
        _ candidates: [BattleCandidate]
    ) -> [BattleCandidate] {
        var seenKeys = Set<String>()
        var cleaned: [BattleCandidate] = []

        for candidate in candidates {
            let title = candidate.displayTitle.trimmed
            let key = candidate.normalizedIdentityKey.trimmed

            guard title.isEmpty == false else {
                continue
            }

            guard key.isEmpty == false else {
                continue
            }

            guard seenKeys.contains(key) == false else {
                continue
            }

            seenKeys.insert(key)
            cleaned.append(candidate)
        }

        return cleaned
    }

    private func minimumOptionCount(for mode: BattleMode) -> Int {
        switch mode {
        case .randomPick:
            return 2
        case .headToHead:
            return 2
        case .friend:
            return 2
        case .circle:
            return 2
        }
    }
}

enum BattleResultRepositoryError: LocalizedError {
    case missingOwnerId
    case notEnoughOptions
    case winnerNotInOptions
    case duplicateRecentResult

    var errorDescription: String? {
        switch self {
        case .missingOwnerId:
            return "A valid user is required to save this Battle result."
        case .notEnoughOptions:
            return "Not enough valid options were provided for this Battle."
        case .winnerNotInOptions:
            return "The selected winner must be one of the Battle options."
        case .duplicateRecentResult:
            return "This Battle result was already saved recently."
        }
    }
}
