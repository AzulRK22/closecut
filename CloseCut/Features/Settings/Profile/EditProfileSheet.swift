//
//  EditProfileSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 15/05/26.
//

import SwiftUI

struct EditProfileSheet: View {
    let currentDisplayName: String
    let currentAvatarPreset: AvatarPreset
    let isSaving: Bool
    let onCancel: () -> Void
    let onSave: (_ displayName: String, _ avatarPreset: AvatarPreset) -> Void

    @State private var displayName: String
    @State private var selectedAvatarPreset: AvatarPreset
    @FocusState private var isNameFocused: Bool

    init(
        currentDisplayName: String,
        currentAvatarPreset: AvatarPreset,
        isSaving: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (_ displayName: String, _ avatarPreset: AvatarPreset) -> Void
    ) {
        self.currentDisplayName = currentDisplayName
        self.currentAvatarPreset = currentAvatarPreset
        self.isSaving = isSaving
        self.onCancel = onCancel
        self.onSave = onSave

        _displayName = State(initialValue: currentDisplayName)
        _selectedAvatarPreset = State(initialValue: currentAvatarPreset)
    }

    private var cleanedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        cleanedDisplayName.isEmpty == false &&
        cleanedDisplayName.count <= 40 &&
        isSaving == false &&
        hasChanges
    }

    private var hasChanges: Bool {
        cleanedDisplayName != currentDisplayName.trimmingCharacters(in: .whitespacesAndNewlines) ||
        selectedAvatarPreset != currentAvatarPreset
    }

    private var validationMessage: String? {
        if cleanedDisplayName.isEmpty {
            return "Add a display name."
        }

        if cleanedDisplayName.count > 40 {
            return "Display name must be 40 characters or less."
        }

        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        nameSection

                        avatarSection

                        privacyNote

                        if isSaving {
                            loadingRow
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            cleanedDisplayName,
                            selectedAvatarPreset
                        )
                    }
                    .disabled(canSave == false)
                    .foregroundStyle(canSave ? CloseCutColors.accent : CloseCutColors.inactive)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                isNameFocused = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                SettingsAvatarView(
                    displayName: cleanedDisplayName.isEmpty ? "CloseCut user" : cleanedDisplayName,
                    preset: selectedAvatarPreset,
                    size: 72
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Shape your CloseCut identity.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Choose how you appear in your private spaces and Circles.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.94),
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var nameSection: some View {
        SettingsSectionCard(
            title: "Display name",
            subtitle: "This is visible to you and people in your private Circles."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Display name", text: $displayName)
                    .focused($isNameFocused)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack {
                    if let validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.failed)
                    } else {
                        Text("\(cleanedDisplayName.count)/40 characters")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }

                    Spacer()
                }
            }
        }
    }

    private var avatarSection: some View {
        SettingsSectionCard(
            title: "Avatar",
            subtitle: "Use a preset avatar for now. Photo upload can come later."
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 74), spacing: 12)
                ],
                alignment: .leading,
                spacing: 14
            ) {
                ForEach(AvatarPreset.allCases) { preset in
                    avatarPresetButton(preset)
                }
            }
        }
    }

    private func avatarPresetButton(
        _ preset: AvatarPreset
    ) -> some View {
        let isSelected = selectedAvatarPreset == preset

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedAvatarPreset = preset
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    SettingsAvatarView(
                        displayName: cleanedDisplayName.isEmpty ? "CC" : cleanedDisplayName,
                        preset: preset,
                        size: 58,
                        showsIcon: true
                    )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .background(
                                SwiftUI.Circle()
                                    .fill(CloseCutColors.backgroundPrimary)
                            )
                            .offset(x: 3, y: 3)
                    }
                }

                Text(preset.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(isSelected ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? CloseCutColors.accent.opacity(0.10) : CloseCutColors.input.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accentLight.opacity(0.75) : CloseCutColors.separator, lineWidth: isSelected ? 0.9 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.displayName) avatar")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .padding(.top, 2)

            Text("Changing your profile does not share your Personal Timeline. Your entries stay private unless you explicitly share them with a Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Saving profile…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
