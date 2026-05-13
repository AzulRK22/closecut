//
//  EntryEditorView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = EntryEditorViewModel()
    @FocusState private var focusedField: EntryEditorFocusField?

    let user: AuthUser
    let profile: UserProfile
    var entryToEdit: Entry? = nil
    var hasCircleMembers: Bool = false

    @State private var showDiscardConfirmation = false
    @State private var didConfigureViewModel = false
    @State private var selectedCircleIds: Set<String> = []

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    private var activeCircleMemberships: [CircleMembership] {
        localMemberships
            .filter { $0.userId == user.id }
            .map { $0.domain }
            .filter { $0.isActive }
    }

    private var activeCircles: [CloseCircle] {
        let activeCircleIds = Set(activeCircleMemberships.map { $0.circleId })

        return localCircles
            .map { $0.domain }
            .filter { activeCircleIds.contains($0.id) }
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                first.updatedAt > second.updatedAt
            }
    }

    private var isEditorDirty: Bool {
        if let entryToEdit {
            return viewModel.hasChanges(
                comparedTo: entryToEdit,
                selectedCircleIds: Array(selectedCircleIds)
            )
        }

        return viewModel.isDirty || selectedCircleIds.isEmpty == false
    }

    private var canSave: Bool {
        viewModel.canSave && viewModel.isSaving == false
    }

    private var hasSelectedCircles: Bool {
        selectedCircleIds.isEmpty == false
    }

    private var selectedCircleCountText: String {
        if selectedCircleIds.isEmpty {
            return "Private"
        }

        if selectedCircleIds.count == 1 {
            return "Shared with 1 Circle"
        }

        return "Shared with \(selectedCircleIds.count) Circles"
    }

    private var saveContextText: String {
        if viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add a title to continue."
        }

        if viewModel.selectedMood == nil {
            return "Choose a feeling to save this memory."
        }

        if selectedCircleIds.isEmpty {
            return "This will stay private in your Personal library."
        }

        return selectedCircleCountText
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        dragHandle

                        editorHeader

                        titleAutocompleteSection

                        memorySection

                        moreContextSection

                        privacySection

                        if viewModel.errors.isEmpty == false {
                            errorSection
                        }

                        Spacer(minLength: 112)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)

                EntryEditorSaveBar(
                    canSave: canSave,
                    isSaving: viewModel.isSaving,
                    buttonTitle: viewModel.saveButtonTitle,
                    contextText: saveContextText,
                    action: {
                        Task {
                            await save()
                        }
                    }
                )
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleDismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(isEditorDirty || viewModel.isSaving)
        .confirmationDialog(
            "Discard entry?",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                dismiss()
            }

            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Your changes won’t be saved.")
        }
        .onAppear {
            configureViewModelIfNeeded()
        }
    }

    // MARK: - Header

    private var dragHandle: some View {
        Capsule()
            .fill(Color(hex: "#636366"))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .accessibilityHidden(true)
    }

    private var editorHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: entryToEdit?.sourceType == .quickAdd ? "bolt.fill" : "film.stack.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 40, height: 40)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(headerTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(headerSubtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if hasSelectedCircles || entryToEdit?.isSharedWithCircle == true {
                HStack(spacing: 8) {
                    Image(systemName: hasSelectedCircles ? "person.2.fill" : "lock.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(hasSelectedCircles ? CloseCutColors.accentLight : CloseCutColors.textTertiary)

                    Text(selectedCircleCountText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(hasSelectedCircles ? CloseCutColors.accentLight : CloseCutColors.textTertiary)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var headerTitle: String {
        if viewModel.isUpgradingQuickAdd {
            return "Complete this memory."
        }

        if viewModel.isEditing {
            return "Update this memory."
        }

        return "Add a new memory."
    }

    private var headerSubtitle: String {
        if viewModel.isUpgradingQuickAdd {
            return "You already added this title. Now capture what made it yours."
        }

        if viewModel.isEditing {
            return "Adjust the details without losing the original memory."
        }

        return "Start with the title, then capture how it felt."
    }

    // MARK: - Sections

    private var titleAutocompleteSection: some View {
        EntryTitleAutocompleteCard(
            title: $viewModel.title,
            type: $viewModel.type,
            selectedResult: viewModel.selectedTMDBResult,
            existingPosterPath: viewModel.metadataPosterPath,
            existingSubtitle: viewModel.metadataSubtitle,
            existingMediaType: viewModel.metadataMediaType,
            suggestions: viewModel.tmdbSuggestions,
            isSearching: viewModel.isSearchingTMDB,
            searchErrorMessage: viewModel.tmdbSearchError,
            errors: viewModel.errors,
            onTitleChanged: {
                viewModel.titleDidChange()
            },
            onSubmitSearch: {
                viewModel.runTitleSearchImmediately()
            },
            onSelectResult: { result in
                viewModel.selectTMDBResult(result)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    focusedField = .takeaway
                }
            },
            onClearSelection: {
                viewModel.clearSelectedTMDBResult()
            }
        )
    }

    private var memorySection: some View {
        EntryMemoryCard(
            selectedMood: $viewModel.selectedMood,
            takeaway: $viewModel.takeaway,
            errors: viewModel.errors,
            focusedField: $focusedField
        )
    }

    private var moreContextSection: some View {
        EntryMoreContextCard(
            keyMoment: $viewModel.keyMoment,
            intensity: $viewModel.intensity,
            tags: $viewModel.tags,
            watchContext: $viewModel.watchContext,
            cinemaAudio: $viewModel.cinemaAudio,
            cinemaScreen: $viewModel.cinemaScreen,
            cinemaComfort: $viewModel.cinemaComfort,
            focusedField: $focusedField
        )
    }

    private var privacySection: some View {
        EntryEditorPrivacyCard(
            circles: activeCircles,
            selectedCircleIds: $selectedCircleIds
        )
    }

    // MARK: - Errors

    private var errorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.failed)

                Text("Fix before saving")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
            }

            ForEach(viewModel.errors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.failedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.failed.opacity(0.45), lineWidth: 0.5)
        }
    }

    // MARK: - Actions

    private func configureViewModelIfNeeded() {
        guard didConfigureViewModel == false else {
            return
        }

        didConfigureViewModel = true

        if let entryToEdit {
            viewModel.configureForEdit(entry: entryToEdit)
            selectedCircleIds = Set(entryToEdit.sharedCircleIds)

            if viewModel.isUpgradingQuickAdd {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    focusedField = .takeaway
                }
            }
        } else {
            viewModel.configureForNewEntry()
            selectedCircleIds = []
        }
    }

    private func handleDismiss() {
        guard viewModel.isSaving == false else {
            return
        }

        if isEditorDirty {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() async {
        let didSave = await viewModel.save(
            ownerId: user.id,
            defaultVisibility: profile.defaultVisibility,
            selectedCircleIds: Array(selectedCircleIds),
            modelContext: modelContext
        )

        if didSave {
            dismiss()
        }
    }
}
