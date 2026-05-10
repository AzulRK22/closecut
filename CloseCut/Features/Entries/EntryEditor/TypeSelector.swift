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
        VStack(alignment: .leading, spacing: 10) {
            Text("Type")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            HStack(spacing: 8) {
                ForEach(EntryType.allCases) { type in
                    typeButton(type)
                }
            }
        }
    }

    private func typeButton(_ type: EntryType) -> some View {
        let isSelected = selectedType == type

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedType = type
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: type == .movie ? "film.fill" : "tv.fill")
                    .font(.caption.weight(.semibold))

                Text(type.displayName)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : CloseCutColors.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(type.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
