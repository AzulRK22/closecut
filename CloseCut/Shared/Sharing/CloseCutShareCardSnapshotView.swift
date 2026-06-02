//
//  CloseCutShareCardSnapshotView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import SwiftUI

struct CloseCutShareCardSnapshotView: View {
    let item: CloseCutShareItem

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.backgroundPrimary,
                    CloseCutColors.backgroundElevated,
                    CloseCutColors.accent.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            CloseCutShareCardView(item: item)
                .padding(24)
        }
        .frame(width: 390, height: 520)
    }
}

#Preview {
    CloseCutShareCardSnapshotView(
        item: CloseCutShareTextBuilder.battleWinner(
            winnerTitle: "Dune: Part Two",
            metadataText: "2024 • Movie • 8.1 TMDB",
            optionCount: 4,
            sourceText: "Battle"
        )
    )
    .preferredColorScheme(.dark)
}
