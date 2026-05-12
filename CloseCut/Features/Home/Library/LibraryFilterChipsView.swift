//
//  LibraryFilterChipsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct LibraryFilterChipsView: View {
    let options: [LibraryBrowseFilter]
    @Binding var selectedFilter: LibraryBrowseFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedFilter = option
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: option.systemImage)
                                .font(.caption2.weight(.semibold))

                            Text(option.shortTitle)
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .foregroundStyle(selectedFilter == option ? .white : CloseCutColors.textSecondary)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(selectedFilter == option ? CloseCutColors.accent : CloseCutColors.input)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule()
                                .stroke(
                                    selectedFilter == option ? CloseCutColors.accent.opacity(0.8) : CloseCutColors.separator,
                                    lineWidth: 0.5
                                )
                        }
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

struct LibrarySortMenuButton: View {
    @Binding var selectedSort: LibrarySortOption

    var body: some View {
        Menu {
            ForEach(LibrarySortOption.allCases) { option in
                Button {
                    selectedSort = option
                } label: {
                    Label(
                        option.title,
                        systemImage: selectedSort == option ? "checkmark" : option.systemImage
                    )
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedSort.systemImage)
                    .font(.caption2.weight(.semibold))

                Text(selectedSort.title)
                    .font(.caption.weight(.semibold))

                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(CloseCutColors.textSecondary)
            .padding(.horizontal, 11)
            .frame(height: 32)
            .background(CloseCutColors.input)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sort library")
    }
}
