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

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    private var sharingText: String {
        guard isShared else {
            return "Private memory"
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

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    EntryDetailHeroView(
                        entry: entry,
                        profile: profile,
                        metadataText: metadataText,
                        sharingText: sharingText,
                        syncText: syncText,
                        shouldShowSyncStatus: shouldShowSyncStatus
                    )

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

                    EntryDetailMemoryCard(
                        entry: entry,
                        onCompleteMemory: {
                            isShowingEditSheet = true
                        }
                    )

                    if let quote = cleanOptional(entry.quote) {
                        keyMomentCard(quote)
                    }

                    EntryDetailSignalsCard(entry: entry)

                    EntryDetailMetadataCard(overview: entry.overview)

                    EntryDetailSharingCard(
                        entry: entry,
                        sharingText: sharingText,
                        syncText: syncText,
                        shouldShowSyncStatus: shouldShowSyncStatus,
                        onEditSharing: {
                            isShowingEditSheet = true
                        }
                    )

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
                            entry.sourceType == .quickAdd ? "Complete memory" : "Edit memory",
                            systemImage: "pencil"
                        )
                    }
                    .disabled(isDeletingEntry)

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label(
                            isDeletingEntry ? "Deleting..." : "Delete memory",
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
            "Delete this memory?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete memory", role: .destructive) {
                Task {
                    await deleteEntry()
                }
            }
            .disabled(isDeletingEntry)

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes it from your Personal library and any Circle timelines where it was shared. The change will sync later if needed.")
        }
        .alert("Couldn’t delete memory", isPresented: Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "Unknown error.")
        }
    }

    private func keyMomentCard(_ quote: String) -> some View {
        EntryDetailSectionCard(
            title: "Moment",
            subtitle: "A line, scene, or detail that stayed with you.",
            systemImage: "quote.opening"
        ) {
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
