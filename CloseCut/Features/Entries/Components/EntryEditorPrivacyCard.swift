//
//  EntryEditorPrivacyCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct EntryEditorPrivacyCard: View {
    let circles: [CloseCircle]
    @Binding var selectedCircleIds: Set<String>

    private var activeCircles: [CloseCircle] {
        circles
            .filter { $0.deletedAt == nil }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    private var isPrivate: Bool {
        selectedCircleIds.isEmpty
    }

    var body: some View {
        EntryEditorSectionCard(
            title: "Privacy",
            subtitle: "Your memory stays private unless you choose where else it belongs.",
            systemImage: isPrivate ? "lock.fill" : "person.2.fill"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                privacySummary

                if activeCircles.isEmpty {
                    emptyCircleState
                } else {
                    circlesList
                }
            }
        }
    }

    private var privacySummary: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isPrivate ? "lock.fill" : "person.2.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isPrivate ? CloseCutColors.textTertiary : CloseCutColors.accentLight)
                .frame(width: 34, height: 34)
                .background(CloseCutColors.input)
                .clipShape(SwiftUI.Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(summaryTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textPrimary)

                Text(summarySubtitle)
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(12)
        .background(CloseCutColors.input.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var summaryTitle: String {
        if selectedCircleIds.isEmpty {
            return "Private memory"
        }

        if selectedCircleIds.count == 1 {
            return "Shared with 1 Circle"
        }

        return "Shared with \(selectedCircleIds.count) Circles"
    }

    private var summarySubtitle: String {
        if selectedCircleIds.isEmpty {
            return "Only you can see this in your Personal library."
        }

        return "It remains in Personal and also appears in selected Circle timelines."
    }

    private var emptyCircleState: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Create or join a Circle before sharing memories with trusted people.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var circlesList: some View {
        VStack(spacing: 10) {
            ForEach(activeCircles) { circle in
                circleRow(circle)
            }
        }
    }

    private func circleRow(_ circle: CloseCircle) -> some View {
        let isSelected = selectedCircleIds.contains(circle.id)

        return Button {
            toggle(circle.id)
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(isSelected ? CloseCutColors.accent : CloseCutColors.input)
                        .frame(width: 30, height: 30)

                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isSelected ? .white : CloseCutColors.textTertiary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(circle.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Text(subtitle(for: circle))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Text("On")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CloseCutColors.card)
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accentLight : Color.clear, lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(circle.name), \(isSelected ? "selected" : "not selected")")
    }

    private func subtitle(for circle: CloseCircle) -> String {
        if let description = circle.description?.trimmingCharacters(in: .whitespacesAndNewlines),
           description.isEmpty == false {
            return description
        }

        let count = max(circle.memberIds.count, 1)
        return count == 1 ? "1 member" : "\(count) members"
    }

    private func toggle(_ circleId: String) {
        let cleanedCircleId = circleId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedCircleId.isEmpty == false else {
            return
        }

        withAnimation(.easeInOut(duration: 0.16)) {
            if selectedCircleIds.contains(cleanedCircleId) {
                selectedCircleIds.remove(cleanedCircleId)
            } else {
                selectedCircleIds.insert(cleanedCircleId)
            }
        }
    }
}
