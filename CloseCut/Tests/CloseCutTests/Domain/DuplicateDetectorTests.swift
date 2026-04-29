//
//  DuplicateDetectorTests.swift
//  CloseCutTests
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import XCTest
@testable import CloseCut

final class DuplicateDetectorTests: XCTestCase {

    func testDuplicateWhenNormalizedTitleTypeAndYearMatch() {
        let entry = makeEntry(
            title: "Past Lives",
            normalizedTitle: "past lives",
            type: .movie,
            releaseYear: 2023
        )

        let draft = QuickAddDraft(
            title: "Past Lives",
            type: .movie,
            releaseYear: 2023
        )

        XCTAssertTrue(
            DuplicateDetector.isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        )
    }

    func testDuplicateWithDifferentCasingAndSpacing() {
        let entry = makeEntry(
            title: "Past Lives",
            normalizedTitle: "past lives",
            type: .movie,
            releaseYear: 2023
        )

        let draft = QuickAddDraft(
            title: "  PAST   LIVES  ",
            type: .movie,
            releaseYear: 2023
        )

        XCTAssertTrue(
            DuplicateDetector.isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        )
    }

    func testNotDuplicateWhenTypeDiffers() {
        let entry = makeEntry(
            title: "The Bear",
            normalizedTitle: "the bear",
            type: .series,
            releaseYear: 2022
        )

        let draft = QuickAddDraft(
            title: "The Bear",
            type: .movie,
            releaseYear: 2022
        )

        XCTAssertFalse(
            DuplicateDetector.isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        )
    }

    func testNotDuplicateWhenReleaseYearDiffersAndBothYearsExist() {
        let entry = makeEntry(
            title: "Little Women",
            normalizedTitle: "little women",
            type: .movie,
            releaseYear: 2019
        )

        let draft = QuickAddDraft(
            title: "Little Women",
            type: .movie,
            releaseYear: 1994
        )

        XCTAssertFalse(
            DuplicateDetector.isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        )
    }

    func testDuplicateFallbackWhenReleaseYearIsMissing() {
        let entry = makeEntry(
            title: "Arrival",
            normalizedTitle: "arrival",
            type: .movie,
            releaseYear: nil
        )

        let draft = QuickAddDraft(
            title: "Arrival",
            type: .movie,
            releaseYear: 2016
        )

        XCTAssertTrue(
            DuplicateDetector.isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        )
    }

    func testDeletedEntryDoesNotCountAsDuplicate() {
        var entry = makeEntry(
            title: "Her",
            normalizedTitle: "her",
            type: .movie,
            releaseYear: 2013
        )

        entry.deletedAt = Date()

        let draft = QuickAddDraft(
            title: "Her",
            type: .movie,
            releaseYear: 2013
        )

        XCTAssertFalse(
            DuplicateDetector.isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        )
    }

    private func makeEntry(
        title: String,
        normalizedTitle: String,
        type: EntryType,
        releaseYear: Int?
    ) -> Entry {
        Entry(
            id: UUID().uuidString,
            ownerId: "user-1",
            title: title,
            normalizedTitle: normalizedTitle,
            type: type,
            releaseYear: releaseYear,
            mood: "Moved",
            quickSentiment: nil,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 3,
            watchContext: .home,
            watchedDateApprox: .recently,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: .privateOnly,
            sourceType: .fullEntry,
            watchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: .pending
        )
    }
}
