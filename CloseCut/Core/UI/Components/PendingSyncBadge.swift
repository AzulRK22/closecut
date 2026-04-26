//
//  PendingSyncBadge.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum PendingSyncBadgeSize {
    case inline
    case banner
}

struct PendingSyncBadge: View {
    let status: SyncStatus
    var size: PendingSyncBadgeSize = .inline
    var onRetry: (() -> Void)? = nil

    var body: some View {
        switch status {
        case .synced:
            EmptyView()

        case .pending:
            badge(
                dotColor: CloseCutColors.pending,
                background: CloseCutColors.pendingBackground,
                text: "Pending sync"
            )

        case .failed:
            Button {
                onRetry?()
            } label: {
                badge(
                    dotColor: CloseCutColors.failed,
                    background: CloseCutColors.failedBackground,
                    text: onRetry == nil ? "Sync failed" : "Tap to retry"
                )
            }
            .buttonStyle(.plain)
            .disabled(onRetry == nil)
        }
    }

    private func badge(
        dotColor: Color,
        background: Color,
        text: String
    ) -> some View {
        HStack(spacing: 6) {
            SwiftUI.Circle()
                .fill(dotColor)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
