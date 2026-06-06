//
//  CircleQuickPickView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct CircleQuickPickView: View {
    let sharedEntries: [Entry]
    let memberCount: Int
    let state: QuickPickState
    let onShowAnother: () -> Void
    let onOpenTimeline: () -> Void

    private var sharedCountText: String {
        sharedEntries.count == 1 ? "1 shared memory" : "\(sharedEntries.count) shared memories"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            switch state {
            case .insufficientHistory(let currentCount, let targetCount):
                insufficientHistoryView(
                    currentCount: currentCount,
                    targetCount: targetCount
                )

            case .suggestion(let suggestion):
                suggestionContent(
                    suggestion: suggestion,
                    isNoAlternatives: false
                )

            case .noAlternatives(let suggestion):
                suggestionContent(
                    suggestion: suggestion,
                    isNoAlternatives: true
                )

            case .error(let message):
                errorView(message)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(width: 38, height: 38)
                    .background(CloseCutColors.input)
                    .clipShape(SwiftUI.Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text("Circle QuickPick")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("A group pick based only on what this Circle has shared.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                summaryPill(
                    icon: "film.stack.fill",
                    text: sharedCountText
                )

                summaryPill(
                    icon: "person.2.fill",
                    text: memberCount == 1 ? "1 member" : "\(memberCount) members"
                )

                summaryPill(
                    icon: "lock.fill",
                    text: "Private"
                )
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func insufficientHistoryView(
        currentCount: Int,
        targetCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            EmptyStateView(
                title: "Share a little more first",
                message: "Group QuickPick needs \(targetCount) shared memories to understand this Circle. You have \(currentCount) so far.",
                systemImage: "sparkles",
                actionTitle: "View shared timeline",
                action: onOpenTimeline
            )

            Text("Only entries intentionally shared with this Circle are used. Personal libraries stay private.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func suggestionContent(
        suggestion: QuickPickSuggestion,
        isNoAlternatives: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            CircleQuickPickCard(
                suggestion: suggestion,
                isNoAlternatives: isNoAlternatives,
                onShowAnother: onShowAnother
            )

            Text("This pick is stable for the current Circle history. It only changes when you ask for another pick or when shared data changes.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        }
    }

    private func errorView(
        _ message: String
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.failed)

            VStack(spacing: 5) {
                Text("Couldn’t make a group pick.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onOpenTimeline()
            } label: {
                Text("View shared timeline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private func summaryPill(
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
        .foregroundStyle(CloseCutColors.textSecondary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(CloseCutColors.input)
        .clipShape(Capsule())
    }
}

private struct CircleQuickPickCard: View {
    let suggestion: QuickPickSuggestion
    let isNoAlternatives: Bool
    let onShowAnother: () -> Void

    private var label: String {
        suggestion.candidate.isRewatchCandidate ? "Group rewatch" : "Group pick"
    }

    private var descriptionText: String? {
        cleanOptional(suggestion.candidate.overview)
    }

    private var visibleSignals: [QuickPickSignal] {
        Array(suggestion.signals.prefix(3))
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

            VStack(alignment: .leading, spacing: 4) {
                Text("Built from shared Circle history.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Text("This does not read members’ full Personal libraries.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            if isNoAlternatives {
                Text("That is the strongest group match right now.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .padding(.top, 2)
            }

            Button {
                onShowAnother()
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
            CircleQuickPickPosterView(candidate: suggestion.candidate)

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
                    .lineLimit(2)

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
        if visibleSignals.isEmpty == false {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 92), spacing: 8)
                ],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(Array(visibleSignals.enumerated()), id: \.offset) { _, signal in
                    Text(signal.displayLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }
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

private struct CircleQuickPickPosterView: View {
    let candidate: SuggestionCandidate

    private var fallbackIcon: String {
        candidate.type == .movie ? "film.fill" : "tv.fill"
    }

    private var fallbackInitials: String {
        let words = candidate.title
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(candidate.title.prefix(2)).uppercased()
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
        ZStack {
            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.22),
                    CloseCutColors.card.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 7) {
                Image(systemName: fallbackIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.accentLight)

                Text(fallbackInitials)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }
            .padding(8)
        }
    }
}
