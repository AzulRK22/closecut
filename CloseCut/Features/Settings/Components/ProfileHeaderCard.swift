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
    let avatarPreset: AvatarPreset
    let onEditProfile: () -> Void

    private var displayName: String {
        let cleaned = profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.isEmpty {
            if let userDisplayName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
               userDisplayName.isEmpty == false {
                return userDisplayName
            }

            return "CloseCut user"
        }

        return cleaned
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                SettingsAvatarView(
                    displayName: displayName,
                    preset: avatarPreset,
                    size: 62
                )

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
                            text: "Private"
                        )

                        profilePill(
                            icon: "person.2.fill",
                            text: "Circle identity"
                        )
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "eye.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 2)

                Text("This is how you appear inside CloseCut and private Circles. Your personal archive stays private unless you share specific entries.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(CloseCutColors.input.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            Button {
                onEditProfile()
            } label: {
                Label("Edit profile", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
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
