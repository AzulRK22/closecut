//
//  ProfileHeaderCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct ProfileHeaderCard: View {
    let user: AuthUser
    let profile: UserProfile

    private var initials: String {
        let trimmed = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return "CC"
        }

        let parts = trimmed.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }

        return String(letters).uppercased()
    }

    private var emailText: String {
        profile.email ?? user.email ?? user.id
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.accent)
                    .frame(width: 58, height: 58)

                Text(initials)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(profile.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text(emailText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)

                Text("Private taste journal")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.displayName), \(emailText)")
    }
}
