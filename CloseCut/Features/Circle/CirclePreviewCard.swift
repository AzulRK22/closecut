//
//  CirclePreviewCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CirclePreviewCard: View {
    let preview: CirclePreview

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(CloseCutColors.accent.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: "person.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(preview.circle.name)
                        .font(.headline)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)

                    if let description = preview.circle.description,
                       description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(3)
                    } else {
                        Text("A private Circle for shared watch memories.")
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(3)
                    }
                }

                Spacer()
            }

            Divider()
                .overlay(CloseCutColors.separator)

            VStack(spacing: 8) {
                DetailInfoRow(
                    label: "Owner",
                    value: preview.circle.ownerDisplayName
                )

                DetailInfoRow(
                    label: "Members",
                    value: preview.memberCountText
                )

                DetailInfoRow(
                    label: "Invite code",
                    value: preview.circle.inviteCode
                )
            }

            if preview.isAlreadyMember {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CloseCutColors.synced)

                    Text("You’re already a member of this Circle.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }
                .padding(.top, 4)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.top, 2)

                    Text("Joining only gives you access to entries intentionally shared with this Circle. Personal histories stay private.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
