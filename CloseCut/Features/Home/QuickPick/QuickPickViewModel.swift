//
//  QuickPickViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation
import Combine

@MainActor
final class QuickPickViewModel: ObservableObject {
    @Published private(set) var state: QuickPickState = .insufficientHistory(
        currentCount: 0,
        targetCount: 3
    )

    private let engine = QuickPickEngine()

    func generate(history: [Entry]) {
        state = engine.generateSuggestion(history: history)
    }

    func refresh(history: [Entry]) {
        state = engine.generateSuggestion(history: history)
    }

    func resetSession() {
        engine.resetSession()
    }
}
