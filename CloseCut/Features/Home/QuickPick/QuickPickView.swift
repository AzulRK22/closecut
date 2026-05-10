//
//  QuickPickView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import SwiftUI

struct QuickPickView: View {
    let entries: [Entry]
    let onQuickAdd: () -> Void
    let onCreateEntry: () -> Void

    @StateObject private var viewModel = QuickPickViewModel()

    private var activeEntries: [Entry] {
        entries
            .filter { $0.deletedAt == nil }
            .sorted { first, second in
                first.watchedAt > second.watchedAt
            }
    }

    private var quickPickRefreshKey: String {
        activeEntries
            .map {
                "\($0.id)-\($0.updatedAt.timeIntervalSince1970)-\($0.tmdbId ?? -1)-\($0.quickSentiment?.rawValue ?? "")-\($0.intensity)"
            }
            .joined(separator: "|")
    }

    var body: some View {
        Group {
            switch viewModel.state {
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
        .background(CloseCutColors.backgroundPrimary)
        .onAppear {
            viewModel.generate(history: activeEntries)
        }
        .onChange(of: quickPickRefreshKey) { _, _ in
            viewModel.generate(history: activeEntries)
        }
        .onDisappear {
            viewModel.cancelGeneration()
        }
    }

    private func insufficientHistoryView(
        currentCount: Int,
        targetCount: Int
    ) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                EmptyStateView(
                    title: "QuickPick needs a little history",
                    message: "Add \(targetCount) watches so CloseCut can understand your taste. You have \(currentCount) so far.",
                    systemImage: "sparkles",
                    actionTitle: "Add past watches",
                    action: onQuickAdd
                )

                Button {
                    onCreateEntry()
                } label: {
                    Text("Log a new watch")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private func suggestionContent(
        suggestion: QuickPickSuggestion,
        isNoAlternatives: Bool
    ) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                QuickPickCard(
                    suggestion: suggestion,
                    isNoAlternatives: isNoAlternatives,
                    onRefresh: {
                        viewModel.refresh(history: activeEntries)
                    }
                )

                Text("QuickPick is local and rule-based. No AI claims, no public data.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(CloseCutColors.failed)

            Text("Couldn’t make a pick right now.")
                .font(.headline)
                .foregroundStyle(CloseCutColors.textPrimary)

            Text(message)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                viewModel.refresh(history: activeEntries)
            } label: {
                Text("Retry")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 160, height: 44)
                    .background(CloseCutColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
