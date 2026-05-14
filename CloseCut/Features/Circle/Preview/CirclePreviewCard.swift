//
//  CirclePreviewCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

struct CirclePreviewCard: View {
    let preview: CirclePreview

    private var descriptionText: String {
        guard let description = preview.circle.description,
              description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
            return "A private Circle for shared watch memories."
        }

        return description
    }

    private var initials: String {
        let words = preview.circle.name
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(preview.circle.name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Divider()
                .overlay(CloseCutColors.separator)

            VStack(spacing: 10) {
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

            accessNote
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    preview.isAlreadyMember ? CloseCutColors.synced.opacity(0.7) : CloseCutColors.accentLight.opacity(0.65),
                    lineWidth: 0.8
                )
        }
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 8)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(CloseCutColors.accent.opacity(0.16))
                    .frame(width: 52, height: 52)

                Text(initials)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CloseCutColors.accentLight)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(preview.isAlreadyMember ? "You’re already in" : "Circle found")
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(preview.isAlreadyMember ? CloseCutColors.synced : CloseCutColors.accentLight)
                    .textCase(.uppercase)

                Text(preview.circle.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(descriptionText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(2)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    private var accessNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: preview.isAlreadyMember ? "checkmark.circle.fill" : "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(preview.isAlreadyMember ? CloseCutColors.synced : CloseCutColors.accentLight)
                .padding(.top, 1)

            Text(noteText)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var noteText: String {
        if preview.isAlreadyMember {
            return "You already have access to this Circle’s shared memories."
        }

        return "Joining gives you access to this Circle’s shared entries. It does not expose your Personal library."
    }
}
