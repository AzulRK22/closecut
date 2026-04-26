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

    var isDirty: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
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

        let visibility: EntryVisibility

        if hasCircleMembers && isSharedWithCircle {
            visibility = .circle
        } else {
            visibility = defaultVisibility == .circle && hasCircleMembers ? .circle : .privateOnly
        }

        do {
            _ = try repository.createLocalEntry(
                ownerId: ownerId,
                title: title,
                type: type,
                mood: selectedMood.label,
                takeaway: takeaway,
                quote: keyMoment,
                tags: tags,
                intensity: intensity,
                watchContext: watchContext,
                cinemaAudio: cinemaAudio,
                cinemaScreen: cinemaScreen,
                cinemaComfort: cinemaComfort,
                visibility: visibility,
                watchedAt: Date(),
                modelContext: modelContext
            )

            return true
        } catch {
            errors = [error.localizedDescription]
            return false
        }
    }
}
