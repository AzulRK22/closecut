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

    func generate(
        history: [Entry]
    ) {
        generationTask?.cancel()

        generationTask = Task {
            let newState = await engine.generateSuggestion(
                history: history
            )

            guard Task.isCancelled == false else {
                return
            }

            state = newState
        }
    }

    func refreshAndReturnState(
        history: [Entry]
    ) async -> QuickPickState {
        generationTask?.cancel()

        let currentCandidateId = candidateId(from: state)
        var newState = await engine.generateSuggestion(
            history: history
        )

        if let currentCandidateId,
           candidateId(from: newState) == currentCandidateId {
            for _ in 0..<3 {
                let retryState = await engine.generateSuggestion(
                    history: history
                )

                if candidateId(from: retryState) != currentCandidateId {
                    newState = retryState
                    break
                }

                newState = retryState
            }
        }

        state = newState

        return newState
    }

    func resetSession() {
        generationTask?.cancel()
        engine.resetSession()
        state = .insufficientHistory(
            currentCount: 0,
            targetCount: 3
        )
    }

    private func candidateId(
        from state: QuickPickState
    ) -> String? {
        switch state {
        case .suggestion(let suggestion), .noAlternatives(let suggestion):
            return suggestion.candidate.id

        case .insufficientHistory, .error:
            return nil
        }
    }
}
