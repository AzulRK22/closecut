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

    var id: String {
        rawValue
    }

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

    var shortDisplayName: String {
        switch self {
        case .quickAdd:
            return "Quick Add"
        case .fullEntry:
            return "Full"
        case .imported:
            return "Import"
        }
    }

    var systemImage: String {
        switch self {
        case .quickAdd:
            return "bolt.fill"
        case .fullEntry:
            return "square.and.pencil"
        case .imported:
            return "tray.and.arrow.down.fill"
        }
    }

    var isLightweightCapture: Bool {
        switch self {
        case .quickAdd, .imported:
            return true
        case .fullEntry:
            return false
        }
    }
}

enum QuickSentiment: String, Codable, CaseIterable, Identifiable {
    case loved
    case liked
    case mixed
    case notForMe
    case stayedWithMe

    var id: String {
        rawValue
    }

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

    var emoji: String {
        switch self {
        case .loved:
            return "❤️"
        case .liked:
            return "👍"
        case .mixed:
            return "🤔"
        case .notForMe:
            return "🙅"
        case .stayedWithMe:
            return "🌙"
        }
    }

    var systemImage: String {
        switch self {
        case .loved:
            return "heart.fill"
        case .liked:
            return "hand.thumbsup.fill"
        case .mixed:
            return "circle.lefthalf.filled"
        case .notForMe:
            return "hand.thumbsdown.fill"
        case .stayedWithMe:
            return "moon.stars.fill"
        }
    }

    var recommendationSignalWeight: Int {
        switch self {
        case .loved:
            return 5
        case .stayedWithMe:
            return 4
        case .liked:
            return 3
        case .mixed:
            return 1
        case .notForMe:
            return -2
        }
    }

    var isPositiveSignal: Bool {
        recommendationSignalWeight > 0
    }

    var isNegativeSignal: Bool {
        recommendationSignalWeight < 0
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

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .exact:
            return "Exact date"
        case .monthYear:
            return "Month and year"
        case .yearOnly:
            return "Year only"
        case .recently:
            return "Recently"
        case .thisYear:
            return "This year"
        case .longTimeAgo:
            return "A long time ago"
        case .unknown:
            return "Unknown"
        }
    }

    var isPrecise: Bool {
        switch self {
        case .exact, .monthYear, .yearOnly:
            return true
        case .recently, .thisYear, .longTimeAgo, .unknown:
            return false
        }
    }
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

    var isUnknown: Bool {
        kind == .unknown
    }

    var isApproximate: Bool {
        kind != .exact
    }

    var resolvedDisplayLabel: String {
        let cleaned = displayLabel.trimmed

        if cleaned.isEmpty == false {
            return cleaned
        }

        switch kind {
        case .exact:
            if let exactDate {
                return exactDate.formatted(date: .abbreviated, time: .omitted)
            }
            return "Exact date"
        case .monthYear:
            if let month, let year {
                return "\(Self.monthName(for: month)) \(year)"
            }
            return "Month and year"
        case .yearOnly:
            if let year {
                return "\(year)"
            }
            return "Year only"
        case .recently:
            return "Recently"
        case .thisYear:
            return "This year"
        case .longTimeAgo:
            return "A long time ago"
        case .unknown:
            return "Unknown date"
        }
    }

    var approximateSortDate: Date? {
        let calendar = Calendar.current

        switch kind {
        case .exact:
            return exactDate

        case .monthYear:
            guard let month, let year else {
                return nil
            }

            return calendar.date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: 15
                )
            )

        case .yearOnly:
            guard let year else {
                return nil
            }

            return calendar.date(
                from: DateComponents(
                    year: year,
                    month: 7,
                    day: 1
                )
            )

        case .recently:
            return Date()

        case .thisYear:
            let currentYear = year ?? calendar.component(.year, from: Date())
            return calendar.date(
                from: DateComponents(
                    year: currentYear,
                    month: 7,
                    day: 1
                )
            )

        case .longTimeAgo:
            return calendar.date(
                from: DateComponents(
                    year: 2000,
                    month: 1,
                    day: 1
                )
            )

        case .unknown:
            return nil
        }
    }

    static func yearOnly(_ year: Int) -> WatchedDateApprox {
        WatchedDateApprox(
            kind: .yearOnly,
            exactDate: nil,
            month: nil,
            year: year,
            displayLabel: "\(year)"
        )
    }

    static func monthYear(
        month: Int,
        year: Int
    ) -> WatchedDateApprox {
        WatchedDateApprox(
            kind: .monthYear,
            exactDate: nil,
            month: month,
            year: year,
            displayLabel: "\(monthName(for: month)) \(year)"
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

    private static func monthName(
        for month: Int
    ) -> String {
        guard month >= 1, month <= 12 else {
            return "Month"
        }

        return Calendar.current.monthSymbols[month - 1]
    }
}
