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
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 12) {
                qualityRow(
                    title: "Audio",
                    subtitle: "Sound clarity and immersion",
                    value: $audio
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                qualityRow(
                    title: "Screen",
                    subtitle: "Image quality and room setup",
                    value: $screen
                )

                Divider()
                    .overlay(CloseCutColors.separator)

                qualityRow(
                    title: "Comfort",
                    subtitle: "Seat, room, and overall experience",
                    value: $comfort
                )
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Cinema experience")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Cinema experience")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Optional ratings for memories watched at the theater.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func qualityRow(
        title: String,
        subtitle: String,
        value: Binding<Int?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if value.wrappedValue != nil {
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            value.wrappedValue = nil
                        }
                    } label: {
                        Text("Clear")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear \(title) rating")
                }
            }

            HStack(spacing: 6) {
                qualityButton("Poor", number: 1, value: value)
                qualityButton("OK", number: 3, value: value)
                qualityButton("Great", number: 5, value: value)
            }
        }
    }

    private func qualityButton(
        _ label: String,
        number: Int,
        value: Binding<Int?>
    ) -> some View {
        let isSelected = value.wrappedValue == number

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                value.wrappedValue = number
            }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : CloseCutColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) \(number) out of 5")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
