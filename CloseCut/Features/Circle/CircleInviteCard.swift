//
//  CircleInviteCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct CircleInviteCard: View {
    let inviteCode: String
    let onCopy: () -> Void
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.2.circle.fill")
                    .font(.title2)
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your private Circle")
                        .font(.headline)
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Invite trusted friends later to share memories, reactions, and short comments.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Invite code")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.8)

                HStack {
                    Text(inviteCode)
                        .font(.title3.monospaced().weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Spacer()

                    Button {
                        onCopy()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .frame(width: 40, height: 40)
                    }
                    .accessibilityLabel("Copy invite code")
                }
                .padding(.horizontal, 14)
                .frame(height: 54)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                onJoin()
            } label: {
                Text("Join a Circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
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
