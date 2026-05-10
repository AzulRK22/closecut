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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let systemImage {
                icon(systemImage)
            }

            VStack(alignment: .leading, spacing: 6) {
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }

    private func icon(_ systemImage: String) -> some View {
        ZStack {
            SwiftUI.Circle()
                .fill(CloseCutColors.card)
                .frame(width: 56, height: 56)

            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
        .accessibilityHidden(true)
    }
}
