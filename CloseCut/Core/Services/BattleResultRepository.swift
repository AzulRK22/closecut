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
    func createRandomPickResult(
        ownerId: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        try createResult(
            ownerId: ownerId,
            mode: .randomPick,
            title: "Random Pick",
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
            title: "Movie vs Movie",
            options: options,
            winner: winner,
            modelContext: modelContext
        )
    }

    func fetchLocalResults(
        ownerId: String,
        limit: Int? = nil,
        modelContext: ModelContext
    ) throws -> [BattleResult] {
        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.ownerId == ownerId
            },
            sortBy: [
                SortDescriptor(\LocalBattleResult.createdAt, order: .reverse)
            ]
        )

        let results = try modelContext.fetch(descriptor).map { $0.domain }

        if let limit {
            return Array(results.prefix(limit))
        }

        return results
    }

    func deleteResult(
        resultId: String,
        modelContext: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<LocalBattleResult>(
            predicate: #Predicate { result in
                result.id == resultId
            }
        )

        guard let result = try modelContext.fetch(descriptor).first else {
            return
        }

        modelContext.delete(result)
        try modelContext.save()
    }

    private func createResult(
        ownerId: String,
        mode: BattleMode,
        title: String,
        options: [Entry],
        winner: Entry,
        modelContext: ModelContext
    ) throws -> BattleResult {
        let cleanedOptions = options
            .filter {
                $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }

        guard cleanedOptions.contains(where: { $0.id == winner.id }) else {
            throw BattleResultRepositoryError.winnerNotInOptions
        }

        let localResult = LocalBattleResult(
            ownerId: ownerId,
            mode: mode,
            title: title,
            optionEntryIds: cleanedOptions.map { $0.id },
            optionTitles: cleanedOptions.map { $0.title },
            winnerEntryId: winner.id,
            winnerTitle: winner.title,
            createdAt: Date()
        )

        modelContext.insert(localResult)
        try modelContext.save()

        return localResult.domain
    }
}

enum BattleResultRepositoryError: LocalizedError {
    case winnerNotInOptions

    var errorDescription: String? {
        switch self {
        case .winnerNotInOptions:
            return "The selected winner must be one of the Battle options."
        }
    }
}
