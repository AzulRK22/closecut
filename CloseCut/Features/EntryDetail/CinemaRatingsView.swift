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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let audio {
                qualityPill(label: "Audio", value: audio)
            }

            if let screen {
                qualityPill(label: "Screen", value: screen)
            }

            if let comfort {
                qualityPill(label: "Comfort", value: comfort)
            }
        }
    }

    private func qualityPill(label: String, value: Int) -> some View {
        HStack {
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
