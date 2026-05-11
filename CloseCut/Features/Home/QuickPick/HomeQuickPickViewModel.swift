//
//  HomeQuickPickViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import Foundation
import Combine

@MainActor
final class HomeQuickPickViewModel: ObservableObject {
    @Published private(set) var state: QuickPickState = .insufficientHistory(
        currentCount: 0,
        targetCount: 3
    )

    private let engine = QuickPickEngine()
    private var generationTask: Task<Void, Never>?
    private var lastStableKey: String?

    func generateStablePick(
        userId: String,
        history: [Entry]
    ) {
        let newKey = stableKey(
            userId: userId,
            history: history
        )

        guard newKey != lastStableKey else {
            return
        }

        lastStableKey = newKey

        generate(history: history)
    }

    func refresh(
        history: [Entry]
    ) {
        engine.resetSession()
        lastStableKey = nil
        generate(history: history)
    }

    func resetSession() {
        generationTask?.cancel()
        engine.resetSession()
        lastStableKey = nil
        state = .insufficientHistory(
            currentCount: 0,
            targetCount: 3
        )
    }

    private func generate(
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

    private func stableKey(
        userId: String,
        history: [Entry]
    ) -> String {
        let dayKey = Self.dayKey()

        let historyFingerprint = history
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
            .map { entry in
                [
                    entry.id,
                    "\(entry.updatedAt.timeIntervalSince1970)",
                    "\(entry.tmdbId ?? -1)",
                    entry.quickSentiment?.rawValue ?? "",
                    entry.visibility.rawValue,
                    entry.sharedCircleIds.joined(separator: ",")
                ]
                .joined(separator: "-")
            }
            .joined(separator: "|")

        return "\(userId)|\(dayKey)|\(historyFingerprint)"
    }

    private static func dayKey(
        date: Date = Date()
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        return formatter.string(from: date)
    }
}
