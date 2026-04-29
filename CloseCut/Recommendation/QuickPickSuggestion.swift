//
//  QuickPickSuggestion.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

struct QuickPickSuggestion: Identifiable, Equatable {
    let id: String
    let candidate: SuggestionCandidate
    let reason: String
    let reasonCode: QuickPickReasonCode
    let generatedAt: Date

    init(
        id: String = UUID().uuidString,
        candidate: SuggestionCandidate,
        reason: String,
        reasonCode: QuickPickReasonCode,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.candidate = candidate
        self.reason = reason
        self.reasonCode = reasonCode
        self.generatedAt = generatedAt
    }
}

enum QuickPickReasonCode: String, Codable {
    case insufficientHistory
    case moodContinuity
    case moodContrast
    case tagAffinity
    case strongSentiment
    case highIntensity
    case rewatchCandidate
    case fallback
}

enum QuickPickState: Equatable {
    case insufficientHistory(currentCount: Int, targetCount: Int)
    case suggestion(QuickPickSuggestion)
    case noAlternatives(QuickPickSuggestion)
    case error(String)
}
