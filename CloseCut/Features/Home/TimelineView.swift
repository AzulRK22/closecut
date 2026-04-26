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
                    title: "No entries yet",
                    message: "Start with the movie or series that stayed with you most recently.",
                    systemImage: "film",
                    actionTitle: "Create Entry",
                    action: onCreateEntry
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(entries) { entry in
                            EntryCardView(entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }
}

#Preview {
    TimelineView(
        entries: [],
        onCreateEntry: {}
    )
}
