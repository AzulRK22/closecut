//
//  CinemaRatingsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI

struct CinemaRatingsView: View {
    let audio: Int?
    let screen: Int?
    let comfort: Int?

    private var hasRatings: Bool {
        audio != nil || screen != nil || comfort != nil
    }

    var body: some View {
        if hasRatings {
            VStack(alignment: .leading, spacing: 10) {
                if let audio {
                    qualityPill(
                        icon: "speaker.wave.2.fill",
                        label: "Audio",
                        value: audio
                    )
                }

                if let screen {
                    qualityPill(
                        icon: "rectangle.on.rectangle.fill",
                        label: "Screen",
                        value: screen
                    )
                }

                if let comfort {
                    qualityPill(
                        icon: "chair.lounge.fill",
                        label: "Comfort",
                        value: comfort
                    )
                }
            }
        }
    }

    private func qualityPill(
        icon: String,
        label: String,
        value: Int
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .frame(width: 18)

            Text(label)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)

            Spacer()

            Text(qualityLabel(for: value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(CloseCutColors.input)
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(qualityLabel(for: value))")
    }

    private func qualityLabel(for value: Int) -> String {
        switch value {
        case 1...2:
            return "Poor"
        case 3...4:
            return "OK"
        case 5:
            return "Great"
        default:
            return "Not set"
        }
    }
}
