//
//  WatchPlanResponseSummaryPill.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchPlanResponseSummaryPill: View {
    let plan: WatchPlan

    private var icon: String {
        if plan.acceptedCountExcludingOwner > 0 {
            return "checkmark.circle.fill"
        }

        if plan.pendingResponseCount > 0 {
            return "clock.fill"
        }

        return "person.2.fill"
    }

    private var text: String {
        if plan.acceptedCountExcludingOwner > 0 {
            return plan.acceptedCountExcludingOwner == 1
                ? "1 yes"
                : "\(plan.acceptedCountExcludingOwner) yes"
        }

        if plan.pendingResponseCount > 0 {
            return plan.pendingResponseCount == 1
                ? "1 waiting"
                : "\(plan.pendingResponseCount) waiting"
        }

        return "No responses"
    }

    var body: some View {
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
}
