//
//  CloseCutSharePreviewCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import SwiftUI

struct CloseCutSharePreviewCard: View {
    let item: CloseCutShareItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if item.subtitle.isEmpty == false {
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if item.body.isEmpty == false {
                Text(item.body)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let callToAction = item.callToAction,
               callToAction.isEmpty == false {
                Text(callToAction)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .fixedSize(horizontal: false, vertical: true)
            }

            footer
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent.opacity(0.18))
                    .frame(width: 38, height: 38)

                Image(systemName: item.kind.systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.kind.displayName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .tracking(0.8)
                    .textCase(.uppercase)

                Text("Preview before sharing")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()
        }
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text(item.footer)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(.top, 2)
    }

    private var cardBackground: some ShapeStyle {
        LinearGradient(
            colors: [
                CloseCutColors.card,
                CloseCutColors.card.opacity(0.96),
                CloseCutColors.accent.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
