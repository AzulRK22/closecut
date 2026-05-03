//
//  CircleEntryReadOnlyDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleEntryReadOnlyDetailView: View {
    let entry: Entry
    let currentUserId: String

    private var sharedByText: String {
        entry.ownerId == currentUserId ? "Shared by you" : "Shared by Circle member"
    }

    private var subtitle: String {
        var parts: [String] = []

        if let releaseYear = entry.releaseYear {
            parts.append("\(releaseYear)")
        }

        parts.append(entry.type.displayName)

        if entry.sourceType == .quickAdd {
            parts.append("Quick Add")
        }

        return parts.joined(separator: " • ")
    }

    private var moodText: String {
        if entry.mood.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return entry.quickSentiment?.displayName ?? "Shared memory"
        }

        return entry.mood
    }

    private var takeawayText: String {
        if entry.takeaway.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No takeaway was added."
        }

        return entry.takeaway
    }

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    DetailSectionCard(title: "Memory") {
                        VStack(alignment: .leading, spacing: 12) {
                            DetailInfoRow(label: "Mood", value: moodText)

                            DetailInfoRow(
                                label: "Watched",
                                value: entry.watchedAt.formatted(date: .abbreviated, time: .omitted)
                            )

                            DetailInfoRow(
                                label: "Context",
                                value: entry.watchContext.displayName
                            )
                        }
                    }

                    DetailSectionCard(title: "Takeaway") {
                        Text(takeawayText)
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let quote = entry.quote,
                       quote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        DetailSectionCard(title: "Key moment") {
                            Text("“\(quote)”")
                                .font(.subheadline)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if entry.tags.isEmpty == false {
                        DetailSectionCard(title: "Tags") {
                            let columns = [
                                GridItem(.adaptive(minimum: 80), spacing: 8)
                            ]

                            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(CloseCutColors.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(CloseCutColors.input)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    DetailSectionCard(title: "Circle access") {
                        HStack(spacing: 8) {
                            Image(systemName: "eye")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textTertiary)

                            Text("This shared entry is read-only inside Circle.")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Shared entry")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sharedByText)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(CloseCutColors.accentLight)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(entry.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(CloseCutColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(CloseCutColors.textSecondary)

            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("Personal entry shared with this Circle")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}
