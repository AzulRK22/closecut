//
//  IntensitySelector.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct IntensitySelector: View {
    @Binding var value: Int
    var isEditable: Bool = true

    private var clampedValue: Int {
        min(max(value, EntryValidation.minIntensity), EntryValidation.maxIntensity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ForEach(EntryValidation.minIntensity...EntryValidation.maxIntensity, id: \.self) { number in
                    intensityButton(number)
                }
            }

            HStack {
                Text("Low")
                Spacer()
                Text(intensityLabel(for: clampedValue))
                Spacer()
                Text("Overwhelming")
            }
            .font(.caption2)
            .foregroundStyle(CloseCutColors.textTertiary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Intensity \(clampedValue) out of 5")
    }

    private func intensityButton(_ number: Int) -> some View {
        let isFilled = number <= clampedValue
        let isSelected = number == clampedValue

        return Button {
            guard isEditable else {
                return
            }

            withAnimation(.easeInOut(duration: 0.16)) {
                value = number
            }
        } label: {
            ZStack {
                SwiftUI.Circle()
                    .fill(isFilled ? CloseCutColors.accent : CloseCutColors.input)

                if isSelected {
                    SwiftUI.Circle()
                        .stroke(CloseCutColors.accentLight, lineWidth: 1.5)
                        .padding(2)
                }
            }
            .frame(width: 24, height: 24)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .accessibilityLabel("Intensity \(number) of 5")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func intensityLabel(for value: Int) -> String {
        switch value {
        case 1:
            return "Light"
        case 2:
            return "Soft"
        case 3:
            return "Memorable"
        case 4:
            return "Strong"
        case 5:
            return "Intense"
        default:
            return "Not set"
        }
    }
}
