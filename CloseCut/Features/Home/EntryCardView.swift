//
//  EntryCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct EntryCardView: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text("\(entry.type.displayName) • \(entry.watchContext.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    if entry.visibility == .circle {
                        Label("Circle", systemImage: "person.2.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Shared with Circle")
                    }

                    SyncBadge(status: entry.syncStatus)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.mood)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(entry.takeaway)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
                .accessibilityLabel("Tags \(entry.tags.joined(separator: ", "))")
            }

            HStack {
                Text(entry.watchedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Intensity \(entry.intensity)/5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.separator.opacity(0.4), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(entry.type.displayName), mood \(entry.mood), \(entry.takeaway)")
    }
}

#Preview {
    EntryCardView(
        entry: Entry(
            id: UUID().uuidString,
            ownerId: "preview-user",
            title: "Aftersun",
            type: .movie,
            mood: "Melancholic",
            takeaway: "Some memories hurt because they mattered.",
            quote: nil,
            tags: ["quiet", "memory", "fatherhood"],
            intensity: 5,
            watchContext: .home,
            cinemaAudio: nil,
            cinemaScreen: nil,
            cinemaComfort: nil,
            visibility: .privateOnly,
            watchedAt: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil,
            syncStatus: .pending
        )
    )
    .padding()
}
