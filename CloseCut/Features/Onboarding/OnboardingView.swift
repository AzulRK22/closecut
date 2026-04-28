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
                            message: "CloseCut learns from your history to help you remember, revisit, and choose better.",
                            systemImage: "sparkles"
                        )
                        .tag(1)

                        chooseStartPage
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    pageDots

                    if viewModel.currentStep < 2 {
                        continueButton
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(CloseCutColors.textSecondary)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button("Skip") {
                Task {
                    await complete(path: .skipped)
                }
            }
            .font(.subheadline)
            .foregroundStyle(CloseCutColors.textSecondary)
            .frame(minHeight: 44)
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
                    .frame(width: 180, height: 180)

                Image(systemName: systemImage)
                    .font(.system(size: 64, weight: .regular))
                    .foregroundStyle(CloseCutColors.accentLight)
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
                    .lineLimit(3)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private var chooseStartPage: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("Choose your start")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Add a few past watches to make your timeline and picks feel personal from day one.")
                    .font(.body)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 12) {
                OnboardingChoiceCard(
                    title: "Add past watches fast",
                    message: "Search, tap, done. Add details later.",
                    systemImage: "bolt.fill",
                    isPrimary: true
                ) {
                    Task {
                        let didComplete = await viewModel.complete(
                            userId: user.id,
                            path: .quickAdd,
                            modelContext: modelContext
                        )

                        if didComplete {
                            isShowingQuickAdd = true
                        }
                    }
                }

                OnboardingChoiceCard(
                    title: "Start fresh",
                    message: "Go to your timeline and log when you're ready.",
                    systemImage: "plus.circle",
                    isPrimary: false
                ) {
                    Task {
                        await complete(path: .startFresh)
                    }
                }
            }
            .padding(.horizontal, 20)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.failed)
                    .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                SwiftUI.Circle()
                    .fill(index == viewModel.currentStep ? CloseCutColors.accent : CloseCutColors.input)
                    .frame(width: 7, height: 7)
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
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(CloseCutColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
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
