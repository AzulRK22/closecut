//
//  LibrarySearchPipelineTests.swift
//  CloseCutTests
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import XCTest
@testable import CloseCut

final class LibrarySearchPipelineTests: XCTestCase {

    func testFilterMoviesOnlyReturnsMovies() {
        let entries = [
            makeEntry(title: "Past Lives", type: .movie),
            makeEntry(title: "The Bear", type: .series)
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .movies,
            sort: .recent
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Past Lives")
    }

    func testFilterSeriesOnlyReturnsSeries() {
        let entries = [
            makeEntry(title: "Past Lives", type: .movie),
            makeEntry(title: "The Bear", type: .series)
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .series,
            sort: .recent
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "The Bear")
    }

    func testFilterSharedOnlyReturnsSharedEntries() {
        let entries = [
            makeEntry(title: "Private Entry", visibility: .privateOnly, sharedCircleIds: []),
            makeEntry(title: "Shared Entry", visibility: .circle, sharedCircleIds: ["circle-1"])
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .shared,
            sort: .recent
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Shared Entry")
    }

    func testFilterQuickAddOnlyReturnsQuickAdds() {
        let entries = [
            makeEntry(title: "Full Entry", sourceType: .fullEntry),
            makeEntry(title: "Quick Entry", sourceType: .quickAdd)
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .quickAdd,
            sort: .recent
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Quick Entry")
    }

    func testNeedsDetailsOnlyReturnsIncompleteQuickAdds() {
        let entries = [
            makeEntry(
                title: "Complete Quick Add",
                mood: "Moved",
                takeaway: "Strong memory",
                tags: ["memory"],
                sourceType: .quickAdd
            ),
            makeEntry(
                title: "Incomplete Quick Add",
                mood: "",
                takeaway: "",
                tags: [],
                sourceType: .quickAdd
            ),
            makeEntry(
                title: "Full Entry",
                mood: "",
                takeaway: "",
                tags: [],
                sourceType: .fullEntry
            )
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .needsDetails,
            sort: .recent
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Incomplete Quick Add")
    }

    func testSortAlphabeticalOrdersByTitle() {
        let entries = [
            makeEntry(title: "Zodiac"),
            makeEntry(title: "Arrival"),
            makeEntry(title: "Her")
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .all,
            sort: .alphabetical
        )

        XCTAssertEqual(result.map(\.title), ["Arrival", "Her", "Zodiac"])
    }

    func testSortYearOrdersNewestReleaseYearFirst() {
        let entries = [
            makeEntry(title: "Old", releaseYear: 1995),
            makeEntry(title: "New", releaseYear: 2023),
            makeEntry(title: "Middle", releaseYear: 2016)
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .all,
            sort: .year
        )

        XCTAssertEqual(result.map(\.title), ["New", "Middle", "Old"])
    }

    func testDeletedEntriesAreExcluded() {
        let entries = [
            makeEntry(title: "Visible"),
            makeEntry(title: "Deleted", deletedAt: Date())
        ]

        let result = LibrarySearchPipeline.process(
            entries: entries,
            query: "",
            filter: .all,
            sort: .recent
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Visible")
    }

    private func makeEntry(
        title: String,
        type: EntryType = .movie,
        releaseYear: Int? = nil,
        mood: String = "Moved",
        takeaway: String = "",
        tags: [String] = [],
        visibility: EntryVisibility = .privateOnly,
        sharedCircleIds: [String] = [],
        sourceType: EntrySourceType = .fullEntry,
        watchedAt: Date = Date(),
        deletedAt: Date? = nil
    ) -> Entry {
        Entry(
            id: UUID().uuidString,
            ownerId: "user-1",
            title: title,
            normalizedTitle: title.normalizedTitleKey,
            type: type,
            releaseYear: releaseYear,
            mood: mood,
            quickSentiment: nil,
            takeaway: takeaway,
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
            externalSourceRaw: nil,
            tmdbId: nil,
            tmdbMediaTypeRaw: nil,
            posterPath: nil,
            backdropPath: nil,
            overview: nil,
            tmdbRating: nil,
            tmdbPopularity: nil,
            tmdbGenreIds: [],
            watchedAt: watchedAt,
            createdAt: watchedAt,
            updatedAt: watchedAt,
            deletedAt: deletedAt,
            syncStatus: .pending
        )
    }
}
