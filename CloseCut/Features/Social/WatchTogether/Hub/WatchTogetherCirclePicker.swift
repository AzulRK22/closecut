//
//  WatchTogetherCirclePicker.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 03/06/26.
//

import SwiftUI

struct WatchTogetherCirclePicker: View {
    let circleRows: [(circle: CloseCircle, membership: CircleMembership)]
    @Binding var selectedCircleId: String?

    private var selectedCircle: CloseCircle? {
        guard let selectedCircleId else {
            return circleRows.first?.circle
        }

        return circleRows.first { $0.circle.id == selectedCircleId }?.circle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WatchTogetherSectionHeader(
                title: "Viewing plans for",
                subtitle: "Switch Circles without leaving the Social tab.",
                trailing: circleRows.isEmpty ? nil : "\(circleRows.count)"
            )

            if circleRows.isEmpty {
                emptyPicker
            } else {
                Menu {
                    ForEach(circleRows, id: \.membership.id) { row in
                        Button {
                            selectedCircleId = row.circle.id
                        } label: {
                            Label(
                                row.circle.displayName,
                                systemImage: row.membership.isOwner ? "crown.fill" : "person.2.fill"
                            )
                        }
                    }
                } label: {
                    pickerLabel
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pickerLabel: some View {
        HStack(spacing: 12) {
            avatar

            VStack(alignment: .leading, spacing: 3) {
                Text(selectedCircle?.displayName ?? "Select Circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)
                    .lineLimit(1)

                Text(selectedCircleSubtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var avatar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(CloseCutColors.accent.opacity(0.16))
                .frame(width: 42, height: 42)

            Text(selectedCircleInitials)
                .font(.caption.weight(.bold))
                .foregroundStyle(CloseCutColors.accentLight)
        }
    }

    private var selectedCircleSubtitle: String {
        guard let selectedCircle else {
            return "No Circle selected"
        }

        let memberCount = max(selectedCircle.memberIds.count, 1)
        return memberCount == 1 ? "1 member" : "\(memberCount) members"
    }

    private var selectedCircleInitials: String {
        guard let selectedCircle else {
            return "CC"
        }

        let words = selectedCircle.displayName
            .split(separator: " ")
            .map(String.init)

        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }

        return String(selectedCircle.displayName.prefix(2)).uppercased()
    }

    private var emptyPicker: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Create or join a Circle to start planning watches with other people.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }
}

