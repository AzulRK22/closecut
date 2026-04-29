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

    var body: some View {
        HStack(spacing: 14) {
            SwiftUI.Circle()
                .fill(CloseCutColors.accent)
                .frame(width: 58, height: 58)
                .overlay {
                    Text(initials)
                        .font(.headline)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.displayName)
                    .font(.headline)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text(profile.email ?? user.email ?? user.id)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()
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
