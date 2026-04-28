//
//  QuickAddResultRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI

enum QuickAddRowState {
    case normal
    case added
    case duplicate
}

struct QuickAddResultRow: View {
    let title: String
    let metadata: String
    let state: QuickAddRowState
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Text(metadata)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Spacer()

                statusIcon
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 58)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(metadata), \(accessibilityState)")
    }

    private var statusIcon: some View {
        switch state {
        case .normal:
            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundStyle(CloseCutColors.accentLight)

        case .added:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(CloseCutColors.synced)

        case .duplicate:
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundStyle(CloseCutColors.textTertiary)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:
            return CloseCutColors.separator
        case .added:
            return CloseCutColors.synced.opacity(0.8)
        case .duplicate:
            return CloseCutColors.subtleBorder
        }
    }

    private var accessibilityState: String {
        switch state {
        case .normal:
            return "not added"
        case .added:
            return "added"
        case .duplicate:
            return "already in your history"
        }
    }
}
