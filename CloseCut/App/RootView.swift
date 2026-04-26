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
    @Environment(\.modelContext) private var modelContext

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
    @EnvironmentObject private var authService: AuthService
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
                RootSignedInTestView(
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

private struct RootSignedInTestView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var entries: [LocalEntry]

    let user: AuthUser
    let profile: UserProfile

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("CloseCut")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Signed in as:")
                    .foregroundStyle(.secondary)

                Text(profile.displayName)
                    .font(.headline)

                Text(profile.email ?? user.id)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Local entries: \(entries.count)")
                    .foregroundStyle(.secondary)

                if let latestEntry = entries.first {
                    VStack(spacing: 4) {
                        Text("Latest: \(latestEntry.title)")
                            .font(.footnote)

                        Text("Tags: \(latestEntry.tags.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Status: \(latestEntry.syncStatusRaw)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }

                Button("Create test entry") {
                    createTestEntry()
                }
                .buttonStyle(.borderedProminent)

                Button("Sign Out") {
                    authService.signOut()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("CloseCut")
        }
    }

    private func createTestEntry() {
        let repository = EntryRepository()

        do {
            _ = try repository.createLocalEntry(
                ownerId: user.id,
                title: "Aftersun",
                type: .movie,
                mood: "Melancholic",
                takeaway: "Some memories hurt because they mattered.",
                quote: nil,
                tags: ["quiet", "memory", "fatherhood", "memory"],
                intensity: 5,
                watchContext: .home,
                cinemaAudio: nil,
                cinemaScreen: nil,
                cinemaComfort: nil,
                visibility: profile.defaultVisibility,
                watchedAt: Date(),
                modelContext: modelContext
            )
        } catch {
            print("Failed to create test entry via repository: \(error.localizedDescription)")
        }
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
