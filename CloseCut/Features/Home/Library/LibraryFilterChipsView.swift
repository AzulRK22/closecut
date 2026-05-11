//
//  LibraryFilterChipsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct LibraryFilterChipsView: View {
    let title: String
    let options: [LibraryBrowseFilter]
    @Binding var selectedFilter: LibraryBrowseFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { option in
                        Button {
                            selectedFilter = option
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: option.systemImage)
                                    .font(.caption2.weight(.semibold))

                                Text(option.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(selectedFilter == option ? .white : CloseCutColors.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(selectedFilter == option ? CloseCutColors.accent : CloseCutColors.input)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(selectedFilter == option ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct LibrarySortChipsView: View {
    let title: String
    let options: [LibrarySortOption]
    @Binding var selectedSort: LibrarySortOption

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: option.systemImage)
                                    .font(.caption2.weight(.semibold))

                                Text(option.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(selectedSort == option ? .white : CloseCutColors.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(selectedSort == option ? CloseCutColors.accent : CloseCutColors.input)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(selectedSort == option ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
