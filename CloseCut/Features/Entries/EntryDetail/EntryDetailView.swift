//
//  EntryDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: Entry
    let user: AuthUser
    let profile: UserProfile

    @State private var isShowingEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeletingEntry = false
    @State private var deleteErrorMessage: String?

    private let entryRepository = EntryRepository()

    private var cleanedMood: String {
        entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var mood: Mood? {
        guard cleanedMood.isEmpty == false else {
            return nil
        }

        return Mood.from(cleanedMood)
    }

    private var moodDisplayText: String? {
        if cleanedMood.isEmpty == false {
            return Mood.from(cleanedMood).label
        }

        return entry.quickSentiment?.displayName
    }

    private var hasCinemaRatings: Bool {
        entry.watchContext == .cinema &&
        (entry.cinemaAudio != nil || entry.cinemaScreen != nil || entry.cinemaComfort != nil)
    }

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var sharingText: String {
        guard isShared else {
            return "Private"
        }

        if entry.sharedCircleIds.count == 1 {
            return "Shared with 1 Circle"
        }

        return "Shared with \(entry.sharedCircleIds.count) Circles"
    }

    private var syncText: String {
        switch entry.syncStatus {
        case .pending:
            return "Pending sync"
        case .synced:
            return "Synced"
        case .failed:
            return "Sync failed"
        }
    }

    private var shouldShowSyncStatus: Bool {
        entry.syncStatus != .synced
    }

    private var hasBackdrop: Bool {
        entry.backdropPath?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private var metadataText: String {
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

    private var overviewText: String? {
        cleanOptional(entry.overview)
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    heroMediaBlock

                    if entry.syncStatus == .failed {
                        SyncResultBanner(
                            message: "This entry failed to sync. Try syncing again from Settings.",
                            style: .warning
                        )
                    }

                    if isDeletingEntry {
                        SyncResultBanner(
                            message: "Deleting entry…",
                            style: .neutral
                        )
                    }

                    if let overviewText {
                        overviewBlock(overviewText)
                    }

                    takeawayBlock

                    contextBlock

                    if let quote = cleanOptional(entry.quote) {
                        keyMomentBlock(quote)
                    }

                    intensityBlock

                    if entry.tags.isEmpty == false {
                        tagsBlock
                    }

                    sharedStatusBlock

                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(CloseCutColors.accent)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        isShowingEditSheet = true
                    } label: {
                        Label(
                            entry.sourceType == .quickAdd ? "Add details" : "Edit",
                            systemImage: "pencil"
                        )
                    }
                    .disabled(isDeletingEntry)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(
                            isDeletingEntry ? "Deleting..." : "Delete entry",
                            systemImage: "trash"
                        )
                    }
                    .disabled(isDeletingEntry || entry.deletedAt != nil)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(CloseCutColors.accent)
                }
                .accessibilityLabel("Entry actions")
                .disabled(isDeletingEntry)
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EntryEditorView(
                user: user,
                profile: profile,
                entryToEdit: entry,
                hasCircleMembers: entry.isSharedWithCircle
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete entry", role: .destructive) {
                Task {
                    await deleteEntry()
                }
            }
            .disabled(isDeletingEntry)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes it from your Personal Timeline and any Circle timelines where it was shared. The change will sync later if needed.")
        }
        .alert("Couldn’t delete entry", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Unknown error.")
        }
    }

    private var heroMediaBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                backdropLayer

                LinearGradient(
                    colors: [
                        .clear,
                        CloseCutColors.card.opacity(0.88),
                        CloseCutColors.card
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: 14) {
                    EntryPosterThumbnailView(
                        entry: entry,
                        width: 86,
                        height: 126,
                        cornerRadius: 16
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        statusChips

                        Text(entry.title)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(metadataText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textTertiary)

                            Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textTertiary)

                            Text("•")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textTertiary)

                            Text("Added by \(profile.displayName)")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textTertiary)
                                .lineLimit(1)
                        }

                        if let mood {
                            MoodPill(
                                mood: mood,
                                size: .small,
                                isSelected: false,
                                showLabel: true
                            )
                        } else if let moodDisplayText {
                            EntryDetailStatusChip(
                                icon: "sparkles",
                                text: moodDisplayText,
                                isHighlighted: true
                            )
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
            }
            .frame(minHeight: hasBackdrop ? 220 : 176)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }

            if entry.sourceType == .quickAdd {
                quickAddNote
            }
        }
    }

    private var statusChips: some View {
        HStack(spacing: 6) {
            EntryDetailStatusChip(
                icon: entry.type == .movie ? "film.fill" : "tv.fill",
                text: entry.type.displayName,
                isHighlighted: false
            )

            if entry.sourceType == .quickAdd {
                EntryDetailStatusChip(
                    icon: "bolt.fill",
                    text: "Quick Add",
                    isHighlighted: true
                )
            }

            if isShared {
                EntryDetailStatusChip(
                    icon: "person.2.fill",
                    text: "Shared",
                    isHighlighted: true
                )
            }

            if shouldShowSyncStatus {
                EntryDetailStatusChip(
                    icon: entry.syncStatus == .failed ? "exclamationmark.triangle.fill" : "clock.fill",
                    text: syncText,
                    isHighlighted: false,
                    isWarning: entry.syncStatus == .failed
                )
            }
        }
    }

    @ViewBuilder
    private var backdropLayer: some View {
        if let backdropURL = entry.backdropURL {
            AsyncImage(url: backdropURL) { phase in
                switch phase {
                case .empty:
                    fallbackBackdrop

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    fallbackBackdrop

                @unknown default:
                    fallbackBackdrop
                }
            }
        } else {
            fallbackBackdrop
        }
    }

    private var fallbackBackdrop: some View {
        ZStack {
            CloseCutColors.card

            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.22),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var quickAddNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)

            Text("This started as a Quick Add. Add details anytime to turn it into a richer memory.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func overviewBlock(_ overview: String) -> some View {
        DetailSectionCard(title: "Overview") {
            Text(overview)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                Text(
                    entry.sourceType == .quickAdd
                    ? "No details yet. Add mood, takeaway, tags, and context when you're ready."
                    : "No takeaway added."
                )
                .font(.body)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
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
                    label: "Watched",
                    value: watchedDateText
                )

                DetailInfoRow(
                    label: "Visibility",
                    value: sharingText
                )

                if shouldShowSyncStatus {
                    DetailInfoRow(
                        label: "Sync",
                        value: syncText
                    )
                }

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

    private var watchedDateText: String {
        if let watchedDateApprox = entry.watchedDateApprox {
            return watchedDateApprox.displayLabel
        }

        return entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
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

    private var sharedStatusBlock: some View {
        DetailSectionCard(title: "Circle sharing") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: isShared ? "person.2.fill" : "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isShared ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(sharingText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text(isShared ? "Circle members can view, react, and comment." : "Only you can see this memory.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }

                Text("This entry always stays in your Personal Timeline. Sharing only controls where else it appears.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    isShowingEditSheet = true
                } label: {
                    Text(isShared ? "Edit sharing" : "Share with a Circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isDeletingEntry)
            }
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    private func deleteEntry() async {
        guard isDeletingEntry == false else {
            return
        }

        guard entry.deletedAt == nil else {
            dismiss()
            return
        }

        isDeletingEntry = true
        deleteErrorMessage = nil

        do {
            _ = try entryRepository.softDeleteLocalEntry(
                entryId: entry.id,
                modelContext: modelContext
            )

            isDeletingEntry = false

            await MainActor.run {
                dismiss()
            }
        } catch {
            isDeletingEntry = false
            deleteErrorMessage = error.localizedDescription

            #if DEBUG
            print("❌ Failed to delete entry:", error.localizedDescription)
            #endif
        }
    }
}

private struct EntryDetailStatusChip: View {
    let icon: String
    let text: String
    var isHighlighted: Bool = false
    var isWarning: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    private var foregroundColor: Color {
        if isWarning {
            return CloseCutColors.failed
        }

        if isHighlighted {
            return CloseCutColors.accentLight
        }

        return CloseCutColors.textTertiary
    }
}
