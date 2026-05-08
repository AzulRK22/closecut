//
//  TimelineSectionBuilder.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 08/05/26.
//

import Foundation

enum TimelineSectionBuilder {
    static func buildSections(
        from entries: [Entry],
        now: Date = Date()
    ) -> [TimelineSection] {
        let activeEntries = entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

        let sortedEntries = activeEntries.sorted {
            $0.watchedAt > $1.watchedAt
        }

        guard sortedEntries.isEmpty == false else {
            return []
        }

        var sections: [TimelineSection] = []

        let recentlyWatched = Array(sortedEntries.prefix(5))
        sections.append(
            TimelineSection(
                kind: .recentlyWatched,
                subtitle: "Your latest memories, quick adds, and shared moments.",
                entries: recentlyWatched
            )
        )

        let stayedWithYou = sortedEntries
            .filter { entry in
                entry.quickSentiment == .loved ||
                entry.quickSentiment == .stayedWithMe ||
                entry.intensity >= 4
            }
            .prefix(5)

        if stayedWithYou.isEmpty == false {
            sections.append(
                TimelineSection(
                    kind: .stayedWithYou,
                    subtitle: "The watches that left the strongest signal in your archive.",
                    entries: Array(stayedWithYou)
                )
            )
        }

        let rewatchCandidates = sortedEntries
            .filter { qualifiesAsRewatchCandidate($0, now: now) }
            .prefix(5)

        if rewatchCandidates.isEmpty == false {
            sections.append(
                TimelineSection(
                    kind: .rewatchCandidates,
                    subtitle: "Older meaningful watches that may be worth revisiting.",
                    entries: Array(rewatchCandidates)
                )
            )
        }

        let highRatedMemories = sortedEntries
            .filter { ($0.tmdbRating ?? 0) >= 7.5 }
            .prefix(5)

        if highRatedMemories.isEmpty == false {
            sections.append(
                TimelineSection(
                    kind: .highRatedMemories,
                    subtitle: "Strong memories with useful TMDB metadata.",
                    entries: Array(highRatedMemories)
                )
            )
        }

        sections.append(
            TimelineSection(
                kind: .allHistory,
                subtitle: "\(sortedEntries.count) private \(sortedEntries.count == 1 ? "memory" : "memories") in your archive.",
                entries: sortedEntries
            )
        )

        return sections
    }

    private static func qualifiesAsRewatchCandidate(
        _ entry: Entry,
        now: Date
    ) -> Bool {
        let daysSinceWatch = Calendar.current.dateComponents(
            [.day],
            from: entry.watchedAt,
            to: now
        ).day ?? 0

        let isOldEnough = daysSinceWatch >= 120
        let hasStrongSentiment = entry.quickSentiment == .loved || entry.quickSentiment == .stayedWithMe
        let hasHighIntensity = entry.intensity >= 4
        let hasHighRating = (entry.tmdbRating ?? 0) >= 7.5

        return isOldEnough && (hasStrongSentiment || hasHighIntensity || hasHighRating)
    }
}
