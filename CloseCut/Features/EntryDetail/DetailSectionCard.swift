//
//  DetailSectionCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 26/04/26.
//

import SwiftUI

struct DetailSectionCard<Content: View>: View {
    let title: String
    let content: () -> Content

    init(
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .tracking(0.8)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
