//
//  CloseCutShareActionCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import SwiftUI

struct CloseCutShareActionCard: View {
    let item: CloseCutShareItem
    let buttonTitle: String
    var note: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CloseCutSharePreviewCard(item: item)

            ShareLink(item: item.shareText) {
                HStack(spacing: 9) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption.weight(.bold))

                    Text(buttonTitle)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.84)

                    Spacer(minLength: 0)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(CloseCutColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if let note,
               note.trimmed.isEmpty == false {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 2)

                    Text(note)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
    }
}
