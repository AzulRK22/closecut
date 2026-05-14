//
//  CirclePresetChip.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CirclePresetChip: View {
    let preset: CirclePreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: preset.systemImage)
                    .font(.caption.weight(.semibold))

                Text(preset.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : CloseCutColors.textSecondary)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(preset.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
