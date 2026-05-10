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
    @FocusState private var focusedField: Field?

    let user: AuthUser
    let profile: UserProfile
    var entryToEdit: Entry? = nil
    var hasCircleMembers: Bool = false

    @State private var showDiscardConfirmation = false
    @State private var isShowingMediaSearch = false
    @State private var didConfigureViewModel = false
    @State private var isMetadataSectionExpanded = false
    @State private var selectedCircleIds: Set<String> = []

    @Query(sort: \LocalCircle.updatedAt, order: .reverse)
    private var localCircles: [LocalCircle]

    @Query(sort: \LocalCircleMembership.updatedAt, order: .reverse)
    private var localMemberships: [LocalCircleMembership]

    private enum Field {
        case title
        case takeaway
        case keyMoment
    }

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

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        dragHandle

                        editorHeader

                        mediaMetadataSection

                        TypeSelector(selectedType: $viewModel.type)

                        titleField

                        moodSection

                        takeawaySection

                        keyMomentSection

                        intensitySection

                        tagsSection

                        contextSection

                        if viewModel.shouldShowCinemaFields {
                            CinemaExperienceFields(
                                audio: $viewModel.cinemaAudio,
                                screen: $viewModel.cinemaScreen,
                                comfort: $viewModel.cinemaComfort
                            )
                            .animation(.easeInOut(duration: 0.2), value: viewModel.watchContext)
                        }

                        sharingSection

                        if viewModel.errors.isEmpty == false {
                            errorSection
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
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

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text(viewModel.saveButtonTitle)
                        }
                    }
                    .disabled(canSave == false)
                    .foregroundStyle(canSave ? CloseCutColors.accent : CloseCutColors.inactive)
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
        .sheet(isPresented: $isShowingMediaSearch) {
            MediaSearchView(
                title: "Search TMDB",
                subtitle: "Choose the movie or series that matches this entry.",
                placeholder: "Search title",
                onCancel: {
                    isShowingMediaSearch = false
                },
                onSelect: { result in
                    viewModel.selectTMDBResult(result)

                    withAnimation(.easeInOut(duration: 0.2)) {
                        isMetadataSectionExpanded = true
                    }

                    isShowingMediaSearch = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
            return "Turn this Quick Add into a richer memory."
        }

        if viewModel.isEditing {
            return "Update this memory."
        }

        return "Add a new watch memory."
    }

    private var headerSubtitle: String {
        if viewModel.isUpgradingQuickAdd {
            return "Add mood, takeaway, context, metadata, and Circle sharing when it makes sense."
        }

        if viewModel.isEditing {
            return "Keep your Timeline accurate without losing the original watch memory."
        }

        return "Capture what you watched, how it felt, and whether it belongs only to you or also to a Circle."
    }

    // MARK: - Metadata

    private var mediaMetadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isMetadataSectionExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "sparkles.tv")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 34, height: 34)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Media metadata")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text(metadataSummaryText)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: isMetadataSectionExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if isMetadataSectionExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.hasMetadataSelectionOrExistingMetadata {
                        selectedMetadataPreview
                    } else {
                        Text("Connect TMDB data to add poster, overview, rating, genres, and smarter QuickPick signals.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        isShowingMediaSearch = true
                    } label: {
                        Label(
                            viewModel.hasMetadataSelectionOrExistingMetadata ? "Change metadata" : "Search TMDB",
                            systemImage: "magnifyingglass"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(viewModel.hasMetadataSelectionOrExistingMetadata ? CloseCutColors.accentLight : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(viewModel.hasMetadataSelectionOrExistingMetadata ? CloseCutColors.input : CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    if viewModel.selectedTMDBResult != nil {
                        Button {
                            viewModel.clearSelectedTMDBResult()
                        } label: {
                            Text("Clear new TMDB selection")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textTertiary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(CloseCutColors.input.opacity(0.72))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var selectedMetadataPreview: some View {
        HStack(alignment: .top, spacing: 12) {
            MediaPosterView(
                posterPath: viewModel.metadataPosterPath,
                mediaType: viewModel.metadataMediaType,
                width: 54,
                height: 80,
                cornerRadius: 11
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(viewModel.selectedTMDBResult == nil ? "Connected metadata" : "Selected from TMDB")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .tracking(0.8)
                    .textCase(.uppercase)

                Text(viewModel.metadataDisplayTitle ?? viewModel.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)

                if let subtitle = viewModel.metadataSubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                }

                Text("This powers posters, detail context, and smarter recommendations.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var metadataSummaryText: String {
        if let subtitle = viewModel.metadataSubtitle,
           viewModel.hasMetadataSelectionOrExistingMetadata {
            return subtitle
        }

        if viewModel.hasMetadataSelectionOrExistingMetadata {
            return "TMDB metadata connected."
        }

        return "Add poster, overview, rating, and genres."
    }

    // MARK: - Main Fields

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Title")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            TextField("What did you watch?", text: $viewModel.title)
                .focused($focusedField, equals: .title)
                .font(.title3)
                .foregroundStyle(CloseCutColors.textPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .takeaway
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(titleFieldBorderColor)
                        .frame(height: 0.5)
                }
                .onChange(of: viewModel.title) { _, newValue in
                    if newValue.count > EntryValidation.maxTitleLength {
                        viewModel.title = String(newValue.prefix(EntryValidation.maxTitleLength))
                    }
                }

            HStack {
                if let releaseYear = viewModel.currentReleaseYear {
                    Text("Linked year: \(releaseYear)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Spacer()

                Text("\(viewModel.title.count)/\(EntryValidation.maxTitleLength)")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            if viewModel.errors.contains("Title is required.") {
                Text("Title is required")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.failed)
            }
        }
    }

    private var titleFieldBorderColor: Color {
        let isTitleMissing = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            viewModel.errors.contains("Title is required.")

        return isTitleMissing ? CloseCutColors.failed : CloseCutColors.separator
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How did it make you feel?")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            MoodPickerView(selectedMood: $viewModel.selectedMood)

            if viewModel.errors.contains("Choose a mood.") {
                Text("Choose a mood")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.failed)
            }
        }
    }

    private var takeawaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your takeaway")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            TextEditor(text: $viewModel.takeaway)
                .focused($focusedField, equals: .takeaway)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 88)
                .padding(10)
                .background(CloseCutColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(takeawayBorderColor, lineWidth: 0.5)
                }
                .overlay(alignment: .topLeading) {
                    if viewModel.takeaway.isEmpty {
                        Text("What stayed with you?")
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: viewModel.takeaway) { _, newValue in
                    if newValue.count > EntryValidation.maxTakeawayLength {
                        viewModel.takeaway = String(newValue.prefix(EntryValidation.maxTakeawayLength))
                    }
                }

            Text("\(viewModel.takeaway.count)/\(EntryValidation.maxTakeawayLength)")
                .font(.caption2)
                .foregroundStyle(
                    viewModel.takeaway.count > EntryValidation.maxTakeawayLength
                    ? CloseCutColors.failed
                    : CloseCutColors.textTertiary
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var takeawayBorderColor: Color {
        viewModel.takeaway.count > EntryValidation.maxTakeawayLength
            ? CloseCutColors.failed
            : CloseCutColors.separator
    }

    private var keyMomentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key moment optional")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            TextField("A line that stayed with you…", text: $viewModel.keyMoment, axis: .vertical)
                .focused($focusedField, equals: .keyMoment)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1...3)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(keyMomentBorderColor)
                        .frame(height: 0.5)
                }
                .onChange(of: viewModel.keyMoment) { _, newValue in
                    if newValue.count > EntryValidation.maxQuoteLength {
                        viewModel.keyMoment = String(newValue.prefix(EntryValidation.maxQuoteLength))
                    }
                }

            Text("\(viewModel.keyMoment.count)/\(EntryValidation.maxQuoteLength)")
                .font(.caption2)
                .foregroundStyle(
                    viewModel.keyMoment.count > EntryValidation.maxQuoteLength
                    ? CloseCutColors.failed
                    : CloseCutColors.textTertiary
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var keyMomentBorderColor: Color {
        viewModel.keyMoment.count > EntryValidation.maxQuoteLength
            ? CloseCutColors.failed
            : CloseCutColors.separator
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Intensity")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            IntensitySelector(value: $viewModel.intensity)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags optional")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            TagsInputView(tags: $viewModel.tags)
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Where did you watch it?")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            ContextSelector(selectedContext: $viewModel.watchContext)
        }
    }

    // MARK: - Sharing

    private var sharingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            CircleSharePickerView(
                circles: activeCircles,
                selectedCircleIds: $selectedCircleIds
            )

            if selectedCircleIds.isEmpty == false {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.top, 1)

                    Text("This entry remains in your Personal Timeline. Selected Circles only get read-only access with reactions and short comments.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
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
            isMetadataSectionExpanded = entryToEdit.hasTMDBMetadata == false
        } else {
            viewModel.configureForNewEntry()
            selectedCircleIds = []
            isMetadataSectionExpanded = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .title
            }
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
