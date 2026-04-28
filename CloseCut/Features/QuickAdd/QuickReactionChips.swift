//
//  QuickReactionChips.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI

struct QuickReactionChips: View {
    @Binding var selectedSentiment: QuickSentiment?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick reaction optional")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(QuickSentiment.allCases) { sentiment in
                        Button {
                            if selectedSentiment == sentiment {
                                selectedSentiment = nil
                            } else {
                                selectedSentiment = sentiment
                            }
                        } label: {
                            Text(sentiment.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedSentiment == sentiment ? .white : CloseCutColors.textSecondary)
                                .padding(.horizontal, 12)
                                .frame(height: 34)
                                .background(selectedSentiment == sentiment ? CloseCutColors.accent : CloseCutColors.input)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(sentiment.displayName)
                        .accessibilityAddTraits(selectedSentiment == sentiment ? .isSelected : [])
                    }
                }
            }
        }
    }
}
