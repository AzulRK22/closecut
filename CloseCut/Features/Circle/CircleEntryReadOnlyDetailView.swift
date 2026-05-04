//
//  CircleEntryReadOnlyDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleEntryReadOnlyDetailView: View {
    let entry: Entry
    let currentUserId: String
    let currentUserDisplayName: String
    let circleId: String

    @State private var reactions: [CircleReaction] = []
    @State private var isLoadingSocial = false
    @State private var isUpdatingReaction = false
    @State private var socialErrorMessage: String?
    @State private var comments: [CircleComment] = []
    @State private var isSendingComment = false
    @State private var isDeletingCommentId: String?

    private let socialRemoteDataSource = CircleSocialRemoteDataSource()

    private var sharedByText: String {
        entry.ownerId == currentUserId ? "Shared by you" : "Shared by Circle member"
    }

    private var sharedContextText: String {
        entry.ownerId == currentUserId
            ? "You shared this from your Personal Timeline."
            : "A Circle member shared this from their Personal Timeline."
    }

    private var subtitle: String {
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

    private var moodText: String {
        if entry.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return entry.quickSentiment?.displayName ?? "Shared memory"
        }

        return entry.mood
    }

    private var takeawayText: String {
        if entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No takeaway was added."
        }

        return entry.takeaway
    }

    private var reactionCount: Int {
        reactions.count
    }

    private var commentCount: Int {
        comments.count
    }

    private var socialSummaryText: String {
        let reactionText = reactionCount == 1 ? "1 reaction" : "\(reactionCount) reactions"
        let commentText = commentCount == 1 ? "1 comment" : "\(commentCount) comments"

        return "\(reactionText) • \(commentText)"
    }

    private var tagColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 80), spacing: 8)
        ]
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let socialErrorMessage {
                        SyncResultBanner(
                            message: socialErrorMessage,
                            style: .warning
                        )
                    }

                    socialSummarySection

                    takeawaySection

                    keyMomentSection

                    memorySection

                    tagsSection

                    commentsSection

                    circleAccessSection

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable {
                await loadSocialData(force: true)
            }
        }
        .navigationTitle("Shared entry")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .task {
            await loadSocialData()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: entry.ownerId == currentUserId ? "person.fill.checkmark" : "person.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        CircleEntryStatusChip(
                            icon: "person.2.fill",
                            text: "Shared",
                            isHighlighted: true
                        )

                        CircleEntryStatusChip(
                            icon: entry.sourceType == .quickAdd ? "bolt.fill" : "film.fill",
                            text: entry.sourceType == .quickAdd ? "Quick Add" : entry.type.displayName,
                            isHighlighted: entry.sourceType == .quickAdd
                        )
                    }

                    Text(entry.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(sharedByText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .textCase(.uppercase)
                        .tracking(0.8)
                }

                Spacer()
            }

            Text(sharedContextText)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "eye")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("Read-only in Circle")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(socialSummaryText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
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

    private var socialSummarySection: some View {
        DetailSectionCard(title: "Circle reactions") {
            VStack(alignment: .leading, spacing: 12) {
                if isLoadingSocial && reactions.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()

                        Text("Loading reactions…")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)

                        Spacer()
                    }
                }

                CircleReactionBarView(
                    reactions: reactions,
                    currentUserId: currentUserId,
                    isUpdating: isUpdatingReaction,
                    onSelect: { type in
                        Task {
                            await toggleReaction(type)
                        }
                    }
                )

                if isUpdatingReaction {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)

                        Text("Updating reaction…")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                    }
                }

                Text("One active reaction per person. Selecting the same reaction removes it.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var takeawaySection: some View {
        DetailSectionCard(title: "Takeaway") {
            Text(takeawayText)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var keyMomentSection: some View {
        if let quote = entry.quote,
           quote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            DetailSectionCard(title: "Key moment") {
                Text("“\(quote)”")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var memorySection: some View {
        DetailSectionCard(title: "Watch details") {
            VStack(alignment: .leading, spacing: 12) {
                DetailInfoRow(label: "Mood", value: moodText)

                DetailInfoRow(
                    label: "Watched",
                    value: entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
                )

                DetailInfoRow(
                    label: "Context",
                    value: entry.watchContext.displayName
                )

                DetailInfoRow(
                    label: "Type",
                    value: subtitle
                )
            }
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if entry.tags.isEmpty == false {
            DetailSectionCard(title: "Tags") {
                LazyVGrid(columns: tagColumns, alignment: .leading, spacing: 8) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var commentsSection: some View {
        DetailSectionCard(title: "Comments") {
            CircleCommentsSectionView(
                comments: comments,
                currentUserId: currentUserId,
                isLoading: isLoadingSocial,
                isSending: isSendingComment,
                isDeletingCommentId: isDeletingCommentId,
                onSend: { text in
                    Task {
                        await sendComment(text)
                    }
                },
                onDelete: { comment in
                    Task {
                        await deleteComment(comment)
                    }
                }
            )
        }
    }

    private var circleAccessSection: some View {
        DetailSectionCard(title: "Circle access") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)

                    Text("Read-only shared memory")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                Text("Circle members can react and comment here, but only the owner can edit or delete the original entry from their Personal Timeline.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func loadSocialData(force: Bool = false) async {
        guard isLoadingSocial == false else {
            return
        }

        if (isUpdatingReaction || isSendingComment || isDeletingCommentId != nil) && force == false {
            return
        }

        isLoadingSocial = true
        socialErrorMessage = nil
        defer { isLoadingSocial = false }

        do {
            async let reactionsTask = socialRemoteDataSource.fetchReactions(
                entryId: entry.id
            )

            async let commentsTask = socialRemoteDataSource.fetchComments(
                entryId: entry.id
            )

            let (fetchedReactions, fetchedComments) = try await (
                reactionsTask,
                commentsTask
            )

            reactions = fetchedReactions
            comments = fetchedComments
        } catch {
            socialErrorMessage = "Couldn’t load reactions or comments."

            #if DEBUG
            print("⚠️ Failed to load social data:", error.localizedDescription)
            #endif
        }
    }

    private func toggleReaction(_ type: CircleReactionType) async {
        guard isUpdatingReaction == false else {
            return
        }

        isUpdatingReaction = true
        socialErrorMessage = nil
        defer { isUpdatingReaction = false }

        do {
            let currentReaction = reactions.first { $0.userId == currentUserId }

            if currentReaction?.type == type {
                try await socialRemoteDataSource.removeReaction(
                    entryId: entry.id,
                    userId: currentUserId
                )
            } else {
                _ = try await socialRemoteDataSource.setReaction(
                    entryId: entry.id,
                    circleId: circleId,
                    userId: currentUserId,
                    displayName: currentUserDisplayName,
                    type: type
                )
            }

            reactions = try await socialRemoteDataSource.fetchReactions(
                entryId: entry.id
            )
        } catch {
            socialErrorMessage = "Couldn’t update reaction."

            #if DEBUG
            print("❌ Failed to update reaction:", error.localizedDescription)
            #endif
        }
    }

    private func sendComment(_ text: String) async {
        guard isSendingComment == false else {
            return
        }

        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedText.isEmpty == false else {
            return
        }

        guard cleanedText.count <= 240 else {
            socialErrorMessage = "Comments must be 240 characters or less."
            return
        }

        isSendingComment = true
        socialErrorMessage = nil
        defer { isSendingComment = false }

        do {
            _ = try await socialRemoteDataSource.createComment(
                entryId: entry.id,
                circleId: circleId,
                userId: currentUserId,
                displayName: currentUserDisplayName,
                text: cleanedText
            )

            comments = try await socialRemoteDataSource.fetchComments(
                entryId: entry.id
            )
        } catch {
            socialErrorMessage = "Couldn’t send comment."

            #if DEBUG
            print("❌ Failed to send comment:", error.localizedDescription)
            #endif
        }
    }

    private func deleteComment(_ comment: CircleComment) async {
        guard comment.userId == currentUserId else {
            return
        }

        guard isDeletingCommentId == nil else {
            return
        }

        isDeletingCommentId = comment.id
        socialErrorMessage = nil
        defer { isDeletingCommentId = nil }

        do {
            try await socialRemoteDataSource.softDeleteComment(
                entryId: entry.id,
                commentId: comment.id,
                userId: currentUserId
            )

            comments.removeAll { $0.id == comment.id }
        } catch {
            socialErrorMessage = "Couldn’t delete comment."

            #if DEBUG
            print("❌ Failed to delete comment:", error.localizedDescription)
            #endif
        }
    }
}

private struct CircleEntryStatusChip: View {
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
