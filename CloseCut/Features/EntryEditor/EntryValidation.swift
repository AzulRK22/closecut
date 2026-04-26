//
//  EntryValidation.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

enum EntryValidation {
    static let maxTitleLength = 120
    static let maxMoodLength = 40
    static let maxTakeawayLength = 280
    static let maxQuoteLength = 240
    static let maxTags = 8
    static let minIntensity = 1
    static let maxIntensity = 5

    static func validate(
        title: String,
        mood: String,
        takeaway: String,
        quote: String?,
        tags: [String],
        intensity: Int,
        watchContext: WatchContext,
        cinemaAudio: Int?,
        cinemaScreen: Int?,
        cinemaComfort: Int?
    ) -> [String] {
        var errors: [String] = []

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMood = mood.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTakeaway = takeaway.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanQuote = quote?.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanTitle.isEmpty {
            errors.append("Title is required.")
        }

        if cleanTitle.count > maxTitleLength {
            errors.append("Title must be \(maxTitleLength) characters or less.")
        }

        if cleanMood.isEmpty {
            errors.append("Mood is required.")
        }

        if cleanMood.count > maxMoodLength {
            errors.append("Mood must be \(maxMoodLength) characters or less.")
        }

        if cleanTakeaway.isEmpty {
            errors.append("Takeaway is required.")
        }

        if cleanTakeaway.count > maxTakeawayLength {
            errors.append("Takeaway must be \(maxTakeawayLength) characters or less.")
        }

        if let cleanQuote, cleanQuote.count > maxQuoteLength {
            errors.append("Quote must be \(maxQuoteLength) characters or less.")
        }

        if tags.count > maxTags {
            errors.append("You can add up to \(maxTags) tags.")
        }

        if intensity < minIntensity || intensity > maxIntensity {
            errors.append("Intensity must be between \(minIntensity) and \(maxIntensity).")
        }

        if watchContext == .cinema {
            validateCinemaValue(cinemaAudio, label: "Audio", errors: &errors)
            validateCinemaValue(cinemaScreen, label: "Screen", errors: &errors)
            validateCinemaValue(cinemaComfort, label: "Comfort", errors: &errors)
        }

        return errors
    }

    private static func validateCinemaValue(
        _ value: Int?,
        label: String,
        errors: inout [String]
    ) {
        guard let value else { return }

        if value < 1 || value > 5 {
            errors.append("\(label) must be between 1 and 5.")
        }
    }
}
