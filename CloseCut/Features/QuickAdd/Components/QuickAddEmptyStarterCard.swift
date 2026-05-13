//
//  QuickAddEmptyStarterCard.swift
//  CloseCut
//

import SwiftUI

struct QuickAddEmptyStarterCard: View {
    let suggestions: [QuickAddSuggestion]
    let action: (QuickAddSuggestion) -> Void
    let rowState: (QuickAddSuggestion) -> QuickAddRowState

    var body: some View {
        QuickAddSectionCard(
            title: "Start with a few you remember",
            subtitle: "Add past watches fast. Details can come later."
        ) {
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 28, height: 28)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text("A few titles are enough to begin.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text("CloseCut uses your history to shape your library and future picks.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                VStack(spacing: 10) {
                    ForEach(suggestions) { suggestion in
                        QuickAddResultRow(
                            title: suggestion.title,
                            metadata: suggestion.metadata,
                            state: rowState(suggestion),
                            action: {
                                action(suggestion)
                            }
                        )
                    }
                }
            }
        }
    }
}
