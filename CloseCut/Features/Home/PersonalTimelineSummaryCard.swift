//
//  PersonalTimelineSummaryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/05/26.
//

import SwiftUI

struct PersonalTimelineSummaryCard: View {
    let entries: [Entry]
    let onQuickAdd: () -> Void
    let onCreateEntry: () -> Void

    private var totalCount: Int {
        entries.count
    }

    private var sharedCount: Int {
        entries.filter {
            $0.visibility == .circle && $0.sharedCircleIds.isEmpty == false
        }.count
    }

    private var quickAddCount: Int {
        entries.filter { $0.sourceType == .quickAdd }.count
    }

    private var privateCount: Int {
        max(totalCount - sharedCount, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            HStack(spacing: 10) {
                statPill(
                    value: "\(totalCount)",
                    label: totalCount == 1 ? "memory" : "memories",
                    icon: "film.stack"
                )

                statPill(
                    value: "\(privateCount)",
                    label: "private",
                    icon: "lock.fill"
                )

                statPill(
                    value: "\(sharedCount)",
                    label: "shared",
                    icon: "person.2.fill"
                )
            }

            HStack(spacing: 10) {
                Button {
                    onQuickAdd()
                } label: {
                    Label("Quick Add", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onCreateEntry()
                } label: {
                    Label("New Entry", systemImage: "plus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("Private by default. Share only the memories that belong in a Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Your archive")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summaryText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 34, height: 34)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())
        }
    }

    private var summaryText: String {
        if totalCount == 0 {
            return "Start building your private taste history."
        }

        if quickAddCount > 0 {
            return "\(quickAddCount) quick adds are ready to become richer memories."
        }

        if sharedCount > 0 {
            return "\(sharedCount) memories are shared with trusted Circles."
        }

        return "Your personal watch history is taking shape."
    }

    private func statPill(
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
