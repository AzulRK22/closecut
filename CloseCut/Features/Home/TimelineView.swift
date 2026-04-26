//
//  TimelineView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct TimelineView: View {
    let entries: [Entry]
    let onCreateEntry: () -> Void

    var body: some View {
        Group {
            if entries.isEmpty {
                EmptyStateView(
                    title: "Nothing here yet",
                    message: "Tap + to log your first watch.",
                    systemImage: "film.stack",
                    actionTitle: "Log a film",
                    action: onCreateEntry
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            EntryCardView(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(CloseCutColors.backgroundPrimary)
    }
}

#Preview {
    TimelineView(
        entries: [],
        onCreateEntry: {}
    )
}
