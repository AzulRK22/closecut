//
//  EntryDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI

struct EntryDetailView: View {
    let entry: Entry
    let user: AuthUser
    let profile: UserProfile

    @State private var isShowingEditSheet = false

    private var mood: Mood {
        Mood.from(entry.mood)
    }

    private var hasCinemaRatings: Bool {
        entry.watchContext == .cinema &&
        (entry.cinemaAudio != nil || entry.cinemaScreen != nil || entry.cinemaComfort != nil)
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerBlock

                    if entry.syncStatus != .synced {
                        PendingSyncBadge(status: entry.syncStatus)
                            .padding(.top, 4)
                    }

                    takeawayBlock

                    contextBlock

                    if let quote = cleanOptional(entry.quote) {
                        keyMomentBlock(quote)
                    }

                    intensityBlock

                    if !entry.tags.isEmpty {
                        tagsBlock
                    }

                    if entry.isSharedWithCircle {
                        sharedPlaceholderBlock
                    }

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(entry.sourceType == .quickAdd ? "Add details" : "Edit") {
                    isShowingEditSheet = true
                }
                .foregroundStyle(CloseCutColors.accent)
                .accessibilityLabel("Edit entry")
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EntryEditorView(
                user: user,
                profile: profile,
                entryToEdit: entry,
                hasCircleMembers: false
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.type.displayName)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
                if entry.sourceType == .quickAdd {
                    Text("Quick Add")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }
                Spacer()
                MoodPill(
                    mood: mood,
                    size: .medium,
                    isSelected: false,
                    showLabel: true
                )
            }
            Text(entry.title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(CloseCutColors.textPrimary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text("Added by \(profile.displayName)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(entry.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
        .padding(.bottom, 4)
    }

    private var takeawayBlock: some View {
        DetailSectionCard(title: "Takeaway") {
            if let takeaway = cleanOptional(entry.takeaway) {
                Text(takeaway)
                    .font(.body.italic())
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(entry.sourceType == .quickAdd ? "No details yet. Add mood, takeaway, tags, and context when you're ready." : "No takeaway added.")
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
    }

    private var contextBlock: some View {
        DetailSectionCard(title: "Context") {
            VStack(spacing: 8) {
                DetailInfoRow(
                    label: "Where",
                    value: entry.watchContext.displayName
                )

                DetailInfoRow(
                    label: "When",
                    value: entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
                )

                DetailInfoRow(
                    label: "Visibility",
                    value: entry.visibility == .circle ? "Shared with Circle" : "Private"
                )

                if hasCinemaRatings {
                    Divider()
                        .overlay(CloseCutColors.separator)
                        .padding(.vertical, 4)

                    CinemaRatingsView(
                        audio: entry.cinemaAudio,
                        screen: entry.cinemaScreen,
                        comfort: entry.cinemaComfort
                    )
                }
            }
        }
    }

    private func keyMomentBlock(_ quote: String) -> some View {
        DetailSectionCard(title: "Key Moment") {
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(CloseCutColors.accent)
                    .frame(width: 3)

                Text("“\(quote)”")
                    .font(.body.italic())
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var intensityBlock: some View {
        DetailSectionCard(title: "Intensity") {
            IntensitySelector(
                value: .constant(entry.intensity),
                isEditable: false
            )
        }
    }

    private var tagsBlock: some View {
        DetailSectionCard(title: "Tags") {
            ReadOnlyTagsView(tags: entry.tags)
        }
    }

    private var sharedPlaceholderBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            DetailSectionCard(title: "Reactions") {
                Text("Reactions will appear here once Circle sync is connected.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
            }

            DetailSectionCard(title: "Comments") {
                Text("Comments will appear here once Circle sync is connected.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
            }
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}

