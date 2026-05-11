//
//  RootView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @EnvironmentObject private var sessionSyncViewModel: SessionSyncViewModel

    var body: some View {
        switch authService.authState {
        case .loading:
            LoadingAuthView()

        case .signedOut:
            AuthView()
                .onAppear {
                    sessionViewModel.reset()
                    sessionSyncViewModel.reset()
                }

        case .signedIn(let user):
            SignedInSessionGate(user: user)

        case .error:
            AuthView()
        }
    }
}

// MARK: - Signed In Gate

private struct SignedInSessionGate: View {
    @EnvironmentObject private var sessionViewModel: SessionViewModel
    @Environment(\.modelContext) private var modelContext

    let user: AuthUser

    var body: some View {
        Group {
            switch sessionViewModel.profileState {
            case .idle:
                LoadingProfileView()
                    .task {
                        await prepareSession()
                    }

            case .loading:
                LoadingProfileView()

            case .ready(let profile):
                LaunchGateView(
                    user: user,
                    profile: profile
                )

            case .error(let message):
                ProfileErrorView(message: message) {
                    Task {
                        await prepareSession()
                    }
                }
            }
        }
    }

    private func prepareSession() async {
        await sessionViewModel.prepareSession(
            authUser: user,
            modelContext: modelContext
        )
    }
}

// MARK: - Launch Gate

private struct LaunchGateView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var launchViewModel = LaunchViewModel()

    let user: AuthUser
    let profile: UserProfile

    var body: some View {
        Group {
            if launchViewModel.isLoading {
                LoadingProfileView()
            } else {
                destinationContent
            }
        }
        .task(id: user.id) {
            launchViewModel.resolveIfNeeded(
                userId: user.id,
                modelContext: modelContext
            )
        }
    }

    @ViewBuilder
    private var destinationContent: some View {
        switch launchViewModel.destination {
        case .onboarding:
            OnboardingView(user: user) {
                launchViewModel.completeToMain()
            }

        case .mainHome:
            MainTabView(
                user: user,
                profile: profile
            )

        case .none:
            LoadingProfileView()
        }
    }
}

// MARK: - Loading Views

private struct LoadingAuthView: View {
    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 18) {
                CloseCutLogoMark(size: 76)

                VStack(spacing: 6) {
                    Text(AppEnvironment.appName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text("Preparing your taste journal")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                }

                ProgressView()
                    .padding(.top, 4)
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing \(AppEnvironment.appName)")
    }
}

private struct LoadingProfileView: View {
    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                CloseCutLogoMark(size: 64)

                Text("Preparing your profile")
                    .font(.subheadline)
                    .foregroundStyle(CloseCutColors.textSecondary)

                ProgressView()
            }
        }
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your profile")
    }
}

private struct ProfileErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(CloseCutColors.failed)

                Text("We couldn't prepare your profile.")
                    .font(.headline)
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .multilineTextAlignment(.center)

                Button {
                    retry()
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
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
        .environmentObject(AuthService())
        .environmentObject(SessionViewModel())
        .environmentObject(SessionSyncViewModel())
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
