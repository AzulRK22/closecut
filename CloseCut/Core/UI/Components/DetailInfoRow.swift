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

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)

            Spacer(minLength: 16)

            Text(value)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 28)
    }
}
