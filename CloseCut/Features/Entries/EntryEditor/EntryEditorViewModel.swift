//
//  EntryEditorViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class EntryEditorViewModel: ObservableObject {
    @Published var type: EntryType = .movie
    @Published var title: String = ""
    @Published var selectedMood: Mood?
    @Published var takeaway: String = ""
    @Published var keyMoment: String = ""
    @Published var intensity: Int = 3
    @Published var tags: [String] = []
    @Published var watchContext: WatchContext = .home
    @Published var cinemaAudio: Int? = nil
    @Published var cinemaScreen: Int? = nil
    @Published var cinemaComfort: Int? = nil

    // Kept only for compatibility with older UI/code.
    // Multi-circle sharing is now driven by selectedCircleIds in EntryEditorView.
    @Published var isSharedWithCircle: Bool = false

    @Published private(set) var selectedTMDBResult: TMDBMediaSearchResult?
    @Published private(set) var tmdbSuggestions: [TMDBMediaSearchResult] = []
    @Published private(set) var isSearchingTMDB: Bool = false
    @Published private(set) var tmdbSearchError: String?

    @Published var isSaving: Bool = false
    @Published var errors: [String] = []

    private let repository = EntryRepository()
    private let tmdbRepository = TMDBMediaRepository()
    private var titleSearchTask: Task<Void, Never>?

    private(set) var editingEntry: Entry?

    // MARK: - Editor Mode

    var isEditing: Bool {
        editingEntry != nil
    }

    var isUpgradingQuickAdd: Bool {
        editingEntry?.sourceType == .quickAdd
    }

    var navigationTitle: String {
        if isUpgradingQuickAdd {
            return "Add details"
        }

        return isEditing ? "Edit entry" : "New entry"
    }

    var saveButtonTitle: String {
        if isUpgradingQuickAdd {
            return "Save details"
        }

        return isEditing ? "Save changes" : "Save"
    }

    var helperMessage: String? {
        if isUpgradingQuickAdd {
            return "Make this memory more yours."
        }

        if isEditing {
            return "Update the details that changed."
        }

        return nil
    }

    // MARK: - Metadata

    var existingExternalMetadata: EntryExternalMetadata? {
        editingEntry?.externalMetadata
    }

    var resolvedExternalMetadata: EntryExternalMetadata? {
        if let selectedTMDBResult {
            return EntryExternalMetadata(tmdbResult: selectedTMDBResult)
        }

        return editingEntry?.externalMetadata
    }

    var currentReleaseYear: Int? {
        selectedTMDBResult?.releaseYear ?? editingEntry?.releaseYear
    }

    var metadataDisplayTitle: String? {
        selectedTMDBResult?.title ?? editingEntry?.title
    }

    var metadataPosterPath: String? {
        selectedTMDBResult?.posterPath ?? editingEntry?.posterPath
    }

    var metadataMediaType: TMDBMediaType {
        if let selectedTMDBResult {
            return selectedTMDBResult.mediaType
        }

        if let raw = editingEntry?.tmdbMediaTypeRaw {
            return TMDBMediaType(rawValue: raw) ?? .unknown
        }

        return type == .series ? .tv : .movie
    }

    var metadataSubtitle: String? {
        if let selectedTMDBResult {
            return selectedTMDBResult.subtitle
        }

        guard let editingEntry,
              editingEntry.hasTMDBMetadata else {
            return nil
        }

        var parts: [String] = []

        if let releaseYear = editingEntry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(editingEntry.type.displayName)

        if let rating = editingEntry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        return parts.joined(separator: " • ")
    }

    var hasMetadataSelectionOrExistingMetadata: Bool {
        selectedTMDBResult != nil || editingEntry?.hasTMDBMetadata == true
    }

    // MARK: - State

    var isDirty: Bool {
        if let editingEntry {
            return hasChanges(comparedTo: editingEntry)
        }

        return cleanTitle.isEmpty == false ||
            selectedMood != nil ||
            cleanTakeaway.isEmpty == false ||
            cleanKeyMoment.isEmpty == false ||
            cleanTags.isEmpty == false ||
            selectedTMDBResult != nil ||
            type != .movie ||
            intensity != 3 ||
            watchContext != .home ||
            cinemaAudio != nil ||
            cinemaScreen != nil ||
            cinemaComfort != nil
    }

    var canSave: Bool {
        cleanTitle.isEmpty == false &&
            selectedMood != nil &&
            isSaving == false
    }

    var shouldShowCinemaFields: Bool {
        watchContext == .cinema
    }

    private var cleanTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanTakeaway: String {
        takeaway.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanKeyMoment: String {
        keyMoment.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanTags: [String] {
        EntryValidation.normalizedTags(tags)
    }

    // MARK: - Configure

    func configureForNewEntry() {
        editingEntry = nil

        type = .movie
        title = ""
        selectedMood = nil
        takeaway = ""
        keyMoment = ""
        intensity = 3
        tags = []
        watchContext = .home
        cinemaAudio = nil
        cinemaScreen = nil
        cinemaComfort = nil
        isSharedWithCircle = false
        selectedTMDBResult = nil
        tmdbSuggestions = []
        isSearchingTMDB = false
        tmdbSearchError = nil
        errors = []
    }

    func configureForEdit(entry: Entry) {
        editingEntry = entry

        type = entry.type
        title = entry.title
        selectedMood = Mood.from(entry.mood)
        takeaway = entry.takeaway
        keyMoment = entry.quote ?? ""
        intensity = entry.intensity
        tags = EntryValidation.normalizedTags(entry.tags)
        watchContext = entry.watchContext
        cinemaAudio = entry.cinemaAudio
        cinemaScreen = entry.cinemaScreen
        cinemaComfort = entry.cinemaComfort
        isSharedWithCircle = entry.isSharedWithCircle
        selectedTMDBResult = nil
        tmdbSuggestions = []
        isSearchingTMDB = false
        tmdbSearchError = nil
        errors = []
    }

    // MARK: - Title Autocomplete

    func titleDidChange() {
        errors.removeAll {
            $0 == "Title is required." ||
            $0 == "Title must be \(EntryValidation.maxTitleLength) characters or less."
        }

        guard selectedTMDBResult == nil else {
            tmdbSuggestions = []
            isSearchingTMDB = false
            tmdbSearchError = nil
            return
        }

        scheduleTitleSearch()
    }

    func scheduleTitleSearch() {
        titleSearchTask?.cancel()
        tmdbSearchError = nil

        guard cleanTitle.count >= 2 else {
            tmdbSuggestions = []
            isSearchingTMDB = false
            return
        }

        let query = cleanTitle

        titleSearchTask = Task {
            try? await Task.sleep(nanoseconds: 420_000_000)

            guard Task.isCancelled == false else {
                return
            }

            await searchTMDBTitle(query: query)
        }
    }

    func runTitleSearchImmediately() {
        titleSearchTask?.cancel()

        guard cleanTitle.count >= 2 else {
            tmdbSuggestions = []
            isSearchingTMDB = false
            return
        }

        let query = cleanTitle

        titleSearchTask = Task {
            await searchTMDBTitle(query: query)
        }
    }

    func clearTitleSearchResults() {
        titleSearchTask?.cancel()
        tmdbSuggestions = []
        isSearchingTMDB = false
        tmdbSearchError = nil
    }

    private func searchTMDBTitle(query: String) async {
        guard selectedTMDBResult == nil else {
            return
        }

        isSearchingTMDB = true
        tmdbSearchError = nil

        do {
            let results = try await tmdbRepository.searchMedia(query: query)

            guard Task.isCancelled == false else {
                return
            }

            tmdbSuggestions = Array(results.prefix(4))
            isSearchingTMDB = false
        } catch {
            guard Task.isCancelled == false else {
                return
            }

            tmdbSuggestions = []
            tmdbSearchError = error.localizedDescription
            isSearchingTMDB = false

            #if DEBUG
            print("⚠️ Entry title TMDB search failed:", error.localizedDescription)
            #endif
        }
    }

    // MARK: - Metadata Actions

    func selectTMDBResult(_ result: TMDBMediaSearchResult) {
        titleSearchTask?.cancel()

        selectedTMDBResult = result
        title = result.title
        type = result.entryType

        tmdbSuggestions = []
        isSearchingTMDB = false
        tmdbSearchError = nil

        errors.removeAll {
            $0 == "Title is required." ||
            $0 == "Title must be \(EntryValidation.maxTitleLength) characters or less."
        }
    }

    func clearSelectedTMDBResult() {
        selectedTMDBResult = nil
        tmdbSuggestions = []
        tmdbSearchError = nil

        if cleanTitle.count >= 2 {
            scheduleTitleSearch()
        }
    }

    // MARK: - Save

    func save(
        ownerId: String,
        defaultVisibility _: EntryVisibility,
        selectedCircleIds: [String],
        modelContext: ModelContext
    ) async -> Bool {
        normalizeInputsBeforeValidation()

        errors = EntryValidation.validate(
            title: title,
            mood: selectedMood,
            takeaway: takeaway,
            quote: keyMoment,
            tags: tags,
            intensity: intensity,
            watchContext: watchContext,
            cinemaAudio: cinemaAudio,
            cinemaScreen: cinemaScreen,
            cinemaComfort: cinemaComfort
        )

        guard errors.isEmpty, let selectedMood else {
            return false
        }

        guard isSaving == false else {
            return false
        }

        isSaving = true
        defer { isSaving = false }

        let cleanedSelectedCircleIds = cleanCircleIds(selectedCircleIds)
        let visibility = resolvedVisibility(
            selectedCircleIds: cleanedSelectedCircleIds
        )

        do {
            if let editingEntry {
                _ = try repository.updateLocalEntry(
                    entryId: editingEntry.id,
                    title: cleanTitle,
                    type: type,
                    releaseYear: resolvedReleaseYear(for: editingEntry),
                    mood: selectedMood.label,
                    quickSentiment: editingEntry.quickSentiment,
                    takeaway: cleanTakeaway,
                    quote: cleanOptional(cleanKeyMoment),
                    tags: cleanTags,
                    intensity: clampedIntensity,
                    watchContext: watchContext,
                    watchedDateApprox: editingEntry.watchedDateApprox,
                    cinemaAudio: resolvedCinemaAudio,
                    cinemaScreen: resolvedCinemaScreen,
                    cinemaComfort: resolvedCinemaComfort,
                    visibility: visibility,
                    sharedCircleIds: cleanedSelectedCircleIds,
                    sourceType: .fullEntry,
                    externalMetadata: resolvedExternalMetadata,
                    watchedAt: editingEntry.watchedAt,
                    modelContext: modelContext
                )
            } else {
                _ = try repository.createLocalEntry(
                    ownerId: ownerId,
                    title: cleanTitle,
                    type: type,
                    releaseYear: selectedTMDBResult?.releaseYear,
                    mood: selectedMood.label,
                    quickSentiment: nil,
                    takeaway: cleanTakeaway,
                    quote: cleanOptional(cleanKeyMoment),
                    tags: cleanTags,
                    intensity: clampedIntensity,
                    watchContext: watchContext,
                    watchedDateApprox: .exact(Date()),
                    cinemaAudio: resolvedCinemaAudio,
                    cinemaScreen: resolvedCinemaScreen,
                    cinemaComfort: resolvedCinemaComfort,
                    visibility: visibility,
                    sharedCircleIds: cleanedSelectedCircleIds,
                    sourceType: .fullEntry,
                    externalMetadata: resolvedExternalMetadata,
                    watchedAt: Date(),
                    modelContext: modelContext
                )
            }

            return true
        } catch {
            errors = [error.localizedDescription]
            return false
        }
    }

    // MARK: - Dirty State

    func hasChanges(
        comparedTo entry: Entry,
        selectedCircleIds: [String]
    ) -> Bool {
        let currentMood = selectedMood?.label ?? ""
        let cleanedSelectedCircleIds = cleanCircleIds(selectedCircleIds)

        return type != entry.type ||
            cleanTitle != entry.title ||
            currentMood != entry.mood ||
            cleanTakeaway != entry.takeaway ||
            cleanKeyMoment != (entry.quote ?? "") ||
            clampedIntensity != entry.intensity ||
            cleanTags != EntryValidation.normalizedTags(entry.tags) ||
            watchContext != entry.watchContext ||
            resolvedCinemaAudio != entry.cinemaAudio ||
            resolvedCinemaScreen != entry.cinemaScreen ||
            resolvedCinemaComfort != entry.cinemaComfort ||
            cleanedSelectedCircleIds != cleanCircleIds(entry.sharedCircleIds) ||
            selectedTMDBResult != nil
    }

    private func hasChanges(comparedTo entry: Entry) -> Bool {
        let currentMood = selectedMood?.label ?? ""

        return type != entry.type ||
            cleanTitle != entry.title ||
            currentMood != entry.mood ||
            cleanTakeaway != entry.takeaway ||
            cleanKeyMoment != (entry.quote ?? "") ||
            clampedIntensity != entry.intensity ||
            cleanTags != EntryValidation.normalizedTags(entry.tags) ||
            watchContext != entry.watchContext ||
            resolvedCinemaAudio != entry.cinemaAudio ||
            resolvedCinemaScreen != entry.cinemaScreen ||
            resolvedCinemaComfort != entry.cinemaComfort ||
            selectedTMDBResult != nil
    }

    // MARK: - Resolved Values

    private var clampedIntensity: Int {
        min(
            max(intensity, EntryValidation.minIntensity),
            EntryValidation.maxIntensity
        )
    }

    private var resolvedCinemaAudio: Int? {
        watchContext == .cinema ? cinemaAudio : nil
    }

    private var resolvedCinemaScreen: Int? {
        watchContext == .cinema ? cinemaScreen : nil
    }

    private var resolvedCinemaComfort: Int? {
        watchContext == .cinema ? cinemaComfort : nil
    }

    private func resolvedReleaseYear(for entry: Entry) -> Int? {
        selectedTMDBResult?.releaseYear ?? entry.releaseYear
    }

    private func resolvedVisibility(
        selectedCircleIds: [String]
    ) -> EntryVisibility {
        selectedCircleIds.isEmpty ? .privateOnly : .circle
    }

    // MARK: - Input Normalization

    private func normalizeInputsBeforeValidation() {
        title = String(cleanTitle.prefix(EntryValidation.maxTitleLength))
        takeaway = String(cleanTakeaway.prefix(EntryValidation.maxTakeawayLength))
        keyMoment = String(cleanKeyMoment.prefix(EntryValidation.maxQuoteLength))
        tags = Array(cleanTags.prefix(EntryValidation.maxTags))
        intensity = clampedIntensity

        if watchContext != .cinema {
            cinemaAudio = nil
            cinemaScreen = nil
            cinemaComfort = nil
        }
    }

    private func cleanOptional(_ value: String) -> String? {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func cleanCircleIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }
            )
        )
        .sorted()
    }
}
