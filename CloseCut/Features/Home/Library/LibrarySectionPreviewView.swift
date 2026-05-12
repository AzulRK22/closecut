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

    var body: some View {
        if visibleEntries.isEmpty == false {
            VStack(alignment: .leading, spacing: 12) {
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
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(CloseCutColors.separator, lineWidth: 0.5)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textTertiary)
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
}
