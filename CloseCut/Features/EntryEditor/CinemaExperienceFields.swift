//
//  CinemaExperienceFields.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct CinemaExperienceFields: View {
    @Binding var audio: Int?
    @Binding var screen: Int?
    @Binding var comfort: Int?

    var body: some View {
        VStack(spacing: 12) {
            qualityRow(title: "Audio", value: $audio)
            qualityRow(title: "Screen", value: $screen)
            qualityRow(title: "Comfort", value: $comfort)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Cinema experience")
    }

    private func qualityRow(title: String, value: Binding<Int?>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                qualityButton("Poor", number: 1, value: value)
                qualityButton("OK", number: 3, value: value)
                qualityButton("Great", number: 5, value: value)
            }
        }
        .frame(minHeight: 44)
    }

    private func qualityButton(
        _ label: String,
        number: Int,
        value: Binding<Int?>
    ) -> some View {
        Button {
            value.wrappedValue = number
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(value.wrappedValue == number ? .white : CloseCutColors.textSecondary)
                .frame(width: 56, height: 32)
                .background(value.wrappedValue == number ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label)")
        .accessibilityAddTraits(value.wrappedValue == number ? .isSelected : [])
    }
}
