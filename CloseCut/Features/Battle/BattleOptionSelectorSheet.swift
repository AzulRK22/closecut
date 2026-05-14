//
//  BattleOptionSelectorSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct BattleOptionSelectorSheet: View {
    let entries: [Entry]
    let initialSelection: Set<String>
    let onCancel: () -> Void
    let onConfirm: ([Entry]) -> Void

    @State private var selectedEntryIds: Set<String> = []

    private var sortedEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var selectedEntries: [Entry] {
        sortedEntries.filter { selectedEntryIds.contains($0.id) }
    }

    private var canConfirm: Bool {
        selectedEntryIds.count >= 2
    }

    private var selectionProgressText: String {
        switch selectedEntryIds.count {
        case 0:
            return "Choose at least 2 titles"
        case 1:
            return "Choose 1 more title"
        default:
            return "\(selectedEntryIds.count) titles in your shortlist"
        }
    }

    private var confirmTitle: String {
        canConfirm ? "Pick from \(selectedEntryIds.count) options" : selectionProgressText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            header

                            shortlistProgressCard

                            entriesSection

                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }

                    footer
                }
            }
            .navigationTitle("Shortlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onConfirm(selectedEntries)
                    }
                    .disabled(canConfirm == false)
                    .foregroundStyle(canConfirm ? CloseCutColors.accent : CloseCutColors.inactive)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            let validEntryIds = Set(sortedEntries.map { $0.id })
            selectedEntryIds = initialSelection.intersection(validEntryIds)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Build tonight’s shortlist.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Choose the movies or series you’re actually considering. CloseCut will pick from this set.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.accent.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: "shuffle")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            HStack(spacing: 8) {
                infoPill(
                    icon: "film.stack",
                    text: "\(sortedEntries.count) available"
                )

                infoPill(
                    icon: "checkmark.circle.fill",
                    text: "\(selectedEntryIds.count) selected"
                )
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

    private func infoPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    // MARK: - Progress

    private var shortlistProgressCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                SwiftUI.Circle()
                    .fill(canConfirm ? CloseCutColors.accent.opacity(0.18) : CloseCutColors.input)
                    .frame(width: 40, height: 40)

                Image(systemName: canConfirm ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(canConfirm ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(canConfirm ? "Shortlist ready" : "Almost there")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(selectionProgressText)
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
                .stroke(canConfirm ? CloseCutColors.accentLight.opacity(0.55) : CloseCutColors.separator, lineWidth: canConfirm ? 0.8 : 0.5)
        }
    }

    // MARK: - Entries

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your watch history")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Tap to add or remove from tonight’s options.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 2)

            if sortedEntries.isEmpty {
                EmptyStateView(
                    title: "No entries yet",
                    message: "Add movies or series to your Personal Timeline before starting a Battle.",
                    systemImage: "film.stack",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(sortedEntries) { entry in
                        optionRow(entry)
                    }
                }
            }
        }
    }

    private func optionRow(_ entry: Entry) -> some View {
        let isSelected = selectedEntryIds.contains(entry.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                toggle(entry)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    EntryPosterThumbnailView(
                        entry: entry,
                        width: 58,
                        height: 86,
                        cornerRadius: 13
                    )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .background(
                                SwiftUI.Circle()
                                    .fill(CloseCutColors.backgroundPrimary)
                            )
                            .offset(x: 5, y: -5)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(subtitle(for: entry))
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        selectionIndicator(isSelected: isSelected)
                    }

                    Text(descriptionText(for: entry))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 7) {
                        if entry.sourceType == .quickAdd {
                            miniPill(
                                icon: "bolt.fill",
                                text: "Quick Add",
                                isHighlighted: true
                            )
                        }

                        miniPill(
                            icon: "sparkle",
                            text: moodText(for: entry),
                            isHighlighted: false
                        )
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(isSelected ? CloseCutColors.accent.opacity(0.10) : CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? CloseCutColors.accentLight.opacity(0.8) : CloseCutColors.separator,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.displayTitle), \(subtitle(for: entry)), \(isSelected ? "selected" : "not selected")")
    }

    private func selectionIndicator(isSelected: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: isSelected ? "checkmark" : "plus")
                .font(.caption2.weight(.bold))

            Text(isSelected ? "Added" : "Add")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(isSelected ? .white : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
        .clipShape(Capsule())
    }

    private func miniPill(
        icon: String,
        text: String,
        isHighlighted: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(CloseCutColors.separator)

            Button {
                onConfirm(selectedEntries)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: canConfirm ? "shuffle" : "plus.circle")
                        .font(.subheadline.weight(.semibold))

                    Text(confirmTitle)
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(canConfirm ? .white : CloseCutColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canConfirm ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canConfirm == false)

            Text("You can edit the shortlist anytime before picking again.")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Helpers

    private func subtitle(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if let rating = entry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if entry.visibility == .circle {
            parts.append("Shared")
        }

        return parts.joined(separator: " • ")
    }

    private func descriptionText(for entry: Entry) -> String {
        if let overview = cleanOptional(entry.overview) {
            return overview
        }

        let cleanedTakeaway = entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedTakeaway.isEmpty == false {
            return cleanedTakeaway
        }

        return "From your Personal Timeline."
    }

    private func moodText(for entry: Entry) -> String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return entry.quickSentiment?.displayName ?? "Memory"
        }

        return cleanedMood
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    private func toggle(_ entry: Entry) {
        if selectedEntryIds.contains(entry.id) {
            selectedEntryIds.remove(entry.id)
        } else {
            selectedEntryIds.insert(entry.id)
        }
    }
}
