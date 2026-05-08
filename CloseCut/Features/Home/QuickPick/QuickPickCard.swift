//
//  QuickPickCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct QuickPickCard: View {
    let suggestion: QuickPickSuggestion
    let isNoAlternatives: Bool
    let onRefresh: () -> Void

    private var label: String {
        suggestion.candidate.isRewatchCandidate ? "Rewatch candidate" : "Watch next"
    }

    private var descriptionText: String? {
        cleanOptional(suggestion.candidate.overview)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            hero

            Text(suggestion.reason)
                .font(.body)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let descriptionText {
                Text(descriptionText)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .lineSpacing(3)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            signalPills

            Text("Local, rule-based, and private. No public ratings profile.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)

            if isNoAlternatives {
                Text("That is the strongest match right now.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 2)
            }

            Button {
                onRefresh()
            } label: {
                Label("Show me another", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(20)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label). \(suggestion.candidate.title). \(suggestion.reason)")
    }

    private var hero: some View {
        HStack(alignment: .top, spacing: 14) {
            QuickPickPosterView(candidate: suggestion.candidate)

            VStack(alignment: .leading, spacing: 8) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.accentLight)

                Text(suggestion.candidate.title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Text(suggestion.candidate.metadata)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text(suggestion.confidenceLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var signalPills: some View {
        if suggestion.signals.isEmpty == false {
            HStack(spacing: 8) {
                ForEach(Array(suggestion.signals.enumerated()), id: \.offset) { _, signal in
                    Text(signal.displayLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}

private struct QuickPickPosterView: View {
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
