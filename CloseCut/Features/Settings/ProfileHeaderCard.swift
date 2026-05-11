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

    private var displayName: String {
        let cleaned = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty {
            return user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? user.displayName ?? "CloseCut user"
                : "CloseCut user"
        }

        return cleaned
    }

    private var initials: String {
        let parts = displayName
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }

        return String(displayName.prefix(2)).uppercased()
    }

    private var emailText: String {
        let profileEmail = profile.email?.trimmingCharacters(in: .whitespacesAndNewlines)
        let authEmail = user.email?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let profileEmail, profileEmail.isEmpty == false {
            return profileEmail
        }

        if let authEmail, authEmail.isEmpty == false {
            return authEmail
        }

        return user.id
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                CloseCutColors.accent,
                                CloseCutColors.accentLight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)

                Text(initials)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text(emailText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    profilePill(
                        icon: "lock.fill",
                        text: "Private taste journal"
                    )

                    profilePill(
                        icon: "iphone",
                        text: "Local-first"
                    )
                }
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
        .accessibilityLabel("\(displayName), \(emailText)")
    }

    private func profilePill(
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
        .foregroundStyle(CloseCutColors.accentLight)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}
