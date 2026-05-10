//
//  HistoryProgressModule.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct HistoryProgressModule: View {
    let currentCount: Int
    let targetCount: Int
    let onQuickAdd: () -> Void
    let onOpenQuickPick: () -> Void

    private var clampedCount: Int {
        min(currentCount, targetCount)
    }

    private var progress: Double {
        guard targetCount > 0 else { return 0 }
        return Double(clampedCount) / Double(targetCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your history is starting")
                        .font(.headline)
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Add \(targetCount) watches to make QuickPick more personal.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(CloseCutColors.input)

                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(CloseCutColors.accent)
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .frame(height: 8)

                Text("\(clampedCount) of \(targetCount) watches added")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            HStack(spacing: 10) {
                Button {
                    onQuickAdd()
                } label: {
                    Text("Add more past watches")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onOpenQuickPick()
                } label: {
                    Text("Open QuickPick")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your history is starting. \(clampedCount) of \(targetCount) watches added.")
    }
}
