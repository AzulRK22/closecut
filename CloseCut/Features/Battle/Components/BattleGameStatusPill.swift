//
//  BattleGameStatusPill.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/06/26.
//

import SwiftUI

struct BattleGameStatusPill: View {
    let icon: String
    let text: String
    var isHighlighted: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))

            Text(text)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? CloseCutColors.accentLight : CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(CloseCutColors.input.opacity(0.95))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(
                    isHighlighted ? CloseCutColors.accentLight.opacity(0.55) : CloseCutColors.separator,
                    lineWidth: 0.5
                )
        }
    }
}
