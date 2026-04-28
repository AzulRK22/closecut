//
//  ActivationModels.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 27/04/26.
//

import Foundation

enum EntrySourceType: String, Codable, CaseIterable, Identifiable {
    case quickAdd
    case fullEntry
    case imported

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quickAdd:
            return "Quick Add"
        case .fullEntry:
            return "Full Entry"
        case .imported:
            return "Imported"
        }
    }
}

enum QuickSentiment: String, Codable, CaseIterable, Identifiable {
    case loved
    case liked
    case mixed
    case notForMe
    case stayedWithMe

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .loved:
            return "Loved"
        case .liked:
            return "Liked"
        case .mixed:
            return "Mixed"
        case .notForMe:
            return "Not for me"
        case .stayedWithMe:
            return "Stayed with me"
        }
    }
}

enum ApproxDateKind: String, Codable, CaseIterable, Identifiable {
    case exact
    case monthYear
    case yearOnly
    case recently
    case thisYear
    case longTimeAgo
    case unknown

    var id: String { rawValue }
}

struct WatchedDateApprox: Codable, Equatable {
    var kind: ApproxDateKind
    var exactDate: Date?
    var month: Int?
    var year: Int?
    var displayLabel: String

    static let unknown = WatchedDateApprox(
        kind: .unknown,
        exactDate: nil,
        month: nil,
        year: nil,
        displayLabel: "Unknown date"
    )

    static let recently = WatchedDateApprox(
        kind: .recently,
        exactDate: nil,
        month: nil,
        year: nil,
        displayLabel: "Recently"
    )

    static let thisYear = WatchedDateApprox(
        kind: .thisYear,
        exactDate: nil,
        month: nil,
        year: Calendar.current.component(.year, from: Date()),
        displayLabel: "This year"
    )

    static let longTimeAgo = WatchedDateApprox(
        kind: .longTimeAgo,
        exactDate: nil,
        month: nil,
        year: nil,
        displayLabel: "A long time ago"
    )

    static func yearOnly(_ year: Int) -> WatchedDateApprox {
        WatchedDateApprox(
            kind: .yearOnly,
            exactDate: nil,
            month: nil,
            year: year,
            displayLabel: "\(year)"
        )
    }

    static func exact(_ date: Date) -> WatchedDateApprox {
        WatchedDateApprox(
            kind: .exact,
            exactDate: date,
            month: Calendar.current.component(.month, from: date),
            year: Calendar.current.component(.year, from: date),
            displayLabel: date.formatted(date: .abbreviated, time: .omitted)
        )
    }
}
