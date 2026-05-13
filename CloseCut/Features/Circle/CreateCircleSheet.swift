//
//  CreateCircleSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CreateCircleSheet: View {
    @Environment(\.dismiss) private var dismiss

    let isCreating: Bool
    let onCreate: (_ name: String, _ description: String) -> Void

    @State private var selectedPreset: CirclePreset?
    @State private var circleName = ""
    @State private var circleDescription = ""

    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case description
    }

    private var cleanedName: String {
        circleName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedDescription: String {
        circleDescription.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreate: Bool {
        cleanedName.isEmpty == false && isCreating == false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        presetSection

                        detailsSection

                        privacyCard

                        createButton

                        if isCreating {
                            loadingRow
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .disabled(isCreating)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                focusedField = .name
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent.opacity(0.18))
                    .frame(width: 52, height: 52)

                Image(systemName: "person.2.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Create a trusted space.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Start with one small group. You can create separate Circles later for different people.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Start with an idea",
                subtitle: "Optional presets help you set up faster."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CirclePreset.all) { preset in
                        CirclePresetChip(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        ) {
                            applyPreset(preset)
                        }
                    }
                }
            }

            if let selectedPreset {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: selectedPreset.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.top, 2)

                    Text(selectedPreset.description)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Circle details",
                subtitle: "Choose a name people will recognize."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Circle name")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("Friends, Family, Movie Club…", text: $circleName)
                    .focused($focusedField, equals: .name)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .description
                    }
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .onChange(of: circleName) { _, newValue in
                        updatePresetSelectionIfNeeded(for: newValue)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description optional")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                TextField("What is this Circle for?", text: $circleDescription, axis: .vertical)
                    .focused($focusedField, equals: .description)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .textInputAutocapitalization(.sentences)
                    .lineLimit(2...4)
                    .submitLabel(.done)
                    .padding(14)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Private by default")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Members only see entries explicitly shared with this Circle. Your Personal library stays yours.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

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

    private var createButton: some View {
        Button {
            guard canCreate else {
                return
            }

            onCreate(
                cleanedName,
                cleanedDescription
            )
        } label: {
            HStack(spacing: 8) {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.85)
                }

                Text(isCreating ? "Creating Circle…" : "Create Circle")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(canCreate ? .white : CloseCutColors.textTertiary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(canCreate ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(canCreate == false)
    }

    private var loadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Preparing your private space…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sectionHeader(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func applyPreset(_ preset: CirclePreset) {
        withAnimation(.easeInOut(duration: 0.18)) {
            selectedPreset = preset
            circleName = preset.title
            circleDescription = preset.description
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            focusedField = .description
        }
    }

    private func updatePresetSelectionIfNeeded(
        for newName: String
    ) {
        guard let selectedPreset else {
            return
        }

        let cleanedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedNewName != selectedPreset.title {
            self.selectedPreset = nil
        }
    }
}
