//
//  HomeHeroQuickPickCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct HomeHeroQuickPickCard: View {
    let state: QuickPickState
    let onQuickAdd: () -> Void
    let onOpenQuickPick: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        Group {
            switch state {
            case .insufficientHistory(let currentCount, let targetCount):
                insufficientHistoryCard(
                    currentCount: currentCount,
                    targetCount: targetCount
                )

            case .suggestion(let suggestion), .noAlternatives(let suggestion):
                suggestionCard(suggestion)

            case .error:
                fallbackCard
            }
        }
    }

    private func suggestionCard(
        _ suggestion: QuickPickSuggestion
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                poster(for: suggestion)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Label("Today’s Pick", systemImage: "sparkles")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())

                        Text(suggestion.confidenceLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }

                    Text(suggestion.candidate.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(suggestion.candidate.metadata)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .lineLimit(1)

                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineSpacing(3)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            signalPills(suggestion.signals)

            HStack(spacing: 10) {
                Button {
                    onOpenQuickPick()
                } label: {
                    Text("Open QuickPick")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    onRefresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(width: 48, height: 44)
                        .background(CloseCutColors.input)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show another pick")
            }

            Text("Stable for today unless your history changes or you ask for another.")
                .font(.caption2)
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(18)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today’s Pick. \(suggestion.candidate.title). \(suggestion.reason)")
    }

    private func insufficientHistoryCard(
        currentCount: Int,
        targetCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 42, height: 42)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Build your taste signal")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Add \(targetCount) watches to unlock better personal picks. You have \(currentCount) so far.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button {
                onQuickAdd()
            } label: {
                Text("Add past watches")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var fallbackCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("QuickPick is unavailable", systemImage: "exclamationmark.triangle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)

            Text("Your library is still safe. Try opening QuickPick again or add more watch history.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Button {
                onRefresh()
            } label: {
                Text("Try again")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func poster(
        for suggestion: QuickPickSuggestion
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CloseCutColors.input)

            if let posterURL = suggestion.candidate.posterURL {
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
                        fallbackPoster(type: suggestion.candidate.type)

                    @unknown default:
                        fallbackPoster(type: suggestion.candidate.type)
                    }
                }
            } else {
                fallbackPoster(type: suggestion.candidate.type)
            }
        }
        .frame(width: 92, height: 136)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func fallbackPoster(
        type: EntryType
    ) -> some View {
        VStack(spacing: 7) {
            Image(systemName: type == .movie ? "film.fill" : "tv.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

            Text(type.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(6)
    }

    @ViewBuilder
    private func signalPills(
        _ signals: [QuickPickSignal]
    ) -> some View {
        if signals.isEmpty == false {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(signals.prefix(3).enumerated()), id: \.offset) { _, signal in
                        Text(signal.displayLabel)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var heroBackground: some View {
        ZStack {
            CloseCutColors.card

            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.14),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
