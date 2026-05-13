//
//  OnboardingHeroCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct OnboardingHeroCard: View {
    let title: String
    let message: String
    let systemImage: String
    let isLogo: Bool
    let pills: [OnboardingHeroPill]

    var body: some View {
        VStack(spacing: 24) {
            visual

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if pills.isEmpty == false {
                pillWrap
            }
        }
        .padding(.horizontal, 24)
    }

    private var visual: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(CloseCutColors.card)
                .frame(width: 214, height: 214)
                .overlay {
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(CloseCutColors.separator, lineWidth: 0.5)
                }

            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.22),
                    CloseCutColors.card.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 214, height: 214)
            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))

            if isLogo {
                CloseCutLogoMark(size: 108)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 66, weight: .regular))
                    .foregroundStyle(CloseCutColors.accentLight)
            }
        }
        .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 10)
    }

    private var pillWrap: some View {
        FlexiblePillLayout(
            pills: pills
        )
    }
}

struct OnboardingHeroPill: Identifiable, Equatable {
    let id = UUID()
    let icon: String
    let text: String
}

private struct FlexiblePillLayout: View {
    let pills: [OnboardingHeroPill]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Array(pills.prefix(2))) { pill in
                    OnboardingFeaturePill(
                        icon: pill.icon,
                        text: pill.text
                    )
                }
            }

            if pills.count > 2 {
                HStack(spacing: 8) {
                    ForEach(Array(pills.dropFirst(2).prefix(2))) { pill in
                        OnboardingFeaturePill(
                            icon: pill.icon,
                            text: pill.text
                        )
                    }
                }
            }
        }
    }
}
