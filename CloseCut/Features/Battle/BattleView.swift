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

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

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
                // Future: open local Battle creation flow.
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")

                    Text(canStartLocalBattle ? "Start Battle" : "Need 2 entries")
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

    private var battleModesSection: some View {
        battleSection(title: "Personal modes") {
            VStack(alignment: .leading, spacing: 14) {
                battleModeRow(
                    icon: "shuffle",
                    title: "Pick what to watch",
                    status: canStartLocalBattle ? "Ready soon" : "Need 2 entries",
                    message: "Choose 2+ options from your Timeline and let CloseCut pick one."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                battleModeRow(
                    icon: "bolt.fill",
                    title: "Movie vs Movie",
                    status: canStartLocalBattle ? "Ready soon" : "Need 2 entries",
                    message: "Put two titles head-to-head and decide what wins."
                )
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
                    message: "Compare two picks with one trusted person. Built on private Circles."
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
            Text("CloseCut is not only about remembering what you watched. Battle makes your taste playful, helps surface favorites, and gives Circles a lightweight entertainment layer without becoming a public social app.")
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
