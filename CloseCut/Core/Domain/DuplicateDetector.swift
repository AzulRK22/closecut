//
//  DuplicateDetector.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 27/04/26.
//

import Foundation

enum DuplicateDetector {

    // MARK: - Public API

    static func isDuplicate(
        draft: QuickAddDraft,
        existingEntry: Entry
    ) -> Bool {
        isDuplicate(
            normalizedTitle: draft.normalizedTitle,
            type: draft.type,
            releaseYear: draft.releaseYear,
            externalMetadata: draft.externalMetadata,
            existingEntry: existingEntry
        )
    }

    static func isDuplicate(
        title: String,
        type: EntryType,
        releaseYear: Int?,
        externalMetadata: EntryExternalMetadata? = nil,
        existingEntry: Entry
    ) -> Bool {
        isDuplicate(
            normalizedTitle: title.normalizedTitleKey,
            type: type,
            releaseYear: releaseYear,
            externalMetadata: externalMetadata,
            existingEntry: existingEntry
        )
    }

    static func isDuplicate(
        normalizedTitle: String,
        type: EntryType,
        releaseYear: Int?,
        externalMetadata: EntryExternalMetadata? = nil,
        existingEntry: Entry
    ) -> Bool {
        guard existingEntry.deletedAt == nil else {
            return false
        }

        if isSameTMDBMedia(
            externalMetadata: externalMetadata,
            existingEntry: existingEntry
        ) {
            return true
        }

        return isSameTitleTypeAndCompatibleYear(
            normalizedTitle: normalizedTitle,
            type: type,
            releaseYear: releaseYear,
            existingEntry: existingEntry
        )
    }

    static func findDuplicate(
        draft: QuickAddDraft,
        in entries: [Entry]
    ) -> Entry? {
        entries.first { entry in
            isDuplicate(
                draft: draft,
                existingEntry: entry
            )
        }
    }

    static func findDuplicate(
        title: String,
        type: EntryType,
        releaseYear: Int?,
        externalMetadata: EntryExternalMetadata? = nil,
        in entries: [Entry]
    ) -> Entry? {
        entries.first { entry in
            isDuplicate(
                title: title,
                type: type,
                releaseYear: releaseYear,
                externalMetadata: externalMetadata,
                existingEntry: entry
            )
        }
    }

    // MARK: - Matching Rules

    private static func isSameTMDBMedia(
        externalMetadata: EntryExternalMetadata?,
        existingEntry: Entry
    ) -> Bool {
        guard let externalMetadata else {
            return false
        }

        guard existingEntry.externalSourceRaw == ExternalMediaSource.tmdb.rawValue else {
            return false
        }

        guard let existingTMDBId = existingEntry.tmdbId,
              let existingMediaTypeRaw = existingEntry.tmdbMediaTypeRaw else {
            return false
        }

        return existingTMDBId == externalMetadata.tmdbId &&
            existingMediaTypeRaw == externalMetadata.tmdbMediaTypeRaw
    }

    private static func isSameTitleTypeAndCompatibleYear(
        normalizedTitle: String,
        type: EntryType,
        releaseYear: Int?,
        existingEntry: Entry
    ) -> Bool {
        let cleanedNormalizedTitle = normalizedTitle
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedNormalizedTitle.isEmpty == false else {
            return false
        }

        guard existingEntry.normalizedTitle == cleanedNormalizedTitle else {
            return false
        }

        guard existingEntry.type == type else {
            return false
        }

        if let releaseYear, let existingYear = existingEntry.releaseYear {
            return releaseYear == existingYear
        }

        return releaseYear == nil || existingEntry.releaseYear == nil
    }
}
