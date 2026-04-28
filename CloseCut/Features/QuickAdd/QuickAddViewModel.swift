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
    @Published private(set) var addedEntries: [Entry] = []
    @Published private(set) var lastDuplicateEntry: Entry?
    @Published private(set) var errorMessage: String?

    private let repository = EntryRepository()

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

    var filteredSuggestions: [QuickAddSuggestion] {
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedQuery.isEmpty == false else {
            return Array(localSuggestions.prefix(6))
        }

        return localSuggestions.filter {
            $0.title.localizedCaseInsensitiveContains(cleanedQuery)
        }
    }

    var canAddManualTitle: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var addedCountText: String {
        switch addedEntries.count {
        case 0:
            return "No titles added yet"
        case 1:
            return "1 added"
        default:
            return "\(addedEntries.count) added"
        }
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
            modelContext: modelContext
        )
    }

    func addManualTitle(
        ownerId: String,
        modelContext: ModelContext
    ) {
        let cleanedTitle = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedTitle.isEmpty == false else {
            return
        }

        let draft = QuickAddDraft(
            title: cleanedTitle,
            type: .movie,
            releaseYear: nil,
            quickSentiment: selectedSentiment,
            watchedDateApprox: selectedApproxDate
        )

        saveDraft(
            draft,
            ownerId: ownerId,
            modelContext: modelContext
        )

        query = ""
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

    private func saveDraft(
        _ draft: QuickAddDraft,
        ownerId: String,
        modelContext: ModelContext
    ) {
        errorMessage = nil
        lastDuplicateEntry = nil

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
            }

            print("✅ Quick Add result:", entry.title, entry.sourceType.rawValue)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Quick Add failed:", error.localizedDescription)
        }
    }
}
