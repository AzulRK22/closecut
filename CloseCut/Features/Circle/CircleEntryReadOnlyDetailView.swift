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
    @State private var comments: [CircleComment] = []
    
    @State private var isLoadingSocial = false
    @State private var isUpdatingReaction = false
    @State private var isSendingComment = false
    @State private var isDeletingCommentId: String?
    
    @State private var socialErrorMessage: String?
    
    private let socialRemoteDataSource = CircleSocialRemoteDataSource()
    
    // MARK: - Access Validation
    
    private var cleanedCircleId: String {
        circleId.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isEntryDeleted: Bool {
        entry.deletedAt != nil
    }
    
    private var isSharedWithCurrentCircle: Bool {
        entry.visibility == .circle &&
        entry.sharedCircleIds.contains(cleanedCircleId)
    }
    
    private var canUseCircleSocial: Bool {
        cleanedCircleId.isEmpty == false &&
        isEntryDeleted == false &&
        isSharedWithCurrentCircle
    }
    
    private var socialUnavailableMessage: String {
        if isEntryDeleted {
            return "This entry is no longer available for Circle reactions or comments."
        }
        
        if cleanedCircleId.isEmpty {
            return "Circle context is missing, so reactions and comments are unavailable."
        }
        
        if isSharedWithCurrentCircle == false {
            return "This entry is not currently shared with this Circle, so reactions and comments are unavailable."
        }
        
        return "Circle reactions and comments are unavailable for this entry."
    }
    
    // MARK: - Display Text
    
    private var sharedByText: String {
        entry.ownerId == currentUserId ? "Shared by you" : "Shared by Circle member"
    }
    
    private var sharedContextText: String {
        entry.ownerId == currentUserId
        ? "You shared this from your Personal Timeline."
        : "A Circle member shared this from their Personal Timeline."
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
    
    private var moodText: String {
        let cleanedMood = entry.mood.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedMood.isEmpty {
            return entry.quickSentiment?.displayName ?? "Shared memory"
        }
        
        return cleanedMood
    }
    
    private var takeawayText: String {
        let cleanedTakeaway = entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedTakeaway.isEmpty {
            return "No takeaway was added."
        }
        
        return cleanedTakeaway
    }
    
    private var overviewText: String? {
        cleanOptional(entry.overview)
    }
    
    private var hasBackdrop: Bool {
        entry.backdropPath?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
    
    private var reactionCount: Int {
        reactions.count
    }
    
    private var commentCount: Int {
        comments.count
    }
    
    private var socialSummaryText: String {
        if canUseCircleSocial == false {
            return "Social unavailable"
        }
        
        let reactionText = reactionCount == 1 ? "1 reaction" : "\(reactionCount) reactions"
        let commentText = commentCount == 1 ? "1 comment" : "\(commentCount) comments"
        
        return "\(reactionText) • \(commentText)"
    }
    
    private var tagColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 80), spacing: 8)
        ]
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroMediaBlock
                    
                    if let socialErrorMessage {
                        SyncResultBanner(
                            message: socialErrorMessage,
                            style: .warning
                        )
                    }
                    
                    socialSummarySection
                    
                    if let overviewText {
                        overviewSection(overviewText)
                    }
                    
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(CloseCutColors.accent)
        .preferredColorScheme(.dark)
        .task(id: "\(entry.id)-\(cleanedCircleId)") {
            await loadSocialData()
        }
    }
    // MARK: - Hero
    
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
                        
                        Text(sharedByText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .lineLimit(1)
                        
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
            
            sharedContextNote
        }
    }
    
    private var statusChips: some View {
        HStack(spacing: 6) {
            CircleEntryStatusChip(
                icon: "person.2.fill",
                text: "Shared",
                isHighlighted: true
            )
            
            CircleEntryStatusChip(
                icon: entry.type == .movie ? "film.fill" : "tv.fill",
                text: entry.type.displayName,
                isHighlighted: false
            )
            
            if entry.sourceType == .quickAdd {
                CircleEntryStatusChip(
                    icon: "bolt.fill",
                    text: "Quick Add",
                    isHighlighted: true
                )
            }
            
            if canUseCircleSocial == false {
                CircleEntryStatusChip(
                    icon: "exclamationmark.triangle.fill",
                    text: "Limited",
                    isWarning: true
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
    
    private var sharedContextNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: entry.ownerId == currentUserId ? "person.fill.checkmark" : "person.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
            
            Text(sharedContextText)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    // MARK: - Content Sections
    
    private var socialSummarySection: some View {
        DetailSectionCard(title: "Circle reactions") {
            VStack(alignment: .leading, spacing: 12) {
                if canUseCircleSocial == false {
                    unavailableSocialRow
                } else {
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
    }
    
    private var unavailableSocialRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
            
            Text(socialUnavailableMessage)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func overviewSection(_ overview: String) -> some View {
        DetailSectionCard(title: "Overview") {
            Text(overview)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
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
        if let quote = cleanOptional(entry.quote) {
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
                    value: metadataText
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
            if canUseCircleSocial == false {
                unavailableSocialRow
            } else {
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
                
                if canUseCircleSocial == false {
                    Divider()
                        .overlay(CloseCutColors.separator)
                    
                    unavailableSocialRow
                }
            }
        }
    }
    // MARK: - Social Actions

    private func loadSocialData(force: Bool = false) async {
        guard canUseCircleSocial else {
            reactions = []
            comments = []
            socialErrorMessage = nil
            return
        }

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
                entryId: entry.id,
                circleId: cleanedCircleId
            )

            async let commentsTask = socialRemoteDataSource.fetchComments(
                entryId: entry.id,
                circleId: cleanedCircleId
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
        guard canUseCircleSocial else {
            socialErrorMessage = socialUnavailableMessage
            return
        }

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
                    circleId: cleanedCircleId,
                    userId: currentUserId,
                    displayName: currentUserDisplayName,
                    type: type
                )
            }

            reactions = try await socialRemoteDataSource.fetchReactions(
                entryId: entry.id,
                circleId: cleanedCircleId
            )
        } catch {
            socialErrorMessage = "Couldn’t update reaction."

            #if DEBUG
            print("❌ Failed to update reaction:", error.localizedDescription)
            #endif
        }
    }

    private func sendComment(_ text: String) async {
        guard canUseCircleSocial else {
            socialErrorMessage = socialUnavailableMessage
            return
        }

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
                circleId: cleanedCircleId,
                userId: currentUserId,
                displayName: currentUserDisplayName,
                text: cleanedText
            )

            comments = try await socialRemoteDataSource.fetchComments(
                entryId: entry.id,
                circleId: cleanedCircleId
            )
        } catch {
            socialErrorMessage = "Couldn’t send comment."

            #if DEBUG
            print("❌ Failed to send comment:", error.localizedDescription)
            #endif
        }
    }

    private func deleteComment(_ comment: CircleComment) async {
        guard canUseCircleSocial else {
            socialErrorMessage = socialUnavailableMessage
            return
        }

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

    // MARK: - Helpers

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
}

// MARK: - Status Chip

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
