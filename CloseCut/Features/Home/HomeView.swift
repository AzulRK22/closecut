//
//  HomeView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \LocalEntry.watchedAt, order: .reverse)
    private var localEntries: [LocalEntry]

    let user: AuthUser
    let profile: UserProfile

    @State private var selectedSegment: HomeSegment = .timeline

    private var entries: [Entry] {
        localEntries
            .filter { $0.ownerId == user.id }
            .filter { $0.deletedAt == nil }
            .map { $0.domain }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Home section", selection: $selectedSegment) {
                    ForEach(HomeSegment.allCases) { segment in
                        Text(segment.title)
                            .tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 8)

                switch selectedSegment {
                case .timeline:
                    TimelineView(
                        entries: entries,
                        onCreateEntry: createTestEntry
                    )

                case .quickPick:
                    EmptyStateView(
                        title: "QuickPick is coming",
                        message: "Soon this will suggest what to watch using your history and Circle signals.",
                        systemImage: "sparkles"
                    )
                }
            }
            .navigationTitle("CloseCut")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hi, \(profile.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        createTestEntry()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Create test entry")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authService.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    .accessibilityLabel("Sign out")
                }
            }
        }
    }

    private func createTestEntry() {
        let repository = EntryRepository()

        do {
            _ = try repository.createLocalEntry(
                ownerId: user.id,
                title: sampleTitle(),
                type: .movie,
                mood: sampleMood(),
                takeaway: sampleTakeaway(),
                quote: nil,
                tags: ["quiet", "memory", "cinema", "memory"],
                intensity: Int.random(in: 1...5),
                watchContext: Bool.random() ? .home : .cinema,
                cinemaAudio: 4,
                cinemaScreen: 5,
                cinemaComfort: 4,
                visibility: profile.defaultVisibility,
                watchedAt: Date(),
                modelContext: modelContext
            )
        } catch {
            print("Failed to create test entry: \(error.localizedDescription)")
        }
    }

    private func sampleTitle() -> String {
        [
            "Aftersun",
            "Past Lives",
            "Arrival",
            "The Bear",
            "Little Women",
            "Her",
            "Lost in Translation"
        ].randomElement() ?? "Aftersun"
    }

    private func sampleMood() -> String {
        [
            "Melancholic",
            "Soft",
            "Inspired",
            "Heavy",
            "Comforted",
            "Reflective"
        ].randomElement() ?? "Reflective"
    }

    private func sampleTakeaway() -> String {
        [
            "Some memories hurt because they mattered.",
            "It stayed with me more than I expected.",
            "Quiet stories can hit the hardest.",
            "A reminder that timing changes everything.",
            "It felt like a conversation I needed today."
        ].randomElement() ?? "It stayed with me."
    }
}

#Preview {
    HomeView(
        user: AuthUser(
            id: "preview-user",
            email: "preview@closecut.dev",
            displayName: "Preview",
            photoURL: nil
        ),
        profile: UserProfile(
            id: "preview-user",
            displayName: "Preview",
            email: "preview@closecut.dev",
            photoURL: nil,
            circleId: nil,
            defaultVisibility: .privateOnly,
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .synced
        )
    )
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
