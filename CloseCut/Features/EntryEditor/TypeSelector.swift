//
//  TypeSelector.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct TypeSelector: View {
    @Binding var selectedType: EntryType

    var body: some View {
        HStack(spacing: 8) {
            ForEach(EntryType.allCases) { type in
                Button {
                    selectedType = type
                } label: {
                    Text(type.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedType == type ? .white : CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(selectedType == type ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(type.displayName)
                .accessibilityAddTraits(selectedType == type ? .isSelected : [])
            }
        }
    }
}
