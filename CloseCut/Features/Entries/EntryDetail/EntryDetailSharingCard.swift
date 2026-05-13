//
//  EntryDetailSharingCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct EntryDetailSharingCard: View {
    let entry: Entry
    let sharingText: String
    let syncText: String
    let shouldShowSyncStatus: Bool
    let onEditSharing: () -> Void

    private var isShared: Bool {
        entry.visibility == .circle && entry.sharedCircleIds.isEmpty == false
    }

    var body: some View {
        EntryDetailSectionCard(
            title: "Visibility",
            subtitle: "Personal memories stay private unless you choose to share.",
            systemImage: isShared ? "person.2.fill" : "lock.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: isShared ? "person.2.fill" : "lock.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isShared ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                        .frame(width: 34, height: 34)
                        .background(CloseCutColors.input)
                        .clipShape(SwiftUI.Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(sharingText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)

                        Text(isShared ? "Selected Circle members can see this in their shared timeline." : "Only you can see this in your Personal library.")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(12)
                .background(CloseCutColors.input.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if shouldShowSyncStatus {
                    HStack(spacing: 8) {
                        Image(systemName: entry.syncStatus == .failed ? "exclamationmark.triangle.fill" : "clock.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(entry.syncStatus == .failed ? CloseCutColors.failed : CloseCutColors.pending)

                        Text(syncText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)

                        Spacer()
                    }
                    .padding(10)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    onEditSharing()
                } label: {
                    Text(isShared ? "Edit sharing" : "Share with a Circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
