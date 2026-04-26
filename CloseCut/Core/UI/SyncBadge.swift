//
//  SyncBadge.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct SyncBadge: View {
    let status: SyncStatus

    var body: some View {
        switch status {
        case .synced:
            EmptyView()

        case .pending:
            Label("Pending Sync", systemImage: "clock")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .accessibilityLabel("Pending sync")

        case .failed:
            Label("Sync Failed", systemImage: "exclamationmark.triangle")
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(Capsule())
                .accessibilityLabel("Sync failed")
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SyncBadge(status: .synced)
        SyncBadge(status: .pending)
        SyncBadge(status: .failed)
    }
    .padding()
}
