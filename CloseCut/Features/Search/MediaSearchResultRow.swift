//
//  MediaSearchResultRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 06/05/26.
//

import SwiftUI

struct MediaSearchResultRow: View {
    let result: TMDBMediaSearchResult
    var isSelected: Bool = false

    private var overviewText: String? {
        cleanOptional(result.overview)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            MediaPosterView(
                posterPath: result.posterPath,
                mediaType: result.mediaType,
                width: 58,
                height: 86,
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(result.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .accessibilityHidden(true)
                    }
                }

                Text(result.subtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)

                if let overviewText {
                    Text(overviewText)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isSelected ? CloseCutColors.accentLight : CloseCutColors.separator,
                    lineWidth: isSelected ? 1 : 0.5
                )
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var accessibilityText: String {
        if isSelected {
            return "\(result.title), \(result.subtitle), selected"
        }

        return "\(result.title), \(result.subtitle)"
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
