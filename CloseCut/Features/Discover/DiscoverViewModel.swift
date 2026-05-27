//
//  DiscoverViewModel.swift
//  CloseCut
//

import Foundation
import Combine

enum DiscoverSectionKind: String, CaseIterable, Identifiable {
    case trending
    case popularMovies
    case popularSeries
    case becauseOfYourTaste

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trending:
            return "Trending this week"
        case .popularMovies:
            return "Popular movies"
        case .popularSeries:
            return "Popular series"
        case .becauseOfYourTaste:
            return "Because of your taste"
        }
    }

    var subtitle: String {
        switch self {
        case .trending:
            return "What people are watching right now."
        case .popularMovies:
            return "High-signal movies worth noticing."
        case .popularSeries:
            return "Series gaining attention."
        case .becauseOfYourTaste:
            return "Picked from genres already in your history."
        }
    }

    var emptyMessage: String {
        switch self {
        case .becauseOfYourTaste:
            return "Add a few more watched titles to unlock personal discovery."
        default:
            return "No titles available right now."
        }
    }
}

struct DiscoverSection: Identifiable, Equatable {
    let id: DiscoverSectionKind
    var items: [TMDBMediaSearchResult]
}

@MainActor
final class DiscoverViewModel: ObservableObject {
    @Published private(set) var sections: [DiscoverSection] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var selectedMedia: TMDBMediaSearchResult?

    private let repository: TMDBMediaRepository
    private var hasLoaded = false

    init(repository: TMDBMediaRepository? = nil) {
        self.repository = repository ?? TMDBMediaRepository()
    }

    var hasContent: Bool {
        sections.contains { $0.items.isEmpty == false }
    }

    func loadIfNeeded(entries: [Entry]) async {
        guard hasLoaded == false else {
            return
        }

        await load(entries: entries)
    }

    func refresh(entries: [Entry]) async {
        hasLoaded = false
        await load(entries: entries)
    }

    func load(entries: [Entry]) async {
        guard isLoading == false else {
            return
        }

        guard TMDBConfiguration.hasValidReadAccessToken else {
            errorMessage = "Discover needs a valid TMDB token to load titles."
            sections = []
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            async let trendingResults = repository.trending()
            async let movieResults = repository.popularMovies()
            async let tvResults = repository.popularTV()

            let personalGenreIds = topGenreIds(from: entries)

            let personalResults: [TMDBMediaSearchResult]

            if personalGenreIds.isEmpty {
                personalResults = []
            } else {
                personalResults = try await repository.discoverMedia(
                    genreIds: personalGenreIds,
                    preferredType: preferredType(from: entries)
                )
            }

            let loadedSections = try await [
                DiscoverSection(
                    id: .trending,
                    items: trendingResults.uniqued(by: \.id)
                ),
                DiscoverSection(
                    id: .popularMovies,
                    items: movieResults.uniqued(by: \.id)
                ),
                DiscoverSection(
                    id: .popularSeries,
                    items: tvResults.uniqued(by: \.id)
                ),
                DiscoverSection(
                    id: .becauseOfYourTaste,
                    items: personalResults.uniqued(by: \.id)
                )
            ]

            sections = loadedSections
        } catch {
            errorMessage = readableError(error)
            sections = []
        }
    }

    func select(_ media: TMDBMediaSearchResult) {
        selectedMedia = media
    }

    func clearSelection() {
        selectedMedia = nil
    }

    // MARK: - Personal Signals

    private func topGenreIds(from entries: [Entry]) -> [Int] {
        let activeEntries = entries.filter { $0.deletedAt == nil }

        let counts = activeEntries
            .flatMap(\.tmdbGenreIds)
            .reduce(into: [Int: Int]()) { result, genreId in
                result[genreId, default: 0] += 1
            }

        return counts
            .sorted { first, second in
                if first.value != second.value {
                    return first.value > second.value
                }

                return first.key < second.key
            }
            .map(\.key)
            .prefixArray(TMDBConfiguration.maximumDiscoveryGenreCount)
    }

    private func preferredType(from entries: [Entry]) -> EntryType? {
        let activeEntries = entries.filter { $0.deletedAt == nil }

        let movieCount = activeEntries.filter { $0.type == .movie }.count
        let seriesCount = activeEntries.filter { $0.type == .series }.count

        if movieCount == 0 && seriesCount == 0 {
            return nil
        }

        if movieCount == seriesCount {
            return nil
        }

        return movieCount > seriesCount ? .movie : .series
    }

    private func readableError(_ error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let message = localizedError.errorDescription {
            return message
        }

        return error.localizedDescription
    }
}

private extension Array {
    func prefixArray(_ maxCount: Int) -> [Element] {
        guard maxCount > 0 else {
            return []
        }

        return Array(prefix(maxCount))
    }
}
