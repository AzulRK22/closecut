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

    func testInsufficientHistoryWhenLessThanThreeEntries() async {
        let engine = QuickPickEngine()

        let state = await engine.generateSuggestion(
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

    func testReturnsSuggestionWhenHistoryHasAtLeastThreeEntries() async {
        let engine = QuickPickEngine()

        let state = await engine.generateSuggestion(
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
            XCTAssertFalse(suggestion.confidenceLabel.isEmpty)

        default:
            XCTFail("Expected a suggestion.")
        }
    }

    func testDoesNotRecommendAlreadyWatchedSeedAsWatchNext() async {
        let engine = QuickPickEngine()

        let state = await engine.generateSuggestion(
            history: [
                makeEntry(
                    title: "Before Sunrise",
                    normalizedTitle: "before sunrise",
                    mood: "Nostalgic"
                ),
                makeEntry(title: "Past Lives", mood: "Nostalgic"),
                makeEntry(title: "Aftersun", mood: "Moved")
            ]
        )

        switch state {
        case .suggestion(let suggestion), .noAlternatives(let suggestion):
            XCTAssertNotEqual(
                suggestion.candidate.normalizedIdentityKey,
                "before sunrise|movie"
            )

        default:
            XCTFail("Expected a suggestion.")
        }
    }

    func testRefreshAvoidsImmediateRepeatWhenAlternativesExist() async {
        let engine = QuickPickEngine()

        let history = [
            makeEntry(title: "Past Lives", mood: "Nostalgic"),
            makeEntry(title: "Aftersun", mood: "Moved"),
            makeEntry(title: "Arrival", mood: "Inspired")
        ]

        let firstState = await engine.generateSuggestion(history: history)
        let secondState = await engine.generateSuggestion(history: history)

        let firstTitle = suggestionTitle(from: firstState)
        let secondTitle = suggestionTitle(from: secondState)

        XCTAssertNotNil(firstTitle)
        XCTAssertNotNil(secondTitle)

        if let firstTitle, let secondTitle {
            XCTAssertNotEqual(firstTitle, secondTitle)
        }
    }

    func testResetSessionAllowsGeneratingAgain() async {
        let engine = QuickPickEngine()

        let history = [
            makeEntry(title: "Past Lives", mood: "Nostalgic"),
            makeEntry(title: "Aftersun", mood: "Moved"),
            makeEntry(title: "Arrival", mood: "Inspired")
        ]

        let firstState = await engine.generateSuggestion(history: history)
        let firstTitle = suggestionTitle(from: firstState)

        engine.resetSession()

        let resetState = await engine.generateSuggestion(history: history)
        let resetTitle = suggestionTitle(from: resetState)

        XCTAssertNotNil(firstTitle)
        XCTAssertNotNil(resetTitle)
    }

    private func suggestionTitle(
        from state: QuickPickState
    ) -> String? {
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
        mood: String = "Moved",
        type: EntryType = .movie,
        releaseYear: Int? = nil,
        quickSentiment: QuickSentiment? = .stayedWithMe,
        intensity: Int = 4,
        sourceType: EntrySourceType = .quickAdd,
        watchedAt: Date = Date(),
        updatedAt: Date = Date(),
        tmdbId: Int? = nil,
        tmdbRating: Double? = nil,
        tmdbGenreIds: [Int] = []
    ) -> Entry {
        Entry(
            id: UUID().uuidString,
            ownerId: "user-1",
            title: title,
            normalizedTitle: normalizedTitle ?? title.normalizedTitleKey,
            type: type,
            releaseYear: releaseYear,
            mood: mood,
            quickSentiment: quickSentiment,
            takeaway: "",
            quote: nil,
            tags: ["memory"],
            intensity: intensity,
            watchContext: .home,
            watchedDateApprox: .recently,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: .privateOnly,
            sharedCircleIds: [],
            sourceType: sourceType,
            externalSourceRaw: nil,
            tmdbId: tmdbId,
            tmdbMediaTypeRaw: nil,
            posterPath: nil,
            backdropPath: nil,
            overview: nil,
            tmdbRating: tmdbRating,
            tmdbPopularity: nil,
            tmdbGenreIds: tmdbGenreIds,
            watchedAt: watchedAt,
            createdAt: watchedAt,
            updatedAt: updatedAt,
            deletedAt: nil,
            syncStatus: .pending
        )
    }
}
