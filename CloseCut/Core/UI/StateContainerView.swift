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
    var emptyActionTitle: String?
    var emptyAction: (() -> Void)?

    var loadingMessage: String
    var errorTitle: String
    var retry: (() -> Void)?

    var style: Style = .card

    let content: (Value) -> Content

    enum Style {
        case plain
        case card
        case fullScreen
    }

    init(
        state: ViewState<Value>,
        emptyTitle: String,
        emptyMessage: String,
        emptySystemImage: String = "film",
        emptyActionTitle: String? = nil,
        emptyAction: (() -> Void)? = nil,
        loadingMessage: String = "Loading…",
        errorTitle: String = "Something went wrong",
        retry: (() -> Void)? = nil,
        style: Style = .card,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.emptyTitle = emptyTitle
        self.emptyMessage = emptyMessage
        self.emptySystemImage = emptySystemImage
        self.emptyActionTitle = emptyActionTitle
        self.emptyAction = emptyAction
        self.loadingMessage = loadingMessage
        self.errorTitle = errorTitle
        self.retry = retry
        self.style = style
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
                systemImage: emptySystemImage,
                actionTitle: emptyActionTitle,
                action: emptyAction
            )

        case .success(let value):
            content(value)

        case .error(let message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: CloseCutSpacing.lg) {
            ProgressView()
                .tint(CloseCutColors.accentLight)

            Text(loadingMessage)
                .font(CloseCutTypography.secondary)
                .foregroundStyle(CloseCutColors.textSecondary)
        }
        .padding(CloseCutSpacing.xxl)
        .frame(
            maxWidth: .infinity,
            maxHeight: style == .fullScreen ? .infinity : nil
        )
        .background(containerBackground)
        .clipShape(containerShape)
        .overlay {
            containerBorder
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(loadingMessage)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: CloseCutSpacing.lg) {
            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.failedBackground)
                    .frame(width: 72, height: 72)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.failed)
            }
            .accessibilityHidden(true)

            VStack(spacing: CloseCutSpacing.sm) {
                Text(errorTitle)
                    .font(CloseCutTypography.sectionTitle)
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(CloseCutTypography.secondary)
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
                        .font(CloseCutTypography.button)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: CloseCutTheme.Size.buttonHeight)
                        .background(CloseCutColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: CloseCutTheme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, CloseCutSpacing.xs)
                .accessibilityHint("Attempts to load this content again.")
            }
        }
        .padding(CloseCutSpacing.xxl)
        .frame(
            maxWidth: .infinity,
            maxHeight: style == .fullScreen ? .infinity : nil
        )
        .background(containerBackground)
        .clipShape(containerShape)
        .overlay {
            containerBorder
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var containerBackground: some View {
        switch style {
        case .plain:
            Color.clear

        case .card:
            CloseCutColors.card.opacity(0.55)

        case .fullScreen:
            Color.clear
        }
    }

    private var containerShape: some Shape {
        RoundedRectangle(
            cornerRadius: style == .plain || style == .fullScreen ? 0 : CloseCutTheme.Radius.xxl,
            style: .continuous
        )
    }

    @ViewBuilder
    private var containerBorder: some View {
        if style == .card {
            RoundedRectangle(cornerRadius: CloseCutTheme.Radius.xxl, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
