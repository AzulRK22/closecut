//
//  ContextSelector.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct ContextSelector: View {
    @Binding var selectedContext: WatchContext

    var body: some View {
        HStack(spacing: 8) {
            contextButton(.home, icon: "house.fill")
            contextButton(.cinema, icon: "popcorn.fill")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Watch context")
    }

    private func contextButton(
        _ context: WatchContext,
        icon: String
    ) -> some View {
        let isSelected = selectedContext == context

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedContext = context
            }
        } label: {
            Label(context.displayName, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : CloseCutColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(isSelected ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? CloseCutColors.accentLight : CloseCutColors.separator, lineWidth: 0.5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(context.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
