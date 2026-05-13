//
//  QuickAddViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class QuickAddViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var selectedSentiment: QuickSentiment? = .stayedWithMe
    @Published var selectedApproxDate: WatchedDateApprox = .recently

    @Published private(set) var tmdbResults: [TMDBMediaSearchResult] = []
    @Published private(set) var isSearchingTMDB = false
    @Published private(set) var searchErrorMessage: String?

    @Published private(set) var addedEntries: [Entry] = []
    @Published private(set) var lastDuplicateEntry: Entry?
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastAddedEntry: Entry?

    private let repository = EntryRepository()
    private let tmdbRepository = TMDBSearchRepository()
    private var searchTask: Task<Void, Never>?

    private let localSuggestions: [QuickAddSuggestion] = [
        QuickAddSuggestion(title: "Past Lives", type: .movie, releaseYear: 2023),
        QuickAddSuggestion(title: "Aftersun", type: .movie, releaseYear: 2022),
        QuickAddSuggestion(title: "Arrival", type: .movie, releaseYear: 2016),
        QuickAddSuggestion(title: "Her", type: .movie, releaseYear: 2013),
        QuickAddSuggestion(title: "Little Women", type: .movie, releaseYear: 2019),
        QuickAddSuggestion(title: "Lost in Translation", type: .movie, releaseYear: 2003),
        QuickAddSuggestion(title: "The Bear", type: .series, releaseYear: 2022),
        QuickAddSuggestion(title: "Fleabag", type: .series, releaseYear: 2016),
        QuickAddSuggestion(title: "Normal People", type: .series, releaseYear: 2020),
        QuickAddSuggestion(title: "Everything Everywhere All at Once", type: .movie, releaseYear: 2022),
        QuickAddSuggestion(title: "La La Land", type: .movie, releaseYear: 2016),
        QuickAddSuggestion(title: "The Worst Person in the World", type: .movie, releaseYear: 2021)
    ]

    var cleanedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var starterSuggestions: [QuickAddSuggestion] {
        Array(localSuggestions.prefix(6))
    }

    var shouldShowEmptyStarter: Bool {
        cleanedQuery.isEmpty &&
            tmdbResults.isEmpty &&
            isSearchingTMDB == false
    }

    var shouldShowLocalFallback: Bool {
        cleanedQuery.isEmpty == false &&
            tmdbResults.isEmpty &&
            isSearchingTMDB == false
    }

    var shouldShowManualAddButton: Bool {
        canAddManualTitle &&
            isSearchingTMDB == false &&
            tmdbResults.isEmpty
    }

    var filteredSuggestions: [QuickAddSuggestion] {
        guard cleanedQuery.isEmpty == false else {
            return starterSuggestions
        }

        return localSuggestions.filter {
            $0.title.localizedCaseInsensitiveContains(cleanedQuery)
        }
    }

    var canAddManualTitle: Bool {
        cleanedQuery.isEmpty == false
    }

    var addedCountText: String {
        switch addedEntries.count {
        case 0:
            return "Start by adding one memory"
        case 1:
            return "1 memory added this session"
        default:
            return "\(addedEntries.count) memories added this session"
        }
    }

    var hasStatusMessage: Bool {
        lastAddedEntry != nil || lastDuplicateEntry != nil || errorMessage != nil
    }

    func scheduleSearch() {
        searchTask?.cancel()
        searchErrorMessage = nil

        guard cleanedQuery.count >= 2 else {
            tmdbResults = []
            isSearchingTMDB = false
            return
        }

        let queryToSearch = cleanedQuery

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 450_000_000)

            guard Task.isCancelled == false else {
                return
            }

            await searchTMDB(query: queryToSearch)
        }
    }

    func runSearchImmediately() {
        searchTask?.cancel()

        guard cleanedQuery.count >= 2 else {
            tmdbResults = []
            isSearchingTMDB = false
            return
        }

        let queryToSearch = cleanedQuery

        searchTask = Task {
            await searchTMDB(query: queryToSearch)
        }
    }

    func clearSearch() {
        searchTask?.cancel()
        query = ""
        tmdbResults = []
        isSearchingTMDB = false
        searchErrorMessage = nil
    }

    func addSuggestion(
        _ suggestion: QuickAddSuggestion,
        ownerId: String,
        modelContext: ModelContext
    ) {
        let draft = QuickAddDraft(
            title: suggestion.title,
            type: suggestion.type,
            releaseYear: suggestion.releaseYear,
            quickSentiment: selectedSentiment,
            watchedDateApprox: selectedApproxDate
        )

        saveDraft(
            draft,
            ownerId: ownerId,
            shouldClearQuery: false,
            modelContext: modelContext
        )
    }

    func addTMDBResult(
        _ result: TMDBMediaSearchResult,
        ownerId: String,
        modelContext: ModelContext
    ) {
        let draft = QuickAddDraft(
            tmdbResult: result,
            quickSentiment: selectedSentiment,
            watchedDateApprox: selectedApproxDate
        )

        saveDraft(
            draft,
            ownerId: ownerId,
            shouldClearQuery: false,
            modelContext: modelContext
        )
    }

    func addManualTitle(
        ownerId: String,
        modelContext: ModelContext
    ) {
        guard cleanedQuery.isEmpty == false else {
            return
        }

        let draft = QuickAddDraft(
            title: cleanedQuery,
            type: .movie,
            releaseYear: nil,
            quickSentiment: selectedSentiment,
            watchedDateApprox: selectedApproxDate
        )

        saveDraft(
            draft,
            ownerId: ownerId,
            shouldClearQuery: true,
            modelContext: modelContext
        )
    }

    func hasAdded(_ suggestion: QuickAddSuggestion) -> Bool {
        addedEntries.contains { entry in
            DuplicateDetector.isDuplicate(
                title: suggestion.title,
                type: suggestion.type,
                releaseYear: suggestion.releaseYear,
                existingEntry: entry
            )
        }
    }

    func hasAdded(_ result: TMDBMediaSearchResult) -> Bool {
        addedEntries.contains { entry in
            DuplicateDetector.isDuplicate(
                title: result.title,
                type: result.entryType,
                releaseYear: result.releaseYear,
                existingEntry: entry
            )
        }
    }

    func clearStatusMessages() {
        lastAddedEntry = nil
        lastDuplicateEntry = nil
        errorMessage = nil
    }

    private func searchTMDB(query: String) async {
        isSearchingTMDB = true
        searchErrorMessage = nil

        do {
            let results = try await tmdbRepository.searchMedia(query: query)

            guard Task.isCancelled == false else {
                return
            }

            tmdbResults = Array(results.prefix(8))
            isSearchingTMDB = false
        } catch {
            guard Task.isCancelled == false else {
                return
            }

            tmdbResults = []
            searchErrorMessage = error.localizedDescription
            isSearchingTMDB = false

            #if DEBUG
            print("⚠️ Quick Add TMDB search failed:", error.localizedDescription)
            #endif
        }
    }

    private func saveDraft(
        _ draft: QuickAddDraft,
        ownerId: String,
        shouldClearQuery: Bool,
        modelContext: ModelContext
    ) {
        clearStatusMessages()

        do {
            let beforeCount = try repository.fetchLocalEntries(
                ownerId: ownerId,
                includeDeleted: false,
                modelContext: modelContext
            ).count

            let entry = try repository.createQuickAddEntry(
                ownerId: ownerId,
                draft: draft,
                visibility: .privateOnly,
                modelContext: modelContext
            )

            let afterCount = try repository.fetchLocalEntries(
                ownerId: ownerId,
                includeDeleted: false,
                modelContext: modelContext
            ).count

            if afterCount == beforeCount {
                lastDuplicateEntry = entry
            } else {
                addedEntries.insert(entry, at: 0)
                lastAddedEntry = entry
            }

            if shouldClearQuery {
                clearSearch()
            }

            #if DEBUG
            print("✅ Quick Add result:", entry.title, entry.sourceType.rawValue)
            #endif
        } catch {
            errorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Quick Add failed:", error.localizedDescription)
            #endif
        }
    }
}
