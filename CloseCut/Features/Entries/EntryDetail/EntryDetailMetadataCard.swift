//
//  EntryDetailMetadataCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct EntryDetailMetadataCard: View {
    let overview: String?

    var body: some View {
        if let overview = cleanOptional(overview) {
            EntryDetailSectionCard(
                title: "About this title",
                subtitle: "Metadata context from the connected movie or series.",
                systemImage: "info.circle.fill"
            ) {
                Text(overview)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
