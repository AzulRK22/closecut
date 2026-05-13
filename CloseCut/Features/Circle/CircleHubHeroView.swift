//
//  CircleHubHeroView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CircleHubHeroView: View {
    let circleCount: Int
    let sharedMemoryCount: Int
    let onCreate: () -> Void
    let onJoin: () -> Void

    private var hasCircles: Bool {
        circleCount > 0
    }

    private var headline: String {
        hasCircles
        ? "Your private spaces."
        : "Share with the people who matter."
    }

    private var message: String {
        hasCircles
        ? "Keep each group separate: friends, family, partner, movie club. Your Personal library stays private unless you choose to share."
        : "Create trusted spaces for the movies and series you actually want to talk about. No public feed. No followers. Just your people."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                heroIcon

                VStack(alignment: .leading, spacing: 7) {
                    Text("CIRCLE")
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(CloseCutColors.accentLight)

                    Text(headline)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            if hasCircles {
                HStack(spacing: 8) {
                    heroPill(
                        icon: "circle.grid.2x2.fill",
                        text: circleCount == 1 ? "1 Circle" : "\(circleCount) Circles"
                    )

                    heroPill(
                        icon: "film.stack.fill",
                        text: sharedMemoryCount == 1 ? "1 shared" : "\(sharedMemoryCount) shared"
                    )

                    heroPill(
                        icon: "lock.fill",
                        text: "Private"
                    )
                }
            }

            HStack(spacing: 10) {
                Button {
                    onCreate()
                } label: {
                    Label("Create", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onJoin()
                } label: {
                    Label("Join", systemImage: "ticket.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
    }

    private var heroIcon: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(CloseCutColors.accent.opacity(0.18))
                .frame(width: 52, height: 52)

            Image(systemName: "person.2.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    private func heroPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
