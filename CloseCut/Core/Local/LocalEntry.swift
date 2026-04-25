//
//  LocalEntry.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalEntry {
    @Attribute(.unique) var id: String

    var ownerId: String

    var title: String
    var typeRaw: String

    var mood: String
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContextRaw: String
    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibilityRaw: String

    var watchedAt: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var syncStatusRaw: String

    init(
        id: String = UUID().uuidString,
        ownerId: String,
        title: String,
        type: EntryType,
        mood: String,
        takeaway: String,
        quote: String? = nil,
        tags: [String] = [],
        intensity: Int,
        watchContext: WatchContext,
        cinemaAudio: Int? = nil,
        cinemaScreen: Int? = nil,
        cinemaComfort: Int? = nil,
        visibility: EntryVisibility = .privateOnly,
        watchedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        syncStatus: SyncStatus = .pending
    ) {
        self.id = id
        self.ownerId = ownerId
        self.title = title
        self.typeRaw = type.rawValue
        self.mood = mood
        self.takeaway = takeaway
        self.quote = quote
        self.tags = tags
        self.intensity = intensity
        self.watchContextRaw = watchContext.rawValue
        self.cinemaAudio = cinemaAudio
        self.cinemaScreen = cinemaScreen
        self.cinemaComfort = cinemaComfort
        self.visibilityRaw = visibility.rawValue
        self.watchedAt = watchedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.syncStatusRaw = syncStatus.rawValue
    }
}
extension LocalEntry {
    var domain: Entry {
        Entry(
            id: id,
            ownerId: ownerId,
            title: title,
            type: EntryType(rawValue: typeRaw) ?? .movie,
            mood: mood,
            takeaway: takeaway,
            quote: quote,
            tags: tags,
            intensity: intensity,
            watchContext: WatchContext(rawValue: watchContextRaw) ?? .home,
            cinemaAudio: cinemaAudio,
            cinemaScreen: cinemaScreen,
            cinemaComfort: cinemaComfort,
            visibility: EntryVisibility(rawValue: visibilityRaw) ?? .privateOnly,
            watchedAt: watchedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            syncStatus: SyncStatus(rawValue: syncStatusRaw) ?? .synced
        )
    }

    func update(from entry: Entry) {
        ownerId = entry.ownerId
        title = entry.title
        typeRaw = entry.type.rawValue
        mood = entry.mood
        takeaway = entry.takeaway
        quote = entry.quote
        tags = entry.tags
        intensity = entry.intensity
        watchContextRaw = entry.watchContext.rawValue
        cinemaAudio = entry.cinemaAudio
        cinemaScreen = entry.cinemaScreen
        cinemaComfort = entry.cinemaComfort
        visibilityRaw = entry.visibility.rawValue
        watchedAt = entry.watchedAt
        createdAt = entry.createdAt
        updatedAt = entry.updatedAt
        deletedAt = entry.deletedAt
        syncStatusRaw = entry.syncStatus.rawValue
    }
}
