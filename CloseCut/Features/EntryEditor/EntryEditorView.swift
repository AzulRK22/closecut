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

    private enum Field {
        case title
        case takeaway
        case keyMoment
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        dragHandle
                        
                        if let helperMessage = viewModel.helperMessage {
                            Text(helperMessage)
                                .font(.subheadline)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

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

                        if hasCircleMembers {
                            visibilitySection
                        }

                        if !viewModel.errors.isEmpty {
                            errorSection
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleDismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
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
                    .disabled(!viewModel.canSave)
                    .foregroundStyle(viewModel.canSave ? CloseCutColors.accent : CloseCutColors.inactive)
                }
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(viewModel.isDirty)
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
            Text("Your changes won't be saved.")
        }
        .onAppear {
            if let entryToEdit {
                viewModel.configureForEdit(entry: entryToEdit)
            } else {
                viewModel.configureForNewEntry()
                focusedField = .title
            }
        }
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color(hex: "#636366"))
            .frame(width: 36, height: 4)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
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
                        .fill(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.errors.contains("Title is required.") ? CloseCutColors.failed : CloseCutColors.separator)
                        .frame(height: 0.5)
                }

            if viewModel.errors.contains("Title is required.") {
                Text("Title is required")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.failed)
            }
        }
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
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(CloseCutColors.separator, lineWidth: 0.5)
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

            Text("\(viewModel.takeaway.count)/\(EntryValidation.maxTakeawayLength)")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var keyMomentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key moment optional")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            TextField("A line that stayed with you…", text: $viewModel.keyMoment)
                .focused($focusedField, equals: .keyMoment)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(CloseCutColors.separator)
                        .frame(height: 0.5)
                }
        }
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

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Share with my circle", isOn: $viewModel.isSharedWithCircle)
                .tint(CloseCutColors.accent)
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Only your circle can see this.")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var errorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(viewModel.errors, id: \.self) { error in
                Text(error)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.failed)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.failedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func handleDismiss() {
        if viewModel.isDirty {
            showDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    private func save() async {
        let didSave = await viewModel.save(
            ownerId: user.id,
            defaultVisibility: profile.defaultVisibility,
            hasCircleMembers: hasCircleMembers,
            modelContext: modelContext
        )

        if didSave {
            dismiss()
        }
    }
}
