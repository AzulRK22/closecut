//
//  QuickAddPreviewAddBar.swift
//  CloseCut
//

import SwiftUI

struct QuickAddPreviewAddBar: View {
    let title: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Divider()
                .overlay(CloseCutColors.separator)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Ready to add")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("You can complete the memory later.")
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    action()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))

                        Text(title)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(CloseCutColors.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }
}
