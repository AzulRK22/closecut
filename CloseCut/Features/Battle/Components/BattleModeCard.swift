//
//  BattleModeCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 14/05/26.
//

import SwiftUI

struct BattleModeCard: View {
    let mode: BattleGameMode
    let isPrimary: Bool
    let isEnabled: Bool
    let action: () -> Void

    private var effectiveBadgeText: String {
        if mode.isAvailableNow == false {
            return mode.badgeText
        }

        return isEnabled ? mode.badgeText : "Need 2 titles"
    }

    var body: some View {
        Button {
            guard isEnabled else {
                return
            }

            action()
        } label: {
            HStack(alignment: .top, spacing: 13) {
                iconBlock

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(mode.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(isEnabled ? CloseCutColors.textPrimary : CloseCutColors.textTertiary)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(effectiveBadgeText)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(isEnabled ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }

                    Text(mode.subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isEnabled ? CloseCutColors.textTertiary : CloseCutColors.inactive)
                    .padding(.top, 17)
            }
            .padding(isPrimary ? 14 : 0)
            .background(isPrimary ? CloseCutColors.accent.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
            .opacity(isEnabled ? 1 : 0.65)
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mode.title). \(effectiveBadgeText). \(mode.subtitle)")
    }

    private var iconBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(isPrimary && isEnabled ? CloseCutColors.accent.opacity(0.22) : CloseCutColors.input)
                .frame(width: 46, height: 46)

            Image(systemName: mode.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isEnabled ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        }
    }
}
