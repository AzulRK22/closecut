//
//  CircleEmptyStateView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CircleEmptyStateView: View {
    let onCreateCircle: () -> Void
    let onJoinCircle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            examplesRow

            VStack(alignment: .leading, spacing: 8) {
                Text("Create one space to start.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Start small with one trusted group. You can make separate Circles later for different people.")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 10) {
                Button {
                    onCreateCircle()
                } label: {
                    Label("Create your first Circle", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onJoinCircle()
                } label: {
                    Label("I have an invite code", systemImage: "ticket.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            privacyLine
        }
        .padding(18)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var examplesRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Good first Circles")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    examplePill(
                        icon: "person.2.fill",
                        title: "Friends"
                    )

                    examplePill(
                        icon: "heart.fill",
                        title: "Partner"
                    )

                    examplePill(
                        icon: "house.fill",
                        title: "Family"
                    )

                    examplePill(
                        icon: "popcorn.fill",
                        title: "Movie Club"
                    )
                }
            }
        }
    }

    private func examplePill(
        icon: String,
        title: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    private var privacyLine: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 1)

            Text("Nothing from Personal is shared automatically.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 2)
    }
}
