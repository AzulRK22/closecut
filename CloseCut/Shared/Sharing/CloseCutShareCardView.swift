//
//  CloseCutShareCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import SwiftUI

struct CloseCutShareCardView: View {
    let item: CloseCutShareItem

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            VStack(alignment: .leading, spacing: 10) {
                Text(item.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                if item.subtitle.isEmpty == false {
                    Text(item.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if item.body.isEmpty == false {
                Text(item.body)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(4)
                    .lineLimit(7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let callToAction = item.callToAction {
                callToActionPill(callToAction)
            }

            Spacer(minLength: 0)

            footer
        }
        .padding(22)
        .frame(width: 340, height: 430, alignment: .leading)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.34), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 24, x: 0, y: 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.kind.displayName). \(item.title). \(item.subtitle)")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 11) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent.opacity(0.22))
                    .frame(width: 42, height: 42)

                Image(systemName: item.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.kind.displayName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .tracking(0.8)
                    .textCase(.uppercase)

                Text("CloseCut")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(item.footer.isEmpty ? "Shared from CloseCut." : item.footer)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Text("Private by default")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(CloseCutColors.accent)
                .clipShape(Capsule())
        }
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.backgroundElevated
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.32),
                    CloseCutColors.accent.opacity(0.08),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 260
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.20),
                    .clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 240
            )
        }
    }

    private func callToActionPill(
        _ text: String
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(CloseCutColors.accentLight)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.28), lineWidth: 0.5)
        }
    }
}

#Preview {
    CloseCutShareCardView(
        item: CloseCutShareTextBuilder.appInvite(
            displayName: "Azul"
        )
    )
    .padding()
    .background(CloseCutColors.backgroundPrimary)
    .preferredColorScheme(.dark)
}
