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
    static let maxTags = 5
    static let maxTagLength = 24
    static let minIntensity = 1
    static let maxIntensity = 5

    static func validate(
        title: String,
        mood: Mood?,
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
        let cleanTakeaway = takeaway.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanQuote = quote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let cleanTags = normalizedTags(tags)

        if cleanTitle.isEmpty {
            errors.append("Title is required.")
        }

        if cleanTitle.count > maxTitleLength {
            errors.append("Title must be \(maxTitleLength) characters or less.")
        }

        if let moodLabel = mood?.label,
           moodLabel.count > maxMoodLength {
            errors.append("Mood must be \(maxMoodLength) characters or less.")
        }

        if mood == nil {
            errors.append("Choose a mood.")
        }

        if cleanTakeaway.count > maxTakeawayLength {
            errors.append("Takeaway must be \(maxTakeawayLength) characters or less.")
        }

        if cleanQuote.count > maxQuoteLength {
            errors.append("Key moment must be \(maxQuoteLength) characters or less.")
        }

        if cleanTags.count > maxTags {
            errors.append("You can add up to \(maxTags) tags.")
        }

        if let invalidTag = cleanTags.first(where: { $0.count > maxTagLength }) {
            errors.append("#\(invalidTag) must be \(maxTagLength) characters or less.")
        }

        if intensity < minIntensity || intensity > maxIntensity {
            errors.append("Intensity must be between \(minIntensity) and \(maxIntensity).")
        }

        if watchContext == .cinema {
            validateCinemaValue(cinemaAudio, label: "Audio", errors: &errors)
            validateCinemaValue(cinemaScreen, label: "Screen", errors: &errors)
            validateCinemaValue(cinemaComfort, label: "Comfort", errors: &errors)
        }

        return Array(Set(errors)).sorted()
    }

    static func normalizedTags(_ tags: [String]) -> [String] {
        Array(
            Set(
                tags
                    .map { normalizeTag($0) }
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }

    static func normalizeTag(_ tag: String) -> String {
        tag
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.isEmpty == false }
            .joined(separator: "-")
    }

    private static func validateCinemaValue(
        _ value: Int?,
        label: String,
        errors: inout [String]
    ) {
        guard let value else {
            return
        }

        if value < minIntensity || value > maxIntensity {
            errors.append("\(label) must be between \(minIntensity) and \(maxIntensity).")
        }
    }
}
