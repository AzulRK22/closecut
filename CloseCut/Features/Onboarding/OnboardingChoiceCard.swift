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
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        message: String,
        systemImage: String,
        isPrimary: Bool,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
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
                        .fill(CloseCutColors.input)
                        .frame(width: 42, height: 42)

                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(iconColor)
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
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 12)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.card.opacity(isDisabled ? 0.55 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isPrimary ? CloseCutColors.accentLight.opacity(0.75) : CloseCutColors.separator,
                        lineWidth: isPrimary ? 1 : 0.5
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.65 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var iconColor: Color {
        if isPrimary {
            return CloseCutColors.accentLight
        }

        return CloseCutColors.textSecondary
    }
}
