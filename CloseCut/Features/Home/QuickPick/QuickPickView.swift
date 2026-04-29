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
            viewModel.generate(history: entries)
        }
        .onChange(of: entries.count) { _, _ in
            viewModel.generate(history: entries)
        }
    }

    private func insufficientHistoryView(
        currentCount: Int,
        targetCount: Int
    ) -> some View {
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
                        viewModel.refresh(history: entries)
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
                viewModel.refresh(history: entries)
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
