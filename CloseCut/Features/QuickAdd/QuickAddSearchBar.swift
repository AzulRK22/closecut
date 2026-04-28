//
//  QuickAddSearchBar.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI

struct QuickAddSearchBar: View {
    @Binding var query: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(CloseCutColors.textTertiary)

            TextField("Search a movie or series", text: $query)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    onSubmit()
                }
                .foregroundStyle(CloseCutColors.textPrimary)

            if query.isEmpty == false {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(CloseCutColors.textTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 14)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
