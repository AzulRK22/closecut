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

    deinit {
        generationTask?.cancel()
    }

    func generate(history: [Entry]) {
        generationTask?.cancel()

        let cleanedHistory = history
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

        generationTask = Task { [engine] in
            let newState = await engine.generateSuggestion(history: cleanedHistory)

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

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
    }
}
