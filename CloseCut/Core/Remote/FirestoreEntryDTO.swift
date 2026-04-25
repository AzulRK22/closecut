//
//  FirestoreEntryDTO.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreEntryDTO: Codable {
    var ownerId: String
    var circleId: String?

    var title: String
    var type: String

    var mood: String
    var takeaway: String
    var quote: String?
    var tags: [String]
    var intensity: Int

    var watchContext: String
    var cinemaAudio: Int?
    var cinemaScreen: Int?
    var cinemaComfort: Int?

    var visibility: String

    var watchedAt: Timestamp
    var createdAt: Timestamp
    var updatedAt: Timestamp
    var deletedAt: Timestamp?
}

extension FirestoreEntryDTO {
    init(entry: Entry, circleId: String? = nil) {
        self.ownerId = entry.ownerId
        self.circleId = circleId
        self.title = entry.title
        self.type = entry.type.rawValue
        self.mood = entry.mood
        self.takeaway = entry.takeaway
        self.quote = entry.quote
        self.tags = entry.tags
        self.intensity = entry.intensity
        self.watchContext = entry.watchContext.rawValue
        self.cinemaAudio = entry.cinemaAudio
        self.cinemaScreen = entry.cinemaScreen
        self.cinemaComfort = entry.cinemaComfort
        self.visibility = entry.visibility.rawValue
        self.watchedAt = Timestamp(date: entry.watchedAt)
        self.createdAt = Timestamp(date: entry.createdAt)
        self.updatedAt = Timestamp(date: entry.updatedAt)
        self.deletedAt = entry.deletedAt.map { Timestamp(date: $0) }
    }

    func domain(id: String, syncStatus: SyncStatus = .synced) -> Entry {
        Entry(
            id: id,
            ownerId: ownerId,
            title: title,
            type: EntryType(rawValue: type) ?? .movie,
            mood: mood,
            takeaway: takeaway,
            quote: quote,
            tags: tags,
            intensity: intensity,
            watchContext: WatchContext(rawValue: watchContext) ?? .home,
            cinemaAudio: cinemaAudio,
            cinemaScreen: cinemaScreen,
            cinemaComfort: cinemaComfort,
            visibility: EntryVisibility(rawValue: visibility) ?? .privateOnly,
            watchedAt: watchedAt.dateValue(),
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue(),
            deletedAt: deletedAt?.dateValue(),
            syncStatus: syncStatus
        )
    }
}
