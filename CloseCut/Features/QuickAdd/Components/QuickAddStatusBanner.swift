//
//  QuickAddStatusBanner.swift
//  CloseCut
//

import SwiftUI

struct QuickAddStatusBanner: View {
    let message: String
    let systemImage: String
    let foregroundColor: Color
    var backgroundColor: Color = CloseCutColors.input

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(foregroundColor)
                .padding(.top, 1)

            Text(message)
                .font(.caption)
                .foregroundStyle(foregroundColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}
