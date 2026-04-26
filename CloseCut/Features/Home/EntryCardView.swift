//
//  EntryCardView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum EntryCardVariant {
    case timeline
    case circle
}

struct EntryCardView: View {
    let entry: Entry
    var variant: EntryCardVariant = .timeline
    var onTap: (() -> Void)? = nil

    private var mood: Mood {
        Mood.from(entry.mood)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(CloseCutColors.card)

                mood.color
                    .frame(width: 3)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: 16
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(entry.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(CloseCutColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        MoodPill(
                            mood: mood,
                            size: .small,
                            showLabel: false
                        )
                    }

                    Text(entry.takeaway)
                        .font(.subheadline)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        Label(entry.watchContext.displayName, systemImage: entry.watchContext == .cinema ? "popcorn" : "house")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)

                        Text(entry.watchedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)

                        Spacer()

                        if entry.visibility == .circle {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.accentLight)
                                .accessibilityLabel("Shared with Circle")
                        }

                        PendingSyncBadge(status: entry.syncStatus)
                    }
                }
                .padding(16)
                .padding(.leading, 3)
            }
            .frame(minHeight: variant == .timeline ? 148 : 128)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), feeling \(mood.label), \(entry.watchedAt.formatted(date: .abbreviated, time: .omitted))")
    }
}
