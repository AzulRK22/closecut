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
    private var generationTask: Task<Void, Never>?

    func setInitialState(
        _ initialState: QuickPickState
    ) {
        generationTask?.cancel()
        state = initialState
    }

    func generate(history: [Entry]) {
        generationTask?.cancel()

        generationTask = Task {
            let newState = await engine.generateSuggestion(history: history)

            guard Task.isCancelled == false else {
                return
            }

            state = newState
        }
    }

    func refresh(history: [Entry]) {
        generate(history: history)
    }

    func resetSession() {
        generationTask?.cancel()
        engine.resetSession()
    }
}
