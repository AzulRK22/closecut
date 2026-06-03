//
//  WatchTogetherHubSection.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchTogetherHubSection: View {
    let circleRows: [(circle: CloseCircle, membership: CircleMembership)]
    let plans: [WatchPlan]
    let currentUserId: String

    @Binding var selectedCircleId: String?

    let onCreatePlan: () -> Void
    let onCreateCircle: () -> Void
    let onOpenPlan: (WatchPlan) -> Void

    private var hasCircles: Bool {
        circleRows.isEmpty == false
    }

    private var resolvedSelectedCircleId: String? {
        if let selectedCircleId,
           circleRows.contains(where: { $0.circle.id == selectedCircleId }) {
            return selectedCircleId
        }

        return circleRows.first?.circle.id
    }

    private var displayedPlans: [WatchPlan] {
        guard let resolvedSelectedCircleId else {
            return []
        }

        return plans
            .filter { $0.circleId == resolvedSelectedCircleId }
            .filter { $0.deletedAt == nil }
    }

    private var activePlanCount: Int {
        plans
            .filter { $0.deletedAt == nil }
            .filter { $0.status != .canceled && $0.status != .watched }
            .count
    }

    private var confirmedPlanCount: Int {
        plans
            .filter { $0.deletedAt == nil }
            .filter { $0.status == .confirmed }
            .count
    }

    private var pendingResponseCount: Int {
        plans
            .filter { $0.deletedAt == nil }
            .reduce(0) { partialResult, plan in
                partialResult + plan.pendingResponseCount
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            WatchTogetherHeroCard(
                activePlanCount: activePlanCount,
                confirmedPlanCount: confirmedPlanCount,
                pendingResponseCount: pendingResponseCount,
                hasCircles: hasCircles,
                onCreatePlan: onCreatePlan,
                onCreateCircle: onCreateCircle
            )

            if hasCircles {
                WatchTogetherCirclePicker(
                    circleRows: circleRows,
                    selectedCircleId: $selectedCircleId
                )
                .onAppear {
                    ensureSelectedCircle()
                }
                .onChange(of: circleRows.map { $0.circle.id }) { _, _ in
                    ensureSelectedCircle()
                }
            }

            WatchTogetherPlanListSection(
                plans: displayedPlans,
                currentUserId: currentUserId,
                hasCircles: hasCircles,
                onCreatePlan: onCreatePlan,
                onCreateCircle: onCreateCircle,
                onOpenPlan: onOpenPlan
            )
        }
    }

    private func ensureSelectedCircle() {
        guard selectedCircleId == nil ||
              circleRows.contains(where: { $0.circle.id == selectedCircleId }) == false else {
            return
        }

        selectedCircleId = circleRows.first?.circle.id
    }
}
