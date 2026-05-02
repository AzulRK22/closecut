//
//  CircleActivityRowView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleActivityRowView: View {
    let activity: CircleActivity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.input)
                    .frame(width: 34, height: 34)

                Image(systemName: activity.type.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.message)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(activity.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.type.displayName), \(activity.message)")
    }
}
