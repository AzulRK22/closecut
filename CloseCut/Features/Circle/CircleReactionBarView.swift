//
//  CircleReactionBarView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/05/26.
//

import SwiftUI

struct CircleReactionBarView: View {
    let reactions: [CircleReaction]
    let currentUserId: String
    let isUpdating: Bool
    let onSelect: (CircleReactionType) -> Void

    private var currentUserReaction: CircleReaction? {
        reactions.first { $0.userId == currentUserId }
    }

    private func count(for type: CircleReactionType) -> Int {
        reactions.filter { $0.type == type }.count
    }

    private func isSelected(_ type: CircleReactionType) -> Bool {
        currentUserReaction?.type == type
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 92), spacing: 8)
                ],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(CircleReactionType.allCases) { type in
                    Button {
                        onSelect(type)
                    } label: {
                        reactionChip(type)
                    }
                    .buttonStyle(.plain)
                    .disabled(isUpdating)
                    .accessibilityLabel(type.accessibilityLabel)
                }
            }

            if let currentUserReaction {
                Text("Your reaction: \(currentUserReaction.type.emoji) \(currentUserReaction.type.title)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
            } else {
                Text("React once. Changing your reaction replaces the previous one.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
    }

    private func reactionChip(_ type: CircleReactionType) -> some View {
        let selected = isSelected(type)
        let reactionCount = count(for: type)

        return HStack(spacing: 6) {
            Text(type.emoji)
                .font(.body)

            Text(type.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            if reactionCount > 0 {
                Text("\(reactionCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(selected ? .white : CloseCutColors.textTertiary)
            }
        }
        .foregroundStyle(selected ? .white : CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(selected ? CloseCutColors.accent : CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(selected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
