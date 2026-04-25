//
//  RootView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocalEntry.watchedAt, order: .reverse) private var entries: [LocalEntry]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("CloseCut")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("Local entries: \(entries.count)")
                    .foregroundStyle(.secondary)

                Button("Create test entry") {
                    createTestEntry()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("CloseCut")
        }
    }

    private func createTestEntry() {
        let entry = LocalEntry(
            ownerId: "local-test-user",
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
        .modelContainer(for: [
            LocalEntry.self,
            LocalReaction.self,
            LocalComment.self,
            LocalCircle.self,
            LocalUserProfile.self,
            PendingAction.self
        ], inMemory: true)
}
