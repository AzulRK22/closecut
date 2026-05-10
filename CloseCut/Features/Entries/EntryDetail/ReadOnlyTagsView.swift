//
//  ReadOnlyTagsView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI

struct ReadOnlyTagsView: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }
            }
            .accessibilityLabel("Tags \(tags.joined(separator: ", "))")
        }
    }
}
