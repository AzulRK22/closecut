//
//  WatchPlanEmptyStateView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchPlanEmptyStateView: View {
    let hasCircles: Bool
    let onCreatePlan: () -> Void
    let onCreateCircle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            icon

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                hasCircles ? onCreatePlan() : onCreateCircle()
            } label: {
                Label(buttonTitle, systemImage: hasCircles ? "plus.circle.fill" : "person.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            privacyNote
        }
        .padding(18)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var icon: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(CloseCutColors.accent.opacity(0.18))
                .frame(width: 52, height: 52)

            Image(systemName: hasCircles ? "calendar.badge.plus" : "person.2.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    private var title: String {
        hasCircles
            ? "No plans yet."
            : "Create a Circle first."
    }

    private var message: String {
        hasCircles
            ? "Turn a movie or series into an actual plan with people you trust. Pick a Circle, invite members, and let them respond."
            : "Watch Together works inside private Circles. Create or join one before planning a shared watch."
    }

    private var buttonTitle: String {
        hasCircles
            ? "Create Watch Together plan"
            : "Create a Circle"
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 1)

            Text("Plans are only visible inside the selected Circle. Your Personal Timeline and Watchlist stay private unless you choose to use them.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
