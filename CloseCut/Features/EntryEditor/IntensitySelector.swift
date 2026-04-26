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

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(1...5, id: \.self) { number in
                    Button {
                        guard isEditable else { return }
                        value = number
                    } label: {
                        SwiftUI.Circle()
                            .fill(number <= value ? CloseCutColors.accent : CloseCutColors.input)
                            .overlay {
                                SwiftUI.Circle()
                                    .stroke(CloseCutColors.subtleBorder, lineWidth: number <= value ? 0 : 0.5)
                            }
                            .frame(width: 24, height: 24)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEditable)
                    .accessibilityLabel("Intensity \(number) of 5")
                    .accessibilityAddTraits(value == number ? .isSelected : [])
                }
            }

            HStack {
                Text("Low")
                Spacer()
                Text("Overwhelming")
            }
            .font(.caption2)
            .foregroundStyle(CloseCutColors.textTertiary)
        }
    }
}
