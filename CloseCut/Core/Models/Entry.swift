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
    var type: EntryType

    var mood: String
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContext: WatchContext
    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibility: EntryVisibility

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
}
