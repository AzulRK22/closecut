//
//  CircleCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CircleCardView: View {
    let circle: CloseCircle
    let membership: CircleMembership

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(circle.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    if let description = circle.description,
                       description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(2)
                    } else {
                        Text("A private space for shared watch memories.")
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Text(membership.role.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(membership.isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Label("\(circle.memberIds.count) members", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("Owner: \(circle.ownerDisplayName)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Spacer()
            }

            HStack {
                Text("Updated \(circle.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(circle.name), \(circle.memberIds.count) members, owner \(circle.ownerDisplayName)")
    }
}
