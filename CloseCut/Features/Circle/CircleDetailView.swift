//
//  CircleDetailView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import SwiftUI

private enum CircleDetailSegment: String, CaseIterable, Identifiable {
    case timeline
    case quickPick
    case members

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline:
            return "Timeline"
        case .quickPick:
            return "QuickPick"
        case .members:
            return "Members"
        }
    }
}

struct CircleDetailView: View {
    let circle: CloseCircle
    let membership: CircleMembership

    @State private var selectedSegment: CircleDetailSegment = .timeline
    @State private var copiedInviteCode = false

    var body: some View {
        ZStack {
            CloseCutColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    Picker("Circle detail section", selection: $selectedSegment) {
                        ForEach(CircleDetailSegment.allCases) { segment in
                            Text(segment.title)
                                .tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)

                    selectedContent

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(circle.name)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(circle.name)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)

                    if let description = circle.description,
                       description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("A private Circle for shared watch memories.")
                            .font(.subheadline)
                            .foregroundStyle(CloseCutColors.textSecondary)
                    }
                }

                Spacer()

                Text(membership.role.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(membership.isOwner ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(CloseCutColors.input)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Label("\(circle.memberIds.count) members", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("•")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Text("Owner: \(circle.ownerDisplayName)")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }

            HStack {
                Text(circle.inviteCode)
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Spacer()

                Button {
                    UIPasteboard.general.string = circle.inviteCode
                    copiedInviteCode = true
                } label: {
                    Image(systemName: copiedInviteCode ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Copy invite code")
            }
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedSegment {
        case .timeline:
            EmptyStateView(
                title: "Nothing shared yet",
                message: "Shared entries for this Circle will appear here.",
                systemImage: "film.stack",
                actionTitle: nil,
                action: nil
            )

        case .quickPick:
            EmptyStateView(
                title: "Not enough group history yet",
                message: "Group QuickPick will use entries shared with this Circle.",
                systemImage: "sparkles",
                actionTitle: nil,
                action: nil
            )

        case .members:
            DetailSectionCard(title: "Members") {
                VStack(spacing: 8) {
                    DetailInfoRow(
                        label: "Owner",
                        value: circle.ownerDisplayName
                    )

                    DetailInfoRow(
                        label: "Total members",
                        value: "\(circle.memberIds.count)"
                    )

                    Text("Full member list and management will be connected next.")
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
