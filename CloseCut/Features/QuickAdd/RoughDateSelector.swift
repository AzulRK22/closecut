//
//  RoughDateSelector.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI

struct RoughDateSelector: View {
    @Binding var selectedDate: WatchedDateApprox

    private var options: [WatchedDateApprox] {
        [
            .recently,
            .thisYear,
            .longTimeAgo,
            .unknown
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rough date optional")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.displayLabel) { option in
                        Button {
                            selectedDate = option
                        } label: {
                            Text(option.displayLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(selectedDate.displayLabel == option.displayLabel ? .white : CloseCutColors.textSecondary)
                                .padding(.horizontal, 12)
                                .frame(height: 34)
                                .background(selectedDate.displayLabel == option.displayLabel ? CloseCutColors.accent : CloseCutColors.input)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.displayLabel)
                        .accessibilityAddTraits(selectedDate.displayLabel == option.displayLabel ? .isSelected : [])
                    }
                }
            }
        }
    }
}
