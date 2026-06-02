//
//  CircleInviteShareSheet.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import SwiftUI
import UIKit

struct CircleInviteShareSheet: View {
    let circle: CloseCircle
    let ownerDisplayName: String
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var copiedInviteCode = false

    private var shareItem: CloseCutShareItem {
        CloseCutShareTextBuilder.circleInvite(
            circleName: circle.displayName,
            inviteCode: circle.cleanedInviteCodeNormalized,
            ownerDisplayName: ownerDisplayName
        )
    }

    private var inviteCodeText: String {
        let cleanedCode = circle.cleanedInviteCodeNormalized
        return cleanedCode.isEmpty ? "No invite code" : cleanedCode
    }

    private var canShareInvite: Bool {
        circle.cleanedInviteCodeNormalized.isEmpty == false
    }

    private var memberCountText: String {
        circle.memberCount == 1 ? "1 member" : "\(circle.memberCount) members"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    content

                    Spacer(minLength: 0)

                    footerActions
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)
            }
            .navigationTitle("Share Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        closeSheet()
                    }
                    .foregroundStyle(CloseCutColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroCard

            sharePreview

            privacyStrip
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                circleAvatar

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        statusPill(
                            icon: "lock.fill",
                            text: "Private Circle",
                            isHighlighted: true
                        )

                        statusPill(
                            icon: "person.2.fill",
                            text: memberCountText,
                            isHighlighted: false
                        )
                    }

                    Text(circle.displayName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Invite someone you trust to this shared watch space.")
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            inviteCodePanel
        }
        .padding(18)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.26), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var circleAvatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            CloseCutColors.accent.opacity(0.28),
                            CloseCutColors.input
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)

            Text(circleInitials)
                .font(.title3.weight(.bold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.accentLight.opacity(0.32), lineWidth: 0.6)
        }
    }

    private var circleInitials: String {
        let words = circle.displayName
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(circle.displayName.prefix(2)).uppercased()
    }

    private var inviteCodePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Invite code", systemImage: "ticket.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Spacer()

                Button {
                    copyInviteCode()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copiedInviteCode ? "checkmark" : "doc.on.doc")
                            .font(.caption2.weight(.bold))

                        Text(copiedInviteCode ? "Copied" : "Copy")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(copiedInviteCode ? CloseCutColors.synced : CloseCutColors.accentLight)
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(CloseCutColors.card.opacity(0.9))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(canShareInvite == false)
            }

            Text(inviteCodeText)
                .font(.title.monospaced().weight(.bold))
                .foregroundStyle(canShareInvite ? CloseCutColors.textPrimary : CloseCutColors.textTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 58)
                .background(CloseCutColors.backgroundPrimary.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(CloseCutColors.separator, lineWidth: 0.5)
                }
        }
        .padding(14)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.cardElevated,
                    CloseCutColors.card,
                    CloseCutColors.accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    CloseCutColors.accentLight.opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 240
            )
        }
    }

    // MARK: - Share Preview

    private var sharePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 30, height: 30)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("What they’ll receive")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("A clean invite message with the Circle code.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(shareItem.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(sharePreviewBody)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineSpacing(3)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(CloseCutColors.input.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var sharePreviewBody: String {
        if canShareInvite {
            return "Use invite code: \(inviteCodeText)\n\nThis is a private CloseCut Circle for sharing movie and series memories with people you trust."
        }

        return "This Circle does not have an available invite code right now."
    }

    // MARK: - Privacy

    private var privacyStrip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("This only shares the invite. Personal entries, Watchlist, shared memories, reactions, and comments are not included.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Footer Actions

    private var footerActions: some View {
        VStack(spacing: 10) {
            ShareLink(item: shareItem.shareText) {
                HStack(spacing: 9) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption.weight(.bold))

                    Text("Share Circle invite")
                        .font(.headline.weight(.semibold))

                    Spacer(minLength: 0)
                }
                .foregroundStyle(canShareInvite ? .white : CloseCutColors.textTertiary)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(canShareInvite ? CloseCutColors.accent : CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canShareInvite == false)

            Button {
                copyInviteCode()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: copiedInviteCode ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption.weight(.semibold))

                    Text(copiedInviteCode ? "Invite code copied" : "Copy invite code")
                        .font(.subheadline.weight(.semibold))

                    Spacer(minLength: 0)
                }
                .foregroundStyle(copiedInviteCode ? CloseCutColors.synced : CloseCutColors.textSecondary)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(canShareInvite == false)
        }
        .padding(.top, 12)
        .background(
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Components

    private func statusPill(
        icon: String,
        text: String,
        isHighlighted: Bool
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2.weight(.bold))

            Text(text)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(CloseCutColors.input.opacity(0.85))
        .clipShape(Capsule())
    }

    // MARK: - Actions

    private func copyInviteCode() {
        guard canShareInvite else {
            return
        }

        UIPasteboard.general.string = inviteCodeText

        withAnimation(.easeInOut(duration: 0.18)) {
            copiedInviteCode = true
        }

        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.18)) {
                    copiedInviteCode = false
                }
            }
        }
    }

    private func closeSheet() {
        onDone()
        dismiss()
    }
}
