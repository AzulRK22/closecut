//
//  HomeHeroQuickPickCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct HomeHeroQuickPickCard: View {
    let entries: [Entry]
    let onQuickAdd: () -> Void
    let onOpenQuickPick: () -> Void

    @State private var state: QuickPickState = .insufficientHistory(
        currentCount: 0,
        targetCount: 3
    )

    private let engine = QuickPickEngine()

    private var refreshKey: String {
        entries
            .map {
                "\($0.id)-\($0.updatedAt.timeIntervalSince1970)-\($0.tmdbId ?? -1)-\($0.quickSentiment?.rawValue ?? "")"
            }
            .joined(separator: "|")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            switch state {
            case .insufficientHistory(let currentCount, let targetCount):
                insufficientHistoryContent(
                    currentCount: currentCount,
                    targetCount: targetCount
                )

            case .suggestion(let suggestion), .noAlternatives(let suggestion):
                suggestionContent(suggestion)

            case .error:
                fallbackContent
            }
        }
        .padding(16)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .task(id: refreshKey) {
            await generateSuggestion()
        }
    }

    private var heroBackground: some View {
        ZStack {
            CloseCutColors.card

            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.18),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func insufficientHistoryContent(
        currentCount: Int,
        targetCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                heroIcon("sparkles")

                VStack(alignment: .leading, spacing: 5) {
                    Text("Build your taste signal")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Add \(max(targetCount - currentCount, 0)) more \(max(targetCount - currentCount, 0) == 1 ? "watch" : "watches") to unlock a better personal pick.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                onQuickAdd()
            } label: {
                Label("Add past watches", systemImage: "bolt.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func suggestionContent(
        _ suggestion: QuickPickSuggestion
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            QuickPickHeroPoster(candidate: suggestion.candidate)

            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY’S PICK")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.accentLight)

                Text(suggestion.candidate.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(suggestion.candidate.metadata)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineLimit(1)

                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    onOpenQuickPick()
                } label: {
                    Text("Open QuickPick")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
    }

    private var fallbackContent: some View {
        HStack(alignment: .top, spacing: 12) {
            heroIcon("sparkles")

            VStack(alignment: .leading, spacing: 5) {
                Text("QuickPick is warming up")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text("Open QuickPick to generate a suggestion from your personal history.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    onOpenQuickPick()
                } label: {
                    Text("Open QuickPick")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }

            Spacer()
        }
    }

    private func heroIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(CloseCutColors.accentLight)
            .frame(width: 38, height: 38)
            .background(CloseCutColors.input)
            .clipShape(SwiftUI.Circle())
    }

    private func generateSuggestion() async {
        state = await engine.generateSuggestion(history: entries)
    }
}

private struct QuickPickHeroPoster: View {
    let candidate: SuggestionCandidate

    private var fallbackIcon: String {
        candidate.type == .movie ? "film.fill" : "tv.fill"
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL = candidate.posterURL {
                AsyncImage(url: posterURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .scaleEffect(0.7)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:
                        fallback

                    @unknown default:
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .frame(width: 82, height: 122)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        VStack(spacing: 7) {
            Image(systemName: fallbackIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text(candidate.type.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .lineLimit(1)
        }
        .padding(6)
    }
}
