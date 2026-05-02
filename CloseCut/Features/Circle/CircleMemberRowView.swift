//
//  CircleMemberRowView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CircleMemberRowView: View {
    let member: CircleMember
    let currentUserId: String

    private var isCurrentUser: Bool {
        member.userId == currentUserId
    }

    var body: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    if isCurrentUser {
                        Text("You")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }

                Text(member.email ?? member.role.displayName)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(member.role.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(member.role == .owner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(CloseCutColors.input)
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.displayName), \(member.role.displayName)")
    }

    private var avatar: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(CloseCutColors.input)
                .frame(width: 36, height: 36)

            Text(initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(CloseCutColors.textPrimary)
        }
    }

    private var initials: String {
        let parts = member.displayName
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }

        return String(member.displayName.prefix(2)).uppercased()
    }
}
