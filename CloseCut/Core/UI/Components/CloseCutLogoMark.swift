//
//  CloseCutLogoMark.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct CloseCutLogoMark: View {
    var size: CGFloat = 72
    var showShadow: Bool = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            CloseCutColors.accent,
                            CloseCutColors.accentLight
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Image(systemName: "film.stack.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(
            color: showShadow ? CloseCutColors.accent.opacity(0.25) : .clear,
            radius: showShadow ? 18 : 0,
            x: 0,
            y: showShadow ? 10 : 0
        )
        .accessibilityHidden(true)
    }
}
