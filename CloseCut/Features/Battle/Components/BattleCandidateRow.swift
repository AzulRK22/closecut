//
//  BattleCandidateRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import SwiftUI

struct BattleCandidateRow: View {
    let candidate: BattleCandidate
    let isSelected: Bool
    var trailingStyle: TrailingStyle = .selection
    let action: () -> Void

    enum TrailingStyle {
        case selection
        case chevron
        case none
    }

    var body: some View {
        Button {
            action()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    BattleCandidatePosterView(
                        candidate: candidate,
                        width: 58,
                        height: 86,
                        cornerRadius: 13
                    )

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .background(
                                SwiftUI.Circle()
                                    .fill(CloseCutColors.backgroundPrimary)
                            )
                            .offset(x: 5, y: -5)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.displayTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(candidate.metadataText)
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        trailingView
                    }

                    Text(candidate.descriptionText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    chipRow
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(isSelected ? CloseCutColors.accent.opacity(0.10) : CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? CloseCutColors.accentLight.opacity(0.8) : CloseCutColors.separator,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(candidate.displayTitle), \(candidate.metadataText), \(isSelected ? "selected" : "not selected")")
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailingStyle {
        case .selection:
            selectionIndicator

        case .chevron:
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 4)

        case .none:
            EmptyView()
        }
    }

    private var selectionIndicator: some View {
        HStack(spacing: 5) {
            Image(systemName: isSelected ? "checkmark" : "plus")
                .font(.caption2.weight(.bold))

            Text(isSelected ? "Added" : "Add")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(isSelected ? .white : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var chipRow: some View {
        HStack(spacing: 7) {
            miniPill(
                icon: candidate.source.systemImage,
                text: candidate.source.shortDisplayName,
                isHighlighted: candidate.source != .archive
            )

            miniPill(
                icon: "sparkle",
                text: candidate.primarySignalText,
                isHighlighted: false
            )

            if candidate.isShared {
                miniPill(
                    icon: "person.2.fill",
                    text: "Shared",
                    isHighlighted: false
                )
            }
        }
    }

    private func miniPill(
        icon: String,
        text: String,
        isHighlighted: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
