//
//  CirclePrivacyCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct CirclePrivacyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 40, height: 40)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Private by design")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("CloseCut is not a public ratings app. Your Personal Timeline stays private unless you intentionally share an entry with a Circle.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                privacyPill("No public feed")
                privacyPill("No followers")
                privacyPill("No open chat")
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func privacyPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(CloseCutColors.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(CloseCutColors.input)
            .clipShape(Capsule())
    }
}
