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
    @State private var didOpenQuickAddPath = false

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
                        ForEach(viewModel.steps) { step in
                            onboardingPage(step)
                                .tag(step.id)
                        }

                        chooseStartPage
                            .tag(viewModel.totalSteps - 1)
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(viewModel.isCompleting)
        .confirmationDialog(
            "Skip setup?",
            isPresented: $viewModel.showSkipConfirmation,
            titleVisibility: .visible
        ) {
            Button("Skip setup", role: .destructive) {
                Task {
                    await complete(path: .skipped)
                }
            }

            Button("Continue setup", role: .cancel) {}
        } message: {
            Text("You can still add past watches later, but CloseCut works better when your library has a few memories from the start.")
        }
        .sheet(isPresented: $isShowingQuickAdd, onDismiss: {
            guard didOpenQuickAddPath else {
                return
            }

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
                    withAnimation(.easeInOut(duration: 0.18)) {
                        viewModel.backTapped()
                    }
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

            Text(viewModel.progressText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(CloseCutColors.input)
                .clipShape(Capsule())
                .accessibilityLabel("Onboarding step \(viewModel.progressText)")

            Spacer()

            Button {
                viewModel.requestSkipConfirmation()
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
            .accessibilityLabel("Skip onboarding")
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    private func onboardingPage(_ step: OnboardingStepContent) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 36)

            OnboardingHeroCard(
                title: step.title,
                message: step.message,
                systemImage: step.systemImage,
                isLogo: step.isLogo,
                pills: step.pills
            )

            Spacer(minLength: 28)
        }
    }

    private var chooseStartPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 36)

                VStack(spacing: 18) {
                    CloseCutLogoMark(size: 76)

                    VStack(spacing: 10) {
                        Text("Make CloseCut yours.")
                            .font(.largeTitle.weight(.semibold))
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.86)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Start with a few memories or go straight in. The more history you add, the better your Timeline and QuickPick become.")
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 24)
                    }

                    HStack(spacing: 8) {
                        OnboardingFeaturePill(
                            icon: "film.fill",
                            text: "Timeline"
                        )

                        OnboardingFeaturePill(
                            icon: "sparkles",
                            text: "QuickPick"
                        )

                        OnboardingFeaturePill(
                            icon: "person.2.fill",
                            text: "Circles"
                        )
                    }
                }

                VStack(spacing: 12) {
                    OnboardingChoiceCard(
                        title: "Add past watches",
                        message: "Best start. Add movies or series you already watched so your library, QuickPick, and taste patterns become useful immediately.",
                        systemImage: "bolt.fill",
                        badgeText: "Recommended",
                        isPrimary: true,
                        isDisabled: viewModel.isCompleting
                    ) {
                        Task {
                            await startQuickAddPath()
                        }
                    }

                    OnboardingChoiceCard(
                        title: "Start fresh",
                        message: "Go to your library now and log your next watch whenever you're ready.",
                        systemImage: "plus.circle",
                        badgeText: nil,
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
                    loadingBanner
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

    private var loadingBanner: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(CloseCutColors.accentLight)

            Text("Preparing your space…")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your space")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentStep ? CloseCutColors.accent : CloseCutColors.input)
                    .frame(
                        width: index == viewModel.currentStep ? 18 : 7,
                        height: 7
                    )
                    .animation(.easeInOut(duration: 0.18), value: viewModel.currentStep)
            }
        }
        .padding(.bottom, 18)
        .accessibilityLabel("Onboarding page \(viewModel.currentStep + 1) of \(viewModel.totalSteps)")
    }

    private var continueButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.continueTapped()
            }
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
        .accessibilityLabel("Continue")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Onboarding error: \(message)")
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
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Private by default. Circle sharing only happens when you explicitly choose it.")
    }

    private func startQuickAddPath() async {
        let didComplete = await viewModel.complete(
            userId: user.id,
            path: .quickAdd,
            modelContext: modelContext
        )

        if didComplete {
            didOpenQuickAddPath = true
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

#Preview {
    OnboardingView(
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        onCompleted: {}
    )
    .modelContainer(for: [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self
    ], inMemory: true)
}
