//
//  OnboardingView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var isShowingQuickAdd = false

    let user: AuthUser
    let onCompleted: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CloseCutColors.backgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    TabView(selection: $viewModel.currentStep) {
                        onboardingPage(
                            index: 0,
                            title: "Your taste has a history",
                            message: "Build a private record of the movies and series that shaped you.",
                            systemImage: "film.stack"
                        )
                        .tag(0)

                        onboardingPage(
                            index: 1,
                            title: "Know what moved you. Know what to watch next.",
                            message: "CloseCut uses your own history to help you remember, revisit, and choose better.",
                            systemImage: "sparkles"
                        )
                        .tag(1)

                        chooseStartPage
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .disabled(viewModel.isCompleting)

                    pageDots

                    if viewModel.currentStep < viewModel.totalSteps - 1 {
                        continueButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(viewModel.isCompleting)
        .sheet(isPresented: $isShowingQuickAdd, onDismiss: {
            onCompleted()
        }) {
            QuickAddPastWatchesView(user: user)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var topBar: some View {
        HStack {
            if viewModel.canGoBack {
                Button {
                    viewModel.backTapped()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(CloseCutColors.textSecondary)
                .disabled(viewModel.isCompleting)
                .accessibilityLabel("Back")
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button {
                Task {
                    await complete(path: .skipped)
                }
            } label: {
                if viewModel.isCompleting {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(minWidth: 44, minHeight: 44)
                } else {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isCompleting)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func onboardingPage(
        index: Int,
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                SwiftUI.Circle()
                    .fill(CloseCutColors.card)
                    .frame(width: 188, height: 188)

                SwiftUI.Circle()
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
                    .frame(width: 188, height: 188)

                if index == 0 {
                    CloseCutLogoMark(size: 104)
                } else {
                    Image(systemName: systemImage)
                        .font(.system(size: 64, weight: .regular))
                        .foregroundStyle(CloseCutColors.accentLight)
                }
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private var chooseStartPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 44)

                VStack(spacing: 12) {
                    Text("Choose your start")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Add a few past watches to make your Timeline and QuickPick feel personal from day one.")
                        .font(.body)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                }

                VStack(spacing: 12) {
                    OnboardingChoiceCard(
                        title: "Add past watches fast",
                        message: "Search, tap, done. Start with history now and add richer details later.",
                        systemImage: "bolt.fill",
                        isPrimary: true,
                        isDisabled: viewModel.isCompleting
                    ) {
                        Task {
                            await startQuickAddPath()
                        }
                    }

                    OnboardingChoiceCard(
                        title: "Start fresh",
                        message: "Go straight to your Timeline and log when you're ready.",
                        systemImage: "plus.circle",
                        isPrimary: false,
                        isDisabled: viewModel.isCompleting
                    ) {
                        Task {
                            await complete(path: .startFresh)
                        }
                    }
                }
                .padding(.horizontal, 20)

                if viewModel.isCompleting {
                    HStack(spacing: 10) {
                        ProgressView()

                        Text("Preparing your space…")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textSecondary)
                    }
                    .padding(.horizontal, 20)
                }

                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                        .padding(.horizontal, 20)
                }

                privacyNote
                    .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                SwiftUI.Circle()
                    .fill(index == viewModel.currentStep ? CloseCutColors.accent : CloseCutColors.input)
                    .frame(width: 7, height: 7)
                    .animation(.easeInOut(duration: 0.18), value: viewModel.currentStep)
            }
        }
        .padding(.bottom, 18)
        .accessibilityLabel("Onboarding page \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
    }

    private var continueButton: some View {
        Button {
            viewModel.continueTapped()
        } label: {
            Text("Continue")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(CloseCutColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isCompleting)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.failed)
                .padding(.top, 2)

            Text(message)
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.failedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Private by default. Circle sharing only happens when you explicitly choose it.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func startQuickAddPath() async {
        let didComplete = await viewModel.complete(
            userId: user.id,
            path: .quickAdd,
            modelContext: modelContext
        )

        if didComplete {
            isShowingQuickAdd = true
        }
    }

    private func complete(path: OnboardingStartPath) async {
        let didComplete = await viewModel.complete(
            userId: user.id,
            path: path,
            modelContext: modelContext
        )

        if didComplete {
            onCompleted()
        }
    }
}
