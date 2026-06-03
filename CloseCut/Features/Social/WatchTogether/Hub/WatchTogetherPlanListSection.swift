//
//  WatchTogetherPlanListSection.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchTogetherPlanListSection: View {
    let plans: [WatchPlan]
    let currentUserId: String
    let hasCircles: Bool
    let onCreatePlan: () -> Void
    let onCreateCircle: () -> Void
    let onOpenPlan: (WatchPlan) -> Void

    private var activePlans: [WatchPlan] {
        plans
            .filter { $0.deletedAt == nil }
            .filter { $0.status != .canceled && $0.status != .watched }
            .sorted { first, second in
                let firstDate = first.confirmedStartAt ?? first.proposedStartAt ?? first.updatedAt
                let secondDate = second.confirmedStartAt ?? second.proposedStartAt ?? second.updatedAt

                return firstDate < secondDate
            }
    }

    private var completedPlans: [WatchPlan] {
        plans
            .filter { $0.deletedAt == nil }
            .filter { $0.status == .watched || $0.status == .canceled }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            WatchTogetherSectionHeader(
                title: "Watch Together",
                subtitle: sectionSubtitle,
                trailing: activePlans.isEmpty ? nil : "\(activePlans.count)"
            )

            if activePlans.isEmpty {
                WatchPlanEmptyStateView(
                    hasCircles: hasCircles,
                    onCreatePlan: onCreatePlan,
                    onCreateCircle: onCreateCircle
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(activePlans) { plan in
                        Button {
                            onOpenPlan(plan)
                        } label: {
                            WatchPlanCardView(
                                plan: plan,
                                currentUserId: currentUserId
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if completedPlans.isEmpty == false {
                completedPreview
            }
        }
    }

    private var sectionSubtitle: String {
        if hasCircles == false {
            return "Create a Circle before making shared plans."
        }

        if activePlans.isEmpty {
            return "No active plans yet. Start with one title and one Circle."
        }

        return "Active plans, responses, and confirmed watches."
    }

    private var completedPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .overlay(CloseCutColors.separator)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Recent closed plans")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Watched or canceled plans stay out of the main list.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                Spacer()

                Text("\(completedPlans.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            ForEach(Array(completedPlans.prefix(2))) { plan in
                Button {
                    onOpenPlan(plan)
                } label: {
                    compactCompletedRow(plan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(CloseCutColors.card.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func compactCompletedRow(
        _ plan: WatchPlan
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: plan.status.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(plan.status == .canceled ? CloseCutColors.failed : CloseCutColors.textTertiary)
                .frame(width: 28, height: 28)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(plan.displayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text("\(plan.status.displayName) • \(plan.displayCircleName)")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(10)
        .background(CloseCutColors.input.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
