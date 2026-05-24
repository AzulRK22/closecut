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

    // MARK: - Create

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
        let cleanedOwnerId = ownerId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedOwnerId.isEmpty == false else {
            throw BattleResultRepositoryError.missingOwnerId
        }

        let cleanedOptions = cleanOptions(options)

        guard cleanedOptions.count >= minimumOptionCount(for: mode) else {
            throw BattleResultRepositoryError.notEnoughOptions
        }

        guard cleanedOptions.contains(where: { $0.id == winner.id }) else {
            throw BattleResultRepositoryError.winnerNotInOptions
        }

        let optionEntryIds = cleanedOptions.map(\.id)

        let isDuplicate = try hasRecentDuplicateResult(
            ownerId: cleanedOwnerId,
            mode: mode,
            optionEntryIds: optionEntryIds,
            winnerEntryId: winner.id,
            modelContext: modelContext
        )

        if isDuplicate {
            throw BattleResultRepositoryError.duplicateRecentResult
        }

        let cleanedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let localResult = LocalBattleResult(
            ownerId: cleanedOwnerId,
            mode: mode,
            title: cleanedTitle.isEmpty ? mode.displayName : cleanedTitle,
            optionEntryIds: optionEntryIds,
            optionTitles: cleanedOptions.map(\.title),
            winnerEntryId: winner.id,
            winnerTitle: winner.title,
            createdAt: Date()
        )

        modelContext.insert(localResult)
        try modelContext.save()

        return localResult.domain
    }

    // MARK: - Read

    func fetchLocalResults(
        ownerId: String,
        limit: Int? = nil,
        modelContext: ModelContext
    ) throws -> [BattleResult] {
        let cleanedOwnerId = ownerId.trimmingCharacters(in: .whitespacesAndNewlines)

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
        let cleanedResultId = resultId.trimmingCharacters(in: .whitespacesAndNewlines)

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
        let cleanedOwnerId = ownerId.trimmingCharacters(in: .whitespacesAndNewlines)

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

    private func hasRecentDuplicateResult(
        ownerId: String,
        mode: BattleMode,
        optionEntryIds: [String],
        winnerEntryId: String,
        within seconds: TimeInterval = 60,
        modelContext: ModelContext
    ) throws -> Bool {
        let cutoffDate = Date().addingTimeInterval(-seconds)
        let sortedOptionIds = optionEntryIds.sorted()

        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.ownerId == ownerId &&
                result.modeRaw == mode.rawValue &&
                result.winnerEntryId == winnerEntryId &&
                result.createdAt >= cutoffDate
            }
        )

        let recentResults = try modelContext.fetch(descriptor)

        return recentResults.contains { result in
            result.optionEntryIds.sorted() == sortedOptionIds
        }
    }

    // MARK: - Helpers

    private func cleanOptions(_ options: [Entry]) -> [Entry] {
        var seenIds = Set<String>()

        return options
            .filter { entry in
                let cleanedTitle = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)

                guard cleanedTitle.isEmpty == false else {
                    return false
                }

                guard entry.deletedAt == nil else {
                    return false
                }

                guard seenIds.contains(entry.id) == false else {
                    return false
                }

                seenIds.insert(entry.id)
                return true
            }
    }

    private func minimumOptionCount(for mode: BattleMode) -> Int {
        switch mode {
        case .randomPick:
            return 1
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
