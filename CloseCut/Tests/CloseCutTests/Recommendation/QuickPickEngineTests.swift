//
//  QuickPickEngineTests.swift
//  CloseCutTests
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import XCTest
@testable import CloseCut

@MainActor
final class QuickPickEngineTests: XCTestCase {

    func testInsufficientHistoryWhenLessThanThreeEntries() {
        let engine = QuickPickEngine()

        let state = engine.generateSuggestion(
            history: [
                makeEntry(title: "Past Lives"),
                makeEntry(title: "Aftersun")
            ]
        )

        switch state {
        case .insufficientHistory(let currentCount, let targetCount):
            XCTAssertEqual(currentCount, 2)
            XCTAssertEqual(targetCount, 3)
        default:
            XCTFail("Expected insufficient history.")
        }
    }

    func testReturnsSuggestionWhenHistoryHasAtLeastThreeEntries() {
        let engine = QuickPickEngine()

        let state = engine.generateSuggestion(
            history: [
                makeEntry(title: "Past Lives", mood: "Nostalgic"),
                makeEntry(title: "Aftersun", mood: "Nostalgic"),
                makeEntry(title: "Arrival", mood: "Inspired")
            ]
        )

        switch state {
        case .suggestion(let suggestion), .noAlternatives(let suggestion):
            XCTAssertFalse(suggestion.candidate.title.isEmpty)
            XCTAssertFalse(suggestion.reason.isEmpty)
        default:
            XCTFail("Expected a suggestion.")
        }
    }

    func testDoesNotRecommendAlreadyWatchedSeedAsWatchNext() {
        let engine = QuickPickEngine()

        let state = engine.generateSuggestion(
            history: [
                makeEntry(title: "Before Sunrise", normalizedTitle: "before sunrise", mood: "Nostalgic"),
                makeEntry(title: "Past Lives", mood: "Nostalgic"),
                makeEntry(title: "Aftersun", mood: "Moved")
            ]
        )

        switch state {
        case .suggestion(let suggestion), .noAlternatives(let suggestion):
            XCTAssertNotEqual(suggestion.candidate.title, "Before Sunrise")
        default:
            XCTFail("Expected a suggestion.")
        }
    }

    func testRefreshAvoidsImmediateRepeatWhenAlternativesExist() {
        let engine = QuickPickEngine()

        let history = [
            makeEntry(title: "Past Lives", mood: "Nostalgic"),
            makeEntry(title: "Aftersun", mood: "Moved"),
            makeEntry(title: "Arrival", mood: "Inspired")
        ]

        let firstState = engine.generateSuggestion(history: history)
        let secondState = engine.generateSuggestion(history: history)

        let firstTitle = suggestionTitle(from: firstState)
        let secondTitle = suggestionTitle(from: secondState)

        XCTAssertNotNil(firstTitle)
        XCTAssertNotNil(secondTitle)

        if firstTitle != nil, secondTitle != nil {
            XCTAssertNotEqual(firstTitle, secondTitle)
        }
    }

    private func suggestionTitle(from state: QuickPickState) -> String? {
        switch state {
        case .suggestion(let suggestion), .noAlternatives(let suggestion):
            return suggestion.candidate.title
        default:
            return nil
        }
    }

    private func makeEntry(
        title: String,
        normalizedTitle: String? = nil,
        mood: String = "Moved"
    ) -> Entry {
        Entry(
            id: UUID().uuidString,
            ownerId: "user-1",
            title: title,
            normalizedTitle: normalizedTitle ?? title.normalizedTitleKey,
            type: .movie,
            releaseYear: nil,
            mood: mood,
            quickSentiment: .stayedWithMe,
            takeaway: "",
            quote: nil,
            tags: ["memory"],
            intensity: 4,
            watchContext: .home,
            watchedDateApprox: .recently,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: .privateOnly,
            sourceType: .quickAdd,
            watchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: .pending
        )
    }
}
