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

    var font: Font {
        switch self {
        case .inline:
            return .caption2
        case .banner:
            return .caption.weight(.semibold)
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .inline:
            return 8
        case .banner:
            return 12
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .inline:
            return 5
        case .banner:
            return 8
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .inline:
            return 6
        case .banner:
            return 10
        }
    }
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
            if let onRetry {
                Button {
                    onRetry()
                } label: {
                    badge(
                        dotColor: CloseCutColors.failed,
                        background: CloseCutColors.failedBackground,
                        text: "Tap to retry"
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Attempts to sync this item again.")
            } else {
                badge(
                    dotColor: CloseCutColors.failed,
                    background: CloseCutColors.failedBackground,
                    text: "Sync failed"
                )
            }
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
                .accessibilityHidden(true)

            Text(text)
                .font(size.font)
                .foregroundStyle(CloseCutColors.textPrimary)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}
