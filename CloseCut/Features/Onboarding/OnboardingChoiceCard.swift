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
    let badgeText: String?
    let isPrimary: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        message: String,
        systemImage: String,
        badgeText: String? = nil,
        isPrimary: Bool,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.badgeText = badgeText
        self.isPrimary = isPrimary
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            guard isDisabled == false else {
                return
            }

            action()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(iconBackground)
                        .frame(width: 46, height: 46)

                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let badgeText {
                            Text(badgeText)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isPrimary ? .white : CloseCutColors.accentLight)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(isPrimary ? CloseCutColors.accent : CloseCutColors.input)
                                .clipShape(Capsule())
                        }
                    }

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
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isPrimary ? CloseCutColors.accentLight.opacity(0.8) : CloseCutColors.separator,
                        lineWidth: isPrimary ? 1 : 0.5
                    )
            }
            .shadow(
                color: isPrimary ? CloseCutColors.accent.opacity(0.14) : .clear,
                radius: 14,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var cardBackground: Color {
        if isDisabled {
            return CloseCutColors.card.opacity(0.55)
        }

        return isPrimary ? CloseCutColors.card : CloseCutColors.card.opacity(0.88)
    }

    private var iconBackground: Color {
        isPrimary ? CloseCutColors.accent.opacity(0.18) : CloseCutColors.input
    }

    private var iconColor: Color {
        isPrimary ? CloseCutColors.accentLight : CloseCutColors.textSecondary
    }
}
