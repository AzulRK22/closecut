//
//  DetailInfoRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI

struct DetailInfoRow: View {
    let label: String
    let value: String
    var systemImage: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .frame(width: 18)
                    .padding(.top, 2)
                    .accessibilityHidden(true)
            }

            Text(label)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)

            Spacer(minLength: 16)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
