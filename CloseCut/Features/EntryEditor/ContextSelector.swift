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

    }

    private func contextButton(_ context: WatchContext, icon: String) -> some View {

        Button {

            selectedContext = context

        } label: {

            Label(context.displayName, systemImage: icon)

                .font(.subheadline.weight(.semibold))

                .foregroundStyle(selectedContext == context ? .white : CloseCutColors.textSecondary)

                .frame(maxWidth: .infinity)

                .frame(height: 36)

                .background(selectedContext == context ? CloseCutColors.accent : CloseCutColors.input)

                .clipShape(Capsule())

        }

        .buttonStyle(.plain)

        .accessibilityLabel(context.displayName)

        .accessibilityAddTraits(selectedContext == context ? .isSelected : [])

    }

}
