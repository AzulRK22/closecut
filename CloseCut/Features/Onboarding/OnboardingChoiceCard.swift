//
//  OnboardingChoiceCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI

struct OnboardingChoiceCard: View {
    let title: String
    let message: String
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(isPrimary ? CloseCutColors.accentLight : CloseCutColors.textSecondary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isPrimary ? CloseCutColors.accent : CloseCutColors.separator, lineWidth: isPrimary ? 1 : 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
