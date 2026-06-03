//
//  CircleHubSummaryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CircleHubSummaryCard: View {
    let circleCount: Int
    let ownedCount: Int
    let joinedCount: Int
    let sharedMemoryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Circle hub")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("A quick pulse of your private social spaces.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                Spacer()

                Image(systemName: "waveform.path.ecg")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 34, height: 34)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())
            }

            HStack(spacing: 10) {
                statBlock(
                    value: "\(circleCount)",
                    label: circleCount == 1 ? "Circle" : "Circles",
                    icon: "circle.grid.2x2.fill"
                )

                statBlock(
                    value: "\(sharedMemoryCount)",
                    label: "Shared",
                    icon: "film.stack.fill"
                )
            }

            HStack(spacing: 10) {
                statBlock(
                    value: "\(ownedCount)",
                    label: "Owned",
                    icon: "crown.fill"
                )

                statBlock(
                    value: "\(joinedCount)",
                    label: "Joined",
                    icon: "person.badge.plus"
                )
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

    private func statBlock(
        value: String,
        label: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
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
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
