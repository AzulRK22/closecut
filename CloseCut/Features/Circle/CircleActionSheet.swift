//
//  CircleActionSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CircleActionSheet: View {
    let onCreate: () -> Void
    let onJoin: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 14) {
                    Text("Add a Circle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Create your own private space or join one with an invite code.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        onCreate()
                    } label: {
                        actionRow(
                            icon: "plus.circle.fill",
                            title: "Create Circle",
                            message: "Start a private space and invite trusted people."
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onJoin()
                    } label: {
                        actionRow(
                            icon: "ticket.fill",
                            title: "Join with invite code",
                            message: "Enter a code from someone you trust."
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Circle")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func actionRow(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
