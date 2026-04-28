//
//  DuplicateDetector.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 27/04/26.
//

import Foundation

enum DuplicateDetector {
    static func isDuplicate(
        draft: QuickAddDraft,
        existingEntry: Entry
    ) -> Bool {
        isDuplicate(
            normalizedTitle: draft.normalizedTitle,
            type: draft.type,
            releaseYear: draft.releaseYear,
            existingEntry: existingEntry
        )
    }

    static func isDuplicate(
        title: String,
        type: EntryType,
        releaseYear: Int?,
        existingEntry: Entry
    ) -> Bool {
        isDuplicate(
            normalizedTitle: title.normalizedTitleKey,
            type: type,
            releaseYear: releaseYear,
            existingEntry: existingEntry
        )
    }

    static func isDuplicate(
        normalizedTitle: String,
        type: EntryType,
        releaseYear: Int?,
        existingEntry: Entry
    ) -> Bool {
        guard existingEntry.deletedAt == nil else {
            return false
        }

        guard existingEntry.normalizedTitle == normalizedTitle else {
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

    static func findDuplicate(
        draft: QuickAddDraft,
        in entries: [Entry]
    ) -> Entry? {
        entries.first { entry in
            isDuplicate(draft: draft, existingEntry: entry)
        }
    }

    static func findDuplicate(
        title: String,
        type: EntryType,
        releaseYear: Int?,
        in entries: [Entry]
    ) -> Entry? {
        entries.first { entry in
            isDuplicate(
                title: title,
                type: type,
                releaseYear: releaseYear,
                existingEntry: entry
            )
        }
    }
}
