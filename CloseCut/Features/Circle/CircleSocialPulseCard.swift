//
//  CircleSocialPulseCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CircleSocialPulseCard: View {
    let sharedMemoryCount: Int
    let hasCircles: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.accent.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 12) {
                pulseRow(
                    icon: "film.stack.fill",
                    title: "Shared timeline",
                    message: sharedMemoryCount > 0
                    ? "\(sharedMemoryCount) memories are already part of your Circle spaces."
                    : "Shared memories will appear inside each Circle once you choose to share from Personal."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                pulseRow(
                    icon: "heart.circle.fill",
                    title: "Lightweight reactions",
                    message: "Each person can leave one reaction and short comments on shared entries."
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                pulseRow(
                    icon: "wand.and.stars",
                    title: "Group taste signal",
                    message: "As Circles collect shared memories, CloseCut can later shape better group picks."
                )
            }
            .padding(14)
            .background(CloseCutColors.input.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var title: String {
        hasCircles ? "Social pulse" : "What happens inside a Circle"
    }

    private var message: String {
        hasCircles
        ? "Your Circle spaces stay intentionally small, private, and built around shared watch memories."
        : "Circle is not a public feed. It is a private layer for trusted people and intentional sharing."
    }

    private func pulseRow(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
