//
//  StateContainerView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum ViewState<Value> {
    case loading
    case empty
    case success(Value)
    case error(String)
}

struct StateContainerView<Value, Content: View>: View {
    let state: ViewState<Value>

    var emptyTitle: String
    var emptyMessage: String
    var emptySystemImage: String

    var loadingMessage: String
    var errorTitle: String

    var retry: (() -> Void)?
    let content: (Value) -> Content

    init(
        state: ViewState<Value>,
        emptyTitle: String,
        emptyMessage: String,
        emptySystemImage: String = "film",
        loadingMessage: String = "Loading…",
        errorTitle: String = "Something went wrong",
        retry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.emptySystemImage = emptySystemImage
        self.loadingMessage = loadingMessage
        self.errorTitle = errorTitle
        self.retry = retry
        self.content = content
    }

    var body: some View {
        switch state {
        case .loading:
            loadingView

        case .empty:
            EmptyStateView(
                title: emptyTitle,
                message: emptyMessage,
                systemImage: emptySystemImage
            )

        case .success(let value):
            content(value)

        case .error(let message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(CloseCutColors.accentLight)

            Text(loadingMessage)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(loadingMessage)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.failedBackground)
                    .frame(width: 72, height: 72)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.failed)
            }

            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let retry {
                Button {
                    retry()
                } label: {
                    Text("Retry")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .accessibilityHint("Attempts to load this content again.")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(CloseCutColors.card.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
        .accessibilityElement(children: .contain)
    }
}
