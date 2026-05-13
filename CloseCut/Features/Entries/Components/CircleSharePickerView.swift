//
//  CircleSharePickerView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/05/26.
//

import SwiftUI

struct CircleSharePickerView: View {
    let circles: [CloseCircle]
    @Binding var selectedCircleIds: Set<String>

    private var activeCircles: [CloseCircle] {
        circles
            .filter { $0.deletedAt == nil }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if activeCircles.isEmpty {
                emptyState
            } else {
                circlesList
            }
        }
        .padding(16)
        .background(CloseCutColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(CloseCutColors.separator, lineWidth: 0.5)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Share with Circles")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(CloseCutColors.textTertiary)
                .textCase(.uppercase)

            Text("This memory stays in your Personal Timeline. Only the Circles you select can see this entry in their shared timeline. You can change this later.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("Create or join a Circle to share entries with trusted people.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isSelected ? CloseCutColors.accentLight : CloseCutColors.textTertiary)
                    .frame(width: 24, height: 24)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineLimit(1)

                    Text(subtitle(for: circle))
                        .font(.caption)
                        .foregroundStyle(CloseCutColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Text("Shared")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.accentLight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(CloseCutColors.card)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(CloseCutColors.input)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? CloseCutColors.accentLight : Color.clear, lineWidth: 0.8)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(circle.name), \(subtitle(for: circle)), \(isSelected ? "selected" : "not selected")")
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

        if selectedCircleIds.contains(cleanedCircleId) {
            selectedCircleIds.remove(cleanedCircleId)
        } else {
            selectedCircleIds.insert(cleanedCircleId)
        }
    }
}
