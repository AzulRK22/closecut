//
//  BattleWinnerActionCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/06/26.
//

import SwiftUI

struct BattleWinnerActionCard: View {
    let winner: BattleCandidate
    let canAddToPersonal: Bool
    let canSaveToWatchlist: Bool
    let isProcessing: Bool
    let onAddToPersonal: () -> Void
    let onSaveToWatchlist: () -> Void

    @State private var sharePayload: CloseCutSharePayload?

    private var shareItem: CloseCutShareItem {
        CloseCutShareTextBuilder.battleWinner(
            winnerTitle: winner.displayTitle,
            metadataText: winner.metadataText,
            optionCount: 2,
            sourceText: winner.sourceLabelText
        )
    }

    var body: some View {
        BattleSectionCard(
            title: "Winner actions",
            subtitle: "Turn the result into your next step."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                actionSummary

                if canAddToPersonal {
                    Button {
                        onAddToPersonal()
                    } label: {
                        primaryActionLabel(
                            icon: "checkmark.circle.fill",
                            title: isProcessing ? "Adding to Personal..." : "Add winner to Personal"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                if canSaveToWatchlist {
                    Button {
                        onSaveToWatchlist()
                    } label: {
                        secondaryActionLabel(
                            icon: "bookmark.fill",
                            title: isProcessing ? "Saving..." : "Save winner to Want to Watch"
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isProcessing)
                }

                shareSection

                Text("Sharing uses the system share sheet. Nothing is posted automatically to Circles yet.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .task(id: winner.id) {
                await prepareSharePayload()
            }
        }
    }

    // MARK: - Share

    @ViewBuilder
    private var shareSection: some View {
        if let sharePayload,
           let previewImage = sharePayload.previewImage {
            ShareLink(
                item: sharePayload,
                preview: SharePreview(
                    shareItem.title,
                    image: Image(uiImage: previewImage)
                )
            ) {
                secondaryActionLabel(
                    icon: "photo.on.rectangle.angled",
                    title: "Share winner card"
                )
            }
            .buttonStyle(.plain)
        } else {
            Button {
                Task {
                    await prepareSharePayload()
                }
            } label: {
                secondaryActionLabel(
                    icon: "photo.on.rectangle.angled",
                    title: "Prepare share card"
                )
            }
            .buttonStyle(.plain)
        }

        ShareLink(item: shareItem.shareText) {
            secondaryActionLabel(
                icon: "text.quote",
                title: "Share as text"
            )
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func prepareSharePayload() async {
        guard let imageData = CloseCutShareImageRenderer.renderShareCardPNGData(
            item: shareItem
        ) else {
            sharePayload = nil
            return
        }

        sharePayload = CloseCutSharePayload(
            imageData: imageData,
            fallbackText: shareItem.shareText
        )
    }

    // MARK: - Summary

    private var actionSummary: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: winner.source.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .frame(width: 30, height: 30)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(winner.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)

                Text(actionContextText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.74))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionContextText: String {
        switch winner.source {
        case .archive:
            return "This winner already belongs to Personal. You can share the result."
        case .watchlist:
            return "This winner is already saved for later. Mark it watched when you actually watch it."
        case .tmdb:
            return "This winner came from Discover/TMDB. Save it before you forget it."
        case .manual:
            return "This winner was added manually for Battle. You can turn it into a real memory."
        }
    }

    // MARK: - Button Labels

    private func primaryActionLabel(
        icon: String,
        title: String
    ) -> some View {
        HStack(spacing: 8) {
            if isProcessing {
                ProgressView()
                    .tint(.white)
            } else {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.84)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(CloseCutColors.accent)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private func secondaryActionLabel(
        icon: String,
        title: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.84)

            Spacer(minLength: 0)
        }
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}
