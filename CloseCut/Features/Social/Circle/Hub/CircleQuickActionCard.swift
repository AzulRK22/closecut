//
//  CircleQuickActionCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CircleQuickActionCard: View {
    let icon: String
    let title: String
    let message: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(isPrimary ? CloseCutColors.accent.opacity(0.18) : CloseCutColors.input)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isPrimary ? CloseCutColors.accentLight : CloseCutColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isPrimary ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .padding(.top, 14)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isPrimary ? CloseCutColors.accentLight.opacity(0.75) : CloseCutColors.separator,
                        lineWidth: isPrimary ? 1 : 0.5
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
