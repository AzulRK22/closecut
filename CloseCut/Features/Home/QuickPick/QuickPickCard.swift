//
//  QuickPickCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct QuickPickCard: View {
    let suggestion: QuickPickSuggestion
    let isNoAlternatives: Bool
    let onRefresh: () -> Void

    private var label: String {
        suggestion.candidate.isRewatchCandidate ? "Rewatch candidate" : "Watch next"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.accentLight)

            VStack(alignment: .leading, spacing: 8) {
                Text(suggestion.candidate.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(suggestion.candidate.metadata)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Text(suggestion.reason)
                .font(.body)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("Based on your local history")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)

            if isNoAlternatives {
                Text("That is the strongest match right now.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 2)
            }

            Button {
                onRefresh()
            } label: {
                Label("Show me another", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(20)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). \(suggestion.candidate.title). \(suggestion.reason)")
    }
}
