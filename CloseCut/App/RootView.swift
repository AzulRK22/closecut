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

    var body: some View {
        switch authService.authState {
        case .loading:
            LoadingAuthView()

        case .signedOut:
            AuthView()
                .onAppear {
                    sessionViewModel.reset()
                }

        case .signedIn(let user):
            SignedInSessionGate(user: user)

        case .error:
            AuthView()
        }
    }
}

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
                        await sessionViewModel.prepareSession(
                            authUser: user,
                            modelContext: modelContext
                        )
                    }

            case .loading:
                LoadingProfileView()

            case .ready(let profile):
                MainTabView(
                    user: user,
                    profile: profile
                )

            case .error(let message):
                ProfileErrorView(message: message) {
                    Task {
                        await sessionViewModel.prepareSession(
                            authUser: user,
                            modelContext: modelContext
                        )
                    }
                }
            }
        }
    }
}

private struct LoadingAuthView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()

            Text("Preparing CloseCut")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing CloseCut")
    }
}

private struct LoadingProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()

            Text("Preparing your profile")
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing your profile")
    }
}

private struct ProfileErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)

            Text("We couldn't prepare your profile.")
                .font(.headline)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    RootView()
        .environmentObject(AuthService())
        .environmentObject(SessionViewModel())
        .modelContainer(for: [
            LocalEntry.self,
            LocalReaction.self,
            LocalComment.self,
            LocalCircle.self,
            LocalUserProfile.self,
            PendingAction.self
        ], inMemory: true)
}
