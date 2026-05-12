//
//  QuickAddSearchBar.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI

struct QuickAddSearchBar: View {
    @Binding var query: String
    let isSearching: Bool
    let onSubmit: () -> Void
    let onClear: () -> Void

    private var cleanedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            TextField("Search movies or series", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    guard cleanedQuery.isEmpty == false else {
                        return
                    }

                    onSubmit()
                }
                .foregroundStyle(CloseCutColors.textPrimary)

            if isSearching {
                ProgressView()
                    .scaleEffect(0.75)
            } else if cleanedQuery.isEmpty == false {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .frame(minHeight: 48)
        .padding(.horizontal, 14)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }
}
