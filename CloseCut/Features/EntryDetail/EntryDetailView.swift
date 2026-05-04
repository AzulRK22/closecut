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

    private var mood: Mood {
        Mood.from(entry.mood)
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

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    headerBlock

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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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
                    .disabled(isDeletingEntry)
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

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
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
                    }

                    Text(entry.title)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                MoodPill(
                    mood: mood,
                    size: .medium,
                    isSelected: false,
                    showLabel: true
                )
            }

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

            if entry.sourceType == .quickAdd {
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
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
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
                    value: entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
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
                    }

                    Spacer()
                }

                Text("This entry always stays in your Personal Timeline. Sharing only controls where else it appears.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
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
