//
//  EntryValidationTests.swift
//  CloseCutTests
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import XCTest
@testable import CloseCut

final class EntryValidationTests: XCTestCase {

    func testValidEntryHasNoErrors() {
        let errors = EntryValidation.validate(
            title: "Past Lives",
            mood: .moved,
            takeaway: "It stayed with me.",
            quote: nil,
            tags: ["memory"],
            intensity: 4,
            watchContext: .home,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil
        )

        XCTAssertTrue(errors.isEmpty)
    }

    func testTitleIsRequired() {
        let errors = EntryValidation.validate(
            title: "   ",
            mood: .moved,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 3,
            watchContext: .home,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil
        )

        XCTAssertTrue(errors.contains("Title is required."))
    }

    func testMoodIsRequired() {
        let errors = EntryValidation.validate(
            title: "Past Lives",
            mood: nil,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 3,
            watchContext: .home,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil
        )

        XCTAssertTrue(errors.contains("Choose a mood."))
    }

    func testTooManyTagsReturnsError() {
        let errors = EntryValidation.validate(
            title: "Past Lives",
            mood: .moved,
            takeaway: "",
            quote: nil,
            tags: ["a", "b", "c", "d", "e", "f"],
            intensity: 3,
            watchContext: .home,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil
        )

        XCTAssertTrue(errors.contains("You can add up to 5 tags."))
    }

    func testInvalidIntensityReturnsError() {
        let errors = EntryValidation.validate(
            title: "Past Lives",
            mood: .moved,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 8,
            watchContext: .home,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil
        )

        XCTAssertTrue(errors.contains("Intensity must be between 1 and 5."))
    }

    func testInvalidCinemaValueReturnsError() {
        let errors = EntryValidation.validate(
            title: "Past Lives",
            mood: .moved,
            takeaway: "",
            quote: nil,
            tags: [],
            intensity: 3,
            watchContext: .cinema,
            cinemaAudio: 10,
            cinemaScreen: nil,
            cinemaComfort: nil
        )

        XCTAssertTrue(errors.contains("Audio must be between 1 and 5."))
    }
}
