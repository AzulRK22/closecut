//
//  LibrarySectionPreviewView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct LibrarySectionPreviewView: View {
    let title: String
    let subtitle: String?
    let entries: [Entry]
    let user: AuthUser
    let profile: UserProfile
    var maxVisibleItems: Int = 4
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    private var visibleEntries: [Entry] {
        Array(
            entries
                .filter { $0.deletedAt == nil }
                .prefix(maxVisibleItems)
        )
    }

    private var countText: String {
        entries.count == 1 ? "1 memory" : "\(entries.count) memories"
    }

    var body: some View {
        if visibleEntries.isEmpty == false {
            VStack(alignment: .leading, spacing: 13) {
                header

                VStack(spacing: 10) {
                    ForEach(visibleEntries) { entry in
                        NavigationLink {
                            EntryDetailView(
                                entry: entry,
                                user: user,
                                profile: profile
                            )
                        } label: {
                            CompactEntryRowView(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .background(sectionBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    Text(countText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CloseCutColors.input.opacity(0.75))
                        .clipShape(Capsule())
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            if let actionTitle,
               let action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(CloseCutColors.input)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sectionBackground: some View {
        ZStack {
            CloseCutColors.card

            LinearGradient(
                colors: [
                    CloseCutColors.accent.opacity(0.05),
                    CloseCutColors.card.opacity(0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
