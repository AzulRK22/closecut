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

    var body: some View {
        switch authService.authState {
        case .loading:
            LoadingAuthView()

        case .signedOut:
            AuthView()

        case .signedIn(let user):
            RootSignedInTestView(user: user)

        case .error:
            AuthView()
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

private struct RootSignedInTestView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var entries: [LocalEntry]

    let user: AuthUser

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("CloseCut")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Signed in as:")
                    .foregroundStyle(.secondary)

                Text(user.email ?? user.id)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Local entries: \(entries.count)")
                    .foregroundStyle(.secondary)

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
        let entry = LocalEntry(
            ownerId: user.id,
            title: "Aftersun",
            type: .movie,
            mood: "Melancholic",
            takeaway: "Some memories hurt because they mattered.",
            quote: nil,
            tags: ["quiet", "memory", "fatherhood"],
            intensity: 5,
            watchContext: .home,
            visibility: .privateOnly,
            syncStatus: .pending
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save test entry: \(error)")
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthService())
        .modelContainer(for: [
            LocalEntry.self,
            LocalReaction.self,
            LocalComment.self,
            LocalCircle.self,
            LocalUserProfile.self,
            PendingAction.self
        ], inMemory: true)
}
