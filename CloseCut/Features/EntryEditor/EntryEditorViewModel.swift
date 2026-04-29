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
    @Published var isSharedWithCircle: Bool = false
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

    var isDirty: Bool {
        if let editingEntry {
            return hasChanges(comparedTo: editingEntry)
        }

        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedMood != nil ||
        !takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !keyMoment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !tags.isEmpty
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
        isSharedWithCircle = entry.visibility == .circle
        errors = []
    }

    func save(
        ownerId: String,
        defaultVisibility: EntryVisibility,
        hasCircleMembers: Bool,
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

        let visibility = resolvedVisibility(
            defaultVisibility: defaultVisibility,
            hasCircleMembers: hasCircleMembers
        )

        do {
            if let editingEntry {
                _ = try repository.updateLocalEntry(
                    entryId: editingEntry.id,
                    title: title,
                    type: type,
                    releaseYear: editingEntry.releaseYear,
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
                    sourceType: .fullEntry,
                    watchedAt: editingEntry.watchedAt,
                    modelContext: modelContext
                )
            } else {
                _ = try repository.createLocalEntry(
                    ownerId: ownerId,
                    title: title,
                    type: type,
                    releaseYear: nil,
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
                    sourceType: .fullEntry,
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

    private func resolvedVisibility(
        defaultVisibility: EntryVisibility,
        hasCircleMembers: Bool
    ) -> EntryVisibility {
        if hasCircleMembers && isSharedWithCircle {
            return .circle
        }

        if editingEntry == nil,
           defaultVisibility == .circle,
           hasCircleMembers {
            return .circle
        }

        return .privateOnly
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
        isSharedWithCircle != (entry.visibility == .circle)
    }
}
