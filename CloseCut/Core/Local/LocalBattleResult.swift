//
//  LocalBattleResult.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import Foundation
import SwiftData

@Model
final class LocalBattleResult {
    @Attribute(.unique) var id: String

    var ownerId: String
    var modeRaw: String
    var title: String

    // Legacy / Personal-backed result support.
    var optionEntryIds: [String]
    var winnerEntryId: String

    // Battle v2 candidate-backed result support.
    var optionCandidateIds: [String]
    var optionTitles: [String]
    var optionSources: [String]

    var winnerCandidateId: String
    var winnerTitle: String
    var winnerSourceRaw: String

    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        mode: BattleMode,
        title: String,
        optionEntryIds: [String] = [],
        optionCandidateIds: [String],
        optionTitles: [String],
        optionSources: [String],
        winnerEntryId: String = "",
        winnerCandidateId: String,
        winnerTitle: String,
        winnerSourceRaw: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.modeRaw = mode.rawValue
        self.title = title

        self.optionEntryIds = optionEntryIds
        self.winnerEntryId = winnerEntryId

        self.optionCandidateIds = optionCandidateIds
        self.optionTitles = optionTitles
        self.optionSources = optionSources

        self.winnerCandidateId = winnerCandidateId
        self.winnerTitle = winnerTitle
        self.winnerSourceRaw = winnerSourceRaw

        self.createdAt = createdAt
    }
}

extension LocalBattleResult {
    var domain: BattleResult {
        BattleResult(
            id: id,
            ownerId: ownerId,
            mode: BattleMode(rawValue: modeRaw) ?? .randomPick,
            title: title,
            optionEntryIds: optionEntryIds,
            winnerEntryId: winnerEntryId,
            optionCandidateIds: optionCandidateIds,
            optionTitles: optionTitles,
            optionSources: optionSources,
            winnerCandidateId: winnerCandidateId,
            winnerTitle: winnerTitle,
            winnerSourceRaw: winnerSourceRaw,
            createdAt: createdAt
        )
    }
}
