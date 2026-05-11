//
//  EntrySearchFilterTests.swift
//  CloseCutTests
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import XCTest
@testable import CloseCut

final class EntrySearchFilterTests: XCTestCase {

    func testEmptyQueryReturnsAllEntries() {
        let entries = [
            makeEntry(title: "Past Lives"),
            makeEntry(title: "Arrival")
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "   "
        )

        XCTAssertEqual(results.count, 2)
    }

    func testSearchMatchesTitle() {
        let entries = [
            makeEntry(title: "Past Lives"),
            makeEntry(title: "Arrival")
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "past"
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Past Lives")
    }

    func testSearchMatchesMood() {
        let entries = [
            makeEntry(title: "Past Lives", mood: "Nostalgic"),
            makeEntry(title: "Arrival", mood: "Inspired")
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "inspired"
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Arrival")
    }

    func testSearchMatchesTag() {
        let entries = [
            makeEntry(title: "Past Lives", tags: ["romance", "memory"]),
            makeEntry(title: "Arrival", tags: ["sci-fi"])
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "sci-fi"
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Arrival")
    }

    func testSearchMatchesReleaseYear() {
        let entries = [
            makeEntry(title: "Past Lives", releaseYear: 2023),
            makeEntry(title: "Arrival", releaseYear: 2016)
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "2016"
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Arrival")
    }

    func testSearchMatchesSharedStatus() {
        let entries = [
            makeEntry(
                title: "Past Lives",
                visibility: .circle,
                sharedCircleIds: ["circle-1"]
            ),
            makeEntry(title: "Arrival")
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "shared"
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Past Lives")
    }

    func testSearchMatchesQuickAddStatus() {
        let entries = [
            makeEntry(
                title: "Past Lives",
                sourceType: .quickAdd
            ),
            makeEntry(
                title: "Arrival",
                sourceType: .fullEntry
            )
        ]

        let results = EntrySearchFilter.filter(
            entries: entries,
            query: "quick add"
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Past Lives")
    }

    private func makeEntry(
        title: String,
        releaseYear: Int? = nil,
        mood: String = "Moved",
        tags: [String] = [],
        visibility: EntryVisibility = .privateOnly,
        sharedCircleIds: [String] = [],
        sourceType: EntrySourceType = .fullEntry
    ) -> Entry {
        Entry(
            id: UUID().uuidString,
            ownerId: "user-1",
            title: title,
            normalizedTitle: title.normalizedTitleKey,
            type: .movie,
            releaseYear: releaseYear,
            mood: mood,
            quickSentiment: nil,
            takeaway: "",
            quote: nil,
            tags: tags,
            intensity: 3,
            watchContext: .home,
            watchedDateApprox: .recently,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: visibility,
            sharedCircleIds: sharedCircleIds,
            sourceType: sourceType,
            externalSourceRaw: nil as String?,
            tmdbId: nil as Int?,
            tmdbMediaTypeRaw: nil as String?,
            posterPath: nil as String?,
            backdropPath: nil as String?,
            overview: nil as String?,
            tmdbRating: nil as Double?,
            tmdbPopularity: nil as Double?,
            tmdbGenreIds: [],
            watchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: .pending
        )
    }
}
