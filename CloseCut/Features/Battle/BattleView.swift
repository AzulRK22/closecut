//
//  BattleView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/05/26.
//

import SwiftUI
import SwiftData

struct BattleView: View {
    let user: AuthUser
    let profile: UserProfile

    @State private var showOptionSelector = false
    @State private var selectedEntries: [Entry] = []
    @State private var pickedEntry: Entry?
    @State private var showHeadToHeadBattle = false

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    private var selectedEntryIds: Set<String> {
        Set(selectedEntries.map { $0.id })
    }

    private var canPickRandomWinner: Bool {
        selectedEntries.count >= 2
    }

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    private var eligibleEntries: [Entry] {
        entries.filter { entry in
            entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    private var canStartLocalBattle: Bool {
        eligibleEntries.count >= 2
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection

                        readinessCard

                        if let pickedEntry {
                            BattlePickResultCard(
                                winner: pickedEntry,
                                optionCount: selectedEntries.count,
                                onPickAgain: pickRandomWinner,
                                onClear: clearBattleSelection
                            )
                        }

                        if selectedEntries.isEmpty == false {
                            selectedOptionsSection
                        }

                        battleModesSection

                        futureSocialSection

                        whyItMattersSection

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Battle")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showOptionSelector) {
                BattleOptionSelectorSheet(
                    entries: eligibleEntries,
                    initialSelection: selectedEntryIds,
                    onCancel: {
                        showOptionSelector = false
                    },
                    onConfirm: { entries in
                        selectedEntries = entries
                        pickedEntry = nil
                        showOptionSelector = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showHeadToHeadBattle) {
                BattleHeadToHeadSheet(
                    entries: eligibleEntries,
                    currentUserId: user.id,
                    onCancel: {
                        showHeadToHeadBattle = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Turn taste into a game.")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Compare picks with yourself, a friend, or your Circle.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start with your own archive, then bring trusted people into the decision.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "bolt.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            HStack(spacing: 10) {
                battleStatPill(
                    value: "\(eligibleEntries.count)",
                    label: "eligible",
                    icon: "film.stack"
                )

                battleStatPill(
                    value: canStartLocalBattle ? "Ready" : "Soon",
                    label: "status",
                    icon: canStartLocalBattle ? "checkmark.circle.fill" : "clock.fill"
                )
            }
        }
    }

    private var readinessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: canStartLocalBattle ? "checkmark.circle.fill" : "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(canStartLocalBattle ? CloseCutColors.synced : CloseCutColors.accentLight)
                    .frame(width: 40, height: 40)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(canStartLocalBattle ? "Your archive is ready" : "Build your archive first")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(canStartLocalBattle ? "You have enough memories to start comparing titles or picking what to watch." : "Add at least two movies or series to unlock your first Battle.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                showOptionSelector = true
            } label: {
                HStack {
                    Image(systemName: "shuffle")

                    Text(canStartLocalBattle ? "Start with random pick" : "Need 2 entries")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canStartLocalBattle ? .white : CloseCutColors.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(canStartLocalBattle ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canStartLocalBattle == false)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var selectedOptionsSection: some View {
        battleSection(title: "Selected options") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(selectedEntries) { entry in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: entry.type == .movie ? "film.fill" : "tv.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .frame(width: 28, height: 28)
                            .background(CloseCutColors.input)
                            .clipShape(SwiftUI.Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .lineLimit(2)

                            Text(optionSubtitle(for: entry))
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }

                    if entry.id != selectedEntries.last?.id {
                        Divider()
                            .overlay(CloseCutColors.separator)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        showOptionSelector = true
                    } label: {
                        Text("Edit options")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        pickRandomWinner()
                    } label: {
                        Label("Pick one", systemImage: "shuffle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(canPickRandomWinner ? .white : CloseCutColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(canPickRandomWinner ? CloseCutColors.accent : CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(canPickRandomWinner == false)
                }
                .padding(.top, 2)
            }
        }
    }

    private var battleModesSection: some View {
        battleSection(title: "Personal battles") {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    showOptionSelector = true
                } label: {
                    battleModeRow(
                        icon: "shuffle",
                        title: "Pick what to watch",
                        status: canStartLocalBattle ? "Available now" : "Need 2 entries",
                        message: "Choose 2+ options and let CloseCut randomly pick one."
                    )
                }
                .buttonStyle(.plain)
                .disabled(canStartLocalBattle == false)

                Divider()
                    .overlay(CloseCutColors.separator)

                Button {
                    showHeadToHeadBattle = true
                } label: {
                    battleModeRow(
                        icon: "bolt.fill",
                        title: "Movie vs Movie",
                        status: canStartLocalBattle ? "Available now" : "Need 2 entries",
                        message: "Put two titles head-to-head and choose what wins for you."
                    )
                }
                .buttonStyle(.plain)
                .disabled(canStartLocalBattle == false)
            }
        }
    }

    private var futureSocialSection: some View {
        battleSection(title: "Social battles") {
            VStack(alignment: .leading, spacing: 14) {
                battleModeRow(
                    icon: "person.2.fill",
                    title: "Friend Battle",
                    status: "Coming later",
                    message: "Compare two picks with one trusted person. Best for a two-person Circle."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                battleModeRow(
                    icon: "person.3.fill",
                    title: "Circle Battle",
                    status: "Coming later",
                    message: "Vote privately with your Circle and pick a group winner."
                )
            }
        }
    }

    private var whyItMattersSection: some View {
        battleSection(title: "Why Battle exists") {
            Text("Battle turns your archive into a decision game. Use it to pick what to watch, compare favorites, and eventually decide with trusted people without turning CloseCut into a public social app.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func battleStatPill(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func battleModeRow(
        icon: String,
        title: String,
        status: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 32, height: 32)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Spacer()

                    Text(status)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)
                }

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func battleSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 2)

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
    }

    private func optionSubtitle(for entry: Entry) -> String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        if entry.visibility == .circle {
            parts.append("Shared")
        }

        return parts.joined(separator: " • ")
    }

    private func pickRandomWinner() {
        guard selectedEntries.count >= 2 else {
            pickedEntry = nil
            return
        }

        pickedEntry = selectedEntries.randomElement()
    }

    private func clearBattleSelection() {
        pickedEntry = nil
        selectedEntries = []
    }
}

#Preview {
    BattleView(
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview User",
            email: "preview@closecut.dev",
            photoURL: nil,
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
    .modelContainer(for: [
        LocalEntry.self,
        LocalReaction.self,
        LocalComment.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self
    ], inMemory: true)
}
