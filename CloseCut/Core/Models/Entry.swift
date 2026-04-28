//
//  Entry.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct Entry: Identifiable, Codable, Equatable {
    let id: String
    var ownerId: String

    var title: String
    var normalizedTitle: String
    var type: EntryType
    var releaseYear: Int?

    var mood: String
    var quickSentiment: QuickSentiment?
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContext: WatchContext
    var watchedDateApprox: WatchedDateApprox?

    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibility: EntryVisibility
    var sourceType: EntrySourceType

    var watchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatus: SyncStatus

    var isSharedWithCircle: Bool {
        visibility == .circle
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var isQuickAdd: Bool {
        sourceType == .quickAdd
    }

    var hasFullEmotionalDetails: Bool {
        sourceType == .fullEntry && mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
