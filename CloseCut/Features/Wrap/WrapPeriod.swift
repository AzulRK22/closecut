//
//  WrapPeriod.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

enum WrapPeriodKind: String, Codable, Equatable {
    case monthly
    case yearly
    case allTime

    var displayName: String {
        switch self {
        case .monthly:
            return "Monthly Wrap"
        case .yearly:
            return "Year Wrap"
        case .allTime:
            return "CloseCut Recap"
        }
    }
}

struct WrapPeriod: Identifiable, Codable, Equatable {
    let id: String
    let kind: WrapPeriodKind
    let startDate: Date
    let endDate: Date
    let title: String
    let subtitle: String

    init(
        kind: WrapPeriodKind,
        startDate: Date,
        endDate: Date,
        title: String,
        subtitle: String
    ) {
        self.kind = kind
        self.startDate = startDate
        self.endDate = endDate
        self.title = title
        self.subtitle = subtitle

        let startTimestamp = Int(startDate.timeIntervalSince1970)
        let endTimestamp = Int(endDate.timeIntervalSince1970)

        self.id = "\(kind.rawValue)-\(startTimestamp)-\(endTimestamp)"
    }

    func contains(
        _ date: Date
    ) -> Bool {
        date >= startDate && date < endDate
    }
}

enum WrapPeriodFactory {
    static func previousMonth(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WrapPeriod {
        let currentComponents = calendar.dateComponents(
            [.year, .month],
            from: now
        )

        let currentMonthStart = calendar.date(
            from: currentComponents
        ) ?? now

        let previousMonthStart = calendar.date(
            byAdding: .month,
            value: -1,
            to: currentMonthStart
        ) ?? now

        let previousMonthEnd = currentMonthStart

        let title = monthYearTitle(
            for: previousMonthStart,
            calendar: calendar
        )

        return WrapPeriod(
            kind: .monthly,
            startDate: previousMonthStart,
            endDate: previousMonthEnd,
            title: "\(title) Wrap",
            subtitle: "Your month in stories."
        )
    }

    static func currentMonth(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WrapPeriod {
        let currentComponents = calendar.dateComponents(
            [.year, .month],
            from: now
        )

        let currentMonthStart = calendar.date(
            from: currentComponents
        ) ?? now

        let nextMonthStart = calendar.date(
            byAdding: .month,
            value: 1,
            to: currentMonthStart
        ) ?? now

        let title = monthYearTitle(
            for: currentMonthStart,
            calendar: calendar
        )

        return WrapPeriod(
            kind: .monthly,
            startDate: currentMonthStart,
            endDate: nextMonthStart,
            title: "\(title) Wrap",
            subtitle: "Your month in stories."
        )
    }

    static func currentYear(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WrapPeriod {
        let yearComponents = calendar.dateComponents(
            [.year],
            from: now
        )

        let yearStart = calendar.date(
            from: yearComponents
        ) ?? now

        let nextYearStart = calendar.date(
            byAdding: .year,
            value: 1,
            to: yearStart
        ) ?? now

        let year = calendar.component(
            .year,
            from: yearStart
        )

        return WrapPeriod(
            kind: .yearly,
            startDate: yearStart,
            endDate: nextYearStart,
            title: "\(year) Wrap",
            subtitle: "Your year in stories."
        )
    }

    static func allTime(
        entries: [Entry],
        now: Date = Date()
    ) -> WrapPeriod? {
        let activeEntries = entries
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                first.watchedAt < second.watchedAt
            }

        guard let firstDate = activeEntries.first?.watchedAt else {
            return nil
        }

        return WrapPeriod(
            kind: .allTime,
            startDate: firstDate,
            endDate: now,
            title: "Your CloseCut Recap",
            subtitle: "Your story so far."
        )
    }

    private static func monthYearTitle(
        for date: Date,
        calendar: Calendar
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
