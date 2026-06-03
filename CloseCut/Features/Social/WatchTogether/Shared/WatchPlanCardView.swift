//
//  WatchPlanCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchPlanCardView: View {
    let plan: WatchPlan
    let currentUserId: String

    private var isOwner: Bool {
        plan.isOwned(by: currentUserId)
    }

    private var ownershipText: String {
        isOwner ? "Created by you" : "Invited by \(plan.displayOwnerName)"
    }

    private var metadataText: String {
        plan.media.metadataText.isEmpty
            ? plan.media.type.displayName
            : plan.media.metadataText
    }

    private var locationIcon: String {
        plan.locationType.systemImage
    }

    private var scheduleIcon: String {
        plan.hasConfirmedSchedule ? "calendar.badge.checkmark" : "calendar"
    }

    private var footerText: String {
        if plan.isCanceled {
            return "This plan was canceled."
        }

        if plan.isWatched {
            return "Watched together."
        }

        if plan.canBeConfirmed && isOwner {
            return "Ready to confirm."
        }

        if plan.isConfirmed {
            return "Plan confirmed."
        }

        if isOwner {
            return plan.confirmationRequirementText
        }

        if plan.responseType(for: currentUserId) == nil {
            return "Your response is pending."
        }

        return "Your response: \(plan.responseType(for: currentUserId)?.displayName ?? "Responded")"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WatchPlanPosterView(
                media: plan.media,
                width: 62,
                height: 92,
                cornerRadius: 13
            )

            VStack(alignment: .leading, spacing: 8) {
                topRow

                Text(plan.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                infoRow(
                    icon: scheduleIcon,
                    text: plan.scheduleText
                )

                infoRow(
                    icon: locationIcon,
                    text: plan.locationText
                )

                if let note = plan.displayNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                footerRow
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(plan.displayTitle), \(plan.status.displayName), \(plan.scheduleText), \(plan.locationText)")
    }

    private var topRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(ownershipText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.6)
                .lineLimit(1)

            Spacer()

            WatchPlanStatusPill(status: plan.status)
        }
    }

    private func infoRow(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .frame(width: 14)

            Text(text)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(1)
        }
    }

    private var footerRow: some View {
        HStack(spacing: 6) {
            WatchPlanResponseSummaryPill(plan: plan)

            Spacer()

            Text(footerText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(plan.canBeConfirmed && isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
    }
}
