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

    var optionEntryIds: [String]
    var optionTitles: [String]

    var winnerEntryId: String
    var winnerTitle: String

    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        mode: BattleMode,
        title: String,
        optionEntryIds: [String],
        optionTitles: [String],
        winnerEntryId: String,
        winnerTitle: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.ownerId = ownerId
        self.modeRaw = mode.rawValue
        self.title = title
        self.optionEntryIds = optionEntryIds
        self.optionTitles = optionTitles
        self.winnerEntryId = winnerEntryId
        self.winnerTitle = winnerTitle
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
            optionTitles: optionTitles,
            winnerEntryId: winnerEntryId,
            winnerTitle: winnerTitle,
            createdAt: createdAt
        )
    }
}
