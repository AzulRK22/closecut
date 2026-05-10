//
//  EntryEditorViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import Combine
import SwiftData

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

    // Kept for compatibility with older UI/code, but no longer drives sharing.
    @Published var isSharedWithCircle: Bool = false

    @Published private(set) var selectedTMDBResult: TMDBMediaSearchResult?

    @Published var isSaving: Bool = false
    @Published var errors: [String] = []

    private let repository = EntryRepository()
    private(set) var editingEntry: Entry?

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

    var isDirty: Bool {
        if let editingEntry {
            return hasChanges(comparedTo: editingEntry)
        }

        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedMood != nil ||
        !takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !keyMoment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !tags.isEmpty ||
        selectedTMDBResult != nil
    }

    var canSave: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false &&
        selectedMood != nil &&
        isSaving == false
    }

    var shouldShowCinemaFields: Bool {
        watchContext == .cinema
    }

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
        tags = entry.tags
        watchContext = entry.watchContext
        cinemaAudio = entry.cinemaAudio
        cinemaScreen = entry.cinemaScreen
        cinemaComfort = entry.cinemaComfort
        isSharedWithCircle = entry.isSharedWithCircle
        selectedTMDBResult = nil
        errors = []
    }

    func selectTMDBResult(_ result: TMDBMediaSearchResult) {
        selectedTMDBResult = result
        title = result.title
        type = result.entryType
        errors.removeAll { $0 == "Title is required." }
    }

    func clearSelectedTMDBResult() {
        selectedTMDBResult = nil
    }

    func save(
        ownerId: String,
        defaultVisibility: EntryVisibility,
        selectedCircleIds: [String],
        modelContext: ModelContext
    ) async -> Bool {
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

        isSaving = true
        defer { isSaving = false }

        let cleanedSelectedCircleIds = cleanCircleIds(selectedCircleIds)
        let visibility = cleanedSelectedCircleIds.isEmpty
            ? EntryVisibility.privateOnly
            : EntryVisibility.circle

        do {
            if let editingEntry {
                _ = try repository.updateLocalEntry(
                    entryId: editingEntry.id,
                    title: title,
                    type: type,
                    releaseYear: selectedTMDBResult?.releaseYear ?? editingEntry.releaseYear,
                    mood: selectedMood.label,
                    quickSentiment: editingEntry.quickSentiment,
                    takeaway: takeaway,
                    quote: keyMoment,
                    tags: tags,
                    intensity: intensity,
                    watchContext: watchContext,
                    watchedDateApprox: editingEntry.watchedDateApprox,
                    cinemaAudio: cinemaAudio,
                    cinemaScreen: cinemaScreen,
                    cinemaComfort: cinemaComfort,
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
                    title: title,
                    type: type,
                    releaseYear: selectedTMDBResult?.releaseYear,
                    mood: selectedMood.label,
                    quickSentiment: nil,
                    takeaway: takeaway,
                    quote: keyMoment,
                    tags: tags,
                    intensity: intensity,
                    watchContext: watchContext,
                    watchedDateApprox: .exact(Date()),
                    cinemaAudio: cinemaAudio,
                    cinemaScreen: cinemaScreen,
                    cinemaComfort: cinemaComfort,
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

    func hasChanges(
        comparedTo entry: Entry,
        selectedCircleIds: [String]
    ) -> Bool {
        let currentMood = selectedMood?.label ?? ""
        let cleanedSelectedCircleIds = cleanCircleIds(selectedCircleIds)

        return type != entry.type ||
        title != entry.title ||
        currentMood != entry.mood ||
        takeaway != entry.takeaway ||
        keyMoment != (entry.quote ?? "") ||
        intensity != entry.intensity ||
        tags != entry.tags ||
        watchContext != entry.watchContext ||
        cinemaAudio != entry.cinemaAudio ||
        cinemaScreen != entry.cinemaScreen ||
        cinemaComfort != entry.cinemaComfort ||
        cleanedSelectedCircleIds != cleanCircleIds(entry.sharedCircleIds) ||
        selectedTMDBResult != nil
    }

    private func hasChanges(comparedTo entry: Entry) -> Bool {
        let currentMood = selectedMood?.label ?? ""

        return type != entry.type ||
        title != entry.title ||
        currentMood != entry.mood ||
        takeaway != entry.takeaway ||
        keyMoment != (entry.quote ?? "") ||
        intensity != entry.intensity ||
        tags != entry.tags ||
        watchContext != entry.watchContext ||
        cinemaAudio != entry.cinemaAudio ||
        cinemaScreen != entry.cinemaScreen ||
        cinemaComfort != entry.cinemaComfort ||
        isSharedWithCircle != entry.isSharedWithCircle ||
        selectedTMDBResult != nil
    }

    private func cleanCircleIds(_ ids: [String]) -> [String] {
        Array(
            Set(
                ids
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            )
        )
        .sorted()
    }
}
