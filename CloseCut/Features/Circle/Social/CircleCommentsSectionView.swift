//
//  CircleCommentsSectionView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/05/26.
//

import SwiftUI

struct CircleCommentsSectionView: View {
    let comments: [CircleComment]
    let currentUserId: String
    let isLoading: Bool
    let isSending: Bool
    let isDeletingCommentId: String?
    let onSend: (String) -> Void
    let onDelete: (CircleComment) -> Void

    @State private var draftText = ""

    private let maxLength = 240

    private var trimmedDraft: String {
        draftText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool {
        trimmedDraft.isEmpty == false &&
        trimmedDraft.count <= maxLength &&
        isSending == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if isLoading && comments.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()

                    Text("Loading comments…")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)

                    Spacer()
                }
            }

            if comments.isEmpty && isLoading == false {
                Text("No comments yet. Keep it short and meaningful.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    ForEach(comments) { comment in
                        commentRow(comment)

                        if comment.id != comments.last?.id {
                            Divider()
                                .overlay(CloseCutColors.separator)
                        }
                    }
                }
            }

            Divider()
                .overlay(CloseCutColors.separator)

            VStack(alignment: .leading, spacing: 8) {
                TextField("Add a short comment…", text: $draftText, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .onChange(of: draftText) { _, newValue in
                        if newValue.count > maxLength {
                            draftText = String(newValue.prefix(maxLength))
                        }
                    }

                HStack {
                    Text("\(trimmedDraft.count)/\(maxLength)")
                        .font(.caption2)
                        .foregroundStyle(trimmedDraft.count > maxLength ? CloseCutColors.failed : CloseCutColors.textTertiary)

                    Spacer()

                    Button {
                        let textToSend = trimmedDraft
                        guard textToSend.isEmpty == false else { return }

                        onSend(textToSend)
                        draftText = ""
                    } label: {
                        HStack(spacing: 6) {
                            if isSending {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }

                            Text(isSending ? "Sending…" : "Send")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(canSend ? .white : CloseCutColors.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(canSend ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(canSend == false)
                }
            }
        }
    }

    private func commentRow(_ comment: CircleComment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(comment.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text("•")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Spacer()

                if comment.userId == currentUserId {
                    Button(role: .destructive) {
                        onDelete(comment)
                    } label: {
                        if isDeletingCommentId == comment.id {
                            ProgressView()
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: "trash")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(CloseCutColors.failed)
                    .disabled(isDeletingCommentId != nil)
                    .accessibilityLabel("Delete comment")
                }
            }

            Text(comment.text)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
