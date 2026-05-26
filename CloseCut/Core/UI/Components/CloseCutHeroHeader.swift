//
//  CloseCutHeroHeader.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct CloseCutHeroHeader: View {
    let title: String
    let subtitle: String
    var systemImage: String? = nil
    var style: Style = .plain

    enum Style {
        case plain
        case card
    }

    var body: some View {
        content
            .padding(style == .card ? 18 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: style == .card ? 24 : 0, style: .continuous))
            .overlay {
                if style == .card {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(CloseCutColors.separator, lineWidth: 0.5)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(subtitle)")
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            if let systemImage {
                icon(systemImage)
            }
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .plain:
            Color.clear

        case .card:
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.94),
                    CloseCutColors.accent.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func icon(_ systemImage: String) -> some View {
        ZStack {
            SwiftUI.Circle()
                .fill(CloseCutColors.accent.opacity(0.16))
                .frame(width: 50, height: 50)

            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
        .accessibilityHidden(true)
    }
}
