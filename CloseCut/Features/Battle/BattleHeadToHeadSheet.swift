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

    @State private var firstEntry: Entry?
    @State private var secondEntry: Entry?
    @State private var winner: Entry?

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
                    } label: {
                        Text(entry.title)
                    }
                }
            } label: {
                HStack {
                    Text(selectedEntry.wrappedValue?.title ?? "Select entry")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedEntry.wrappedValue == nil ? CloseCutColors.textTertiary : CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .padding(14)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
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
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                winner = entry
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon(for: entry))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(winner?.id == entry.id ? .white : CloseCutColors.accentLight)
                    .frame(width: 38, height: 38)
                    .background(winner?.id == entry.id ? CloseCutColors.accent : CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)

                    Text(subtitle(for: entry))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)

                    Text(moodText(for: entry))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if winner?.id == entry.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }
            .padding(14)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(winner?.id == entry.id ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: winner?.id == entry.id ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private func winnerSection(_ winner: Entry) -> some View {
        battleCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 42, height: 42)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Winner")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Text(winner.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("This title won your head-to-head taste battle.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                    }

                    Spacer()
                }

                Button {
                    firstEntry = nil
                    secondEntry = nil
                    self.winner = nil
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

    private func icon(for entry: Entry) -> String {
        entry.type == .movie ? "film.fill" : "tv.fill"
    }

    private func subtitle(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private func moodText(for entry: Entry) -> String {
        if entry.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return entry.quickSentiment?.displayName ?? "No mood yet"
        }

        return entry.mood
    }
}
