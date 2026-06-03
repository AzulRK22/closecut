//
//  WatchTogetherHeroCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchTogetherHeroCard: View {
    let activePlanCount: Int
    let confirmedPlanCount: Int
    let pendingResponseCount: Int
    let hasCircles: Bool
    let onCreatePlan: () -> Void
    let onCreateCircle: () -> Void

    private var title: String {
        hasCircles
            ? "Plan what to watch together."
            : "Start with a Circle."
    }

    private var message: String {
        hasCircles
            ? "Turn a title into a real plan: choose the Circle, propose when and where, then let people respond."
            : "Watch Together lives inside private Circles. Create or join one before planning with others."
    }

    private var primaryButtonTitle: String {
        hasCircles ? "New plan" : "Create Circle"
    }

    private var primaryButtonIcon: String {
        hasCircles ? "calendar.badge.plus" : "person.2.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                heroIcon

                VStack(alignment: .leading, spacing: 7) {
                    Text("WATCH TOGETHER")
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(CloseCutColors.accentLight)

                    Text(title)
                        .font(.title3.weight(.semibold))
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
                    summaryPill(
                        icon: "calendar",
                        text: activePlanCount == 1 ? "1 active" : "\(activePlanCount) active"
                    )

                    summaryPill(
                        icon: "checkmark.seal.fill",
                        text: confirmedPlanCount == 1 ? "1 confirmed" : "\(confirmedPlanCount) confirmed"
                    )

                    summaryPill(
                        icon: "clock.fill",
                        text: pendingResponseCount == 1 ? "1 waiting" : "\(pendingResponseCount) waiting"
                    )
                }
            }

            Button {
                hasCircles ? onCreatePlan() : onCreateCircle()
            } label: {
                Label(primaryButtonTitle, systemImage: primaryButtonIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            privacyLine
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    CloseCutColors.card,
                    CloseCutColors.card.opacity(0.88),
                    CloseCutColors.accent.opacity(0.1)
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

            Image(systemName: "calendar.badge.clock")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    private func summaryPill(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }

    private var privacyLine: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 1)

            Text("Plans are private to the selected Circle. Nothing from Personal, Watchlist, Battle, or Discover is shared automatically.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
