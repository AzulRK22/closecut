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
    var sharedMemoryCount: Int = 0

    private var memberCount: Int {
        max(circle.memberIds.count, 1)
    }

    private var memberCountText: String {
        memberCount == 1 ? "1 member" : "\(memberCount) members"
    }

    private var descriptionText: String {
        guard let description = circle.description,
              description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return "A private space for shared watch memories."
        }

        return description
    }

    private var sharedMemoryText: String {
        sharedMemoryCount == 1 ? "1 shared memory" : "\(sharedMemoryCount) shared memories"
    }

    private var roleIcon: String {
        membership.isOwner ? "crown.fill" : "person.fill"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topRow

            Text(descriptionText)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                infoPill(
                    icon: "person.2.fill",
                    text: memberCountText
                )

                infoPill(
                    icon: "film.stack.fill",
                    text: sharedMemoryText
                )
            }

            Divider()
                .overlay(CloseCutColors.separator)

            bottomRow
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(circle.name), \(memberCountText), \(sharedMemoryText), \(membership.role.displayName)")
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 5) {
                Text(circle.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: roleIcon)
                        .font(.caption2.weight(.semibold))

                    Text(membership.role.displayName)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(membership.isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 6)
        }
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CloseCutColors.accent.opacity(0.16))
                .frame(width: 48, height: 48)

            Text(initials)
                .font(.headline.weight(.bold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    private var initials: String {
        let words = circle.name
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(circle.name.prefix(2)).uppercased()
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text("Updated \(circle.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)

            Spacer()

            Text("Open space")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    private func infoPill(
        icon: String,
        text: String
    ) -> some View {
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
