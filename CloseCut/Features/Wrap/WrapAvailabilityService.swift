//
//  WrapAvailabilityService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

enum WrapAvailabilityService {
    static func availability(
        entries: [Entry],
        watchlistItems: [WatchlistItem],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> WrapAvailability {
        let activeEntries = entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmed.isEmpty == false }

        let savedItems = watchlistItems
            .filter { $0.deletedAt == nil }
            .filter { $0.status == .saved }

        let latestMonthlyPeriod = WrapPeriodFactory.previousMonth(
            now: now,
            calendar: calendar
        )

        let latestMonthlyHasData = hasData(
            period: latestMonthlyPeriod,
            entries: activeEntries,
            watchlistItems: savedItems
        )

        let shouldPromoteMonthlyWrap = latestMonthlyHasData &&
            isWithinMonthlyPromotionWindow(
                now: now,
                calendar: calendar
            )

        let allTimePeriod = WrapPeriodFactory.allTime(
            entries: activeEntries,
            now: now
        )

        let canShowAllTimeRecap = canShowAllTimeRecap(
            entries: activeEntries,
            now: now,
            calendar: calendar
        )

        return WrapAvailability(
            latestMonthlyPeriod: latestMonthlyHasData ? latestMonthlyPeriod : nil,
            shouldPromoteMonthlyWrap: shouldPromoteMonthlyWrap,
            canShowLatestMonthlyWrap: latestMonthlyHasData,
            allTimePeriod: canShowAllTimeRecap ? allTimePeriod : nil,
            canShowAllTimeRecap: canShowAllTimeRecap
        )
    }

    // MARK: - Monthly

    private static func hasData(
        period: WrapPeriod,
        entries: [Entry],
        watchlistItems: [WatchlistItem]
    ) -> Bool {
        let watchedCount = entries.filter {
            period.contains($0.watchedAt)
        }.count

        let savedCount = watchlistItems.filter {
            period.contains($0.createdAt)
        }.count

        return watchedCount > 0 || savedCount >= 3
    }

    private static func isWithinMonthlyPromotionWindow(
        now: Date,
        calendar: Calendar
    ) -> Bool {
        let day = calendar.component(
            .day,
            from: now
        )

        return day >= 1 && day <= 7
    }

    // MARK: - All Time / General Recap

    private static func canShowAllTimeRecap(
        entries: [Entry],
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard entries.count >= 20 else {
            return false
        }

        let sortedEntries = entries.sorted {
            $0.watchedAt < $1.watchedAt
        }

        guard let firstDate = sortedEntries.first?.watchedAt else {
            return false
        }

        let monthsSinceFirstEntry = calendar.dateComponents(
            [.month],
            from: firstDate,
            to: now
        ).month ?? 0

        let distinctMonthCount = Set(
            entries.map { entry in
                let components = calendar.dateComponents(
                    [.year, .month],
                    from: entry.watchedAt
                )

                return "\(components.year ?? 0)-\(components.month ?? 0)"
            }
        )
        .count

        return monthsSinceFirstEntry >= 12 ||
            distinctMonthCount >= 8 ||
            entries.count >= 50
    }
}
