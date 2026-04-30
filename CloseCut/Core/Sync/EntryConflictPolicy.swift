//
//  EntryConflictPolicy.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum EntryMergeDecision: Equatable {
    case insertRemote
    case applyRemote
    case keepLocal
    case keepLocalPending
}

enum EntryConflictPolicy {
    static func decide(
        localEntry: Entry?,
        remoteEntry: Entry
    ) -> EntryMergeDecision {
        guard let localEntry else {
            return .insertRemote
        }

        if localEntry.syncStatus == .pending || localEntry.syncStatus == .failed {
            return .keepLocalPending
        }

        if remoteEntry.deletedAt != nil {
            return .applyRemote
        }

        if remoteEntry.updatedAt > localEntry.updatedAt {
            return .applyRemote
        }

        return .keepLocal
    }
}
