//
//  CirclePrivacyCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct CirclePrivacyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("Private by design")
                    .font(.headline)
                    .foregroundStyle(CloseCutColors.textPrimary)
            } icon: {
                Image(systemName: "lock.fill")
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            Text("CloseCut is not a public ratings app. Entries stay private unless you choose to share them with your Circle.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                privacyPill("No public feed")
                privacyPill("No followers")
                privacyPill("No chat")
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func privacyPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(CloseCutColors.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(CloseCutColors.input)
            .clipShape(Capsule())
    }
}
