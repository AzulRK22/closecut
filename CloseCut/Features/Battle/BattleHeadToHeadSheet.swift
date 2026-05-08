//
//  BattleHeadToHeadSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct BattleHeadToHeadSheet: View {
    let entries: [Entry]
    let currentUserId: String
    let onCancel: () -> Void
    let onWinnerSelected: (Entry, [Entry]) -> Void

    @State private var firstEntry: Entry?
    @State private var secondEntry: Entry?
    @State private var winner: Entry?
    @State private var lastSavedWinnerId: String?

    private var availableEntries: [Entry] {
        entries.sorted { first, second in
            first.watchedAt > second.watchedAt
        }
    }

    private var canStartBattle: Bool {
        firstEntry != nil && secondEntry != nil && firstEntry?.id != secondEntry?.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        pickerSection

                        if canStartBattle {
                            versusSection
                        }

                        if let winner {
                            winnerSection(winner)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Movie vs Movie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onCancel()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Put two titles head-to-head.")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Choose which one wins for you. This is about your taste, not public ratings.")
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var pickerSection: some View {
        battleCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Choose two entries")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                entryPicker(
                    title: "First title",
                    selectedEntry: $firstEntry,
                    excluding: secondEntry
                )

                entryPicker(
                    title: "Second title",
                    selectedEntry: $secondEntry,
                    excluding: firstEntry
                )

                if firstEntry?.id == secondEntry?.id && firstEntry != nil {
                    Text("Choose two different entries.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.failed)
                }
            }
        }
    }

    private func entryPicker(
        title: String,
        selectedEntry: Binding<Entry?>,
        excluding excludedEntry: Entry?
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .tracking(0.8)

            Menu {
                ForEach(availableEntries.filter { $0.id != excludedEntry?.id }) { entry in
                    Button {
                        selectedEntry.wrappedValue = entry
                        winner = nil
                        lastSavedWinnerId = nil
                    } label: {
                        Text(entry.title)
                    }
                }
            } label: {
                selectedPickerLabel(
                    entry: selectedEntry.wrappedValue
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func selectedPickerLabel(entry: Entry?) -> some View {
        HStack(spacing: 12) {
            if let entry {
                EntryPosterThumbnailView(
                    entry: entry,
                    width: 42,
                    height: 60,
                    cornerRadius: 10
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Text(subtitle(for: entry))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }
            } else {
                Image(systemName: "film.stack")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .frame(width: 42, height: 60)
                    .background(CloseCutColors.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text("Select entry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var versusSection: some View {
        if let firstEntry, let secondEntry {
            battleCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Choose the winner")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Spacer()

                        Image(systemName: "bolt.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                    }

                    battleOptionButton(entry: firstEntry)

                    HStack {
                        Rectangle()
                            .fill(CloseCutColors.separator)
                            .frame(height: 0.5)

                        Text("VS")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.horizontal, 8)

                        Rectangle()
                            .fill(CloseCutColors.separator)
                            .frame(height: 0.5)
                    }

                    battleOptionButton(entry: secondEntry)
                }
            }
        }
    }

    private func battleOptionButton(entry: Entry) -> some View {
        let isWinner = winner?.id == entry.id

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                winner = entry
            }

            if let firstEntry, let secondEntry, lastSavedWinnerId != entry.id {
                lastSavedWinnerId = entry.id
                onWinnerSelected(entry, [firstEntry, secondEntry])
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                EntryPosterThumbnailView(
                    entry: entry,
                    width: 64,
                    height: 94,
                    cornerRadius: 13
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(entry.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        if isWinner {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.accentLight)
                        }
                    }

                    Text(subtitle(for: entry))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    Text(moodText(for: entry))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)

                    if let overview = cleanOptional(entry.overview) {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isWinner ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: isWinner ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func winnerSection(_ winner: Entry) -> some View {
        battleCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    EntryPosterThumbnailView(
                        entry: winner,
                        width: 70,
                        height: 102,
                        cornerRadius: 14
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Winner")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(winner.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(subtitle(for: winner))
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(1)

                        Text("This title won your head-to-head taste battle.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                Button {
                    firstEntry = nil
                    secondEntry = nil
                    self.winner = nil
                    lastSavedWinnerId = nil
                } label: {
                    Text("Start another battle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func battleCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func subtitle(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if let rating = entry.tmdbRating, rating > 0 {
            parts.append(String(format: "%.1f TMDB", rating))
        }

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private func moodText(for entry: Entry) -> String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedMood.isEmpty {
            return entry.quickSentiment?.displayName ?? "No mood yet"
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
}
