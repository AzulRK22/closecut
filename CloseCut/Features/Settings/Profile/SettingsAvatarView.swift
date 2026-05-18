//
//  SettingsAvatarView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 15/05/26.
//

import SwiftUI

struct SettingsAvatarView: View {
    let displayName: String
    let preset: AvatarPreset
    var size: CGFloat = 58
    var showsIcon: Bool = false

    private var initials: String {
        let cleanedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedName.isEmpty == false else {
            return "CC"
        }

        let parts = cleanedName
            .split(separator: " ")
            .map(String.init)

        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }

        return String(cleanedName.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(
                    LinearGradient(
                        colors: preset.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            SwiftUI.Circle()
                .stroke(.white.opacity(0.18), lineWidth: 1)
                .frame(width: size, height: size)

            if showsIcon {
                Image(systemName: preset.systemImage)
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(.white)
            } else {
                Text(initials)
                    .font(.system(size: size * 0.30, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .accessibilityHidden(true)
    }
}
