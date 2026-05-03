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

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Share with Circles")
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(CloseCutColors.textTertiary)
                    .textCase(.uppercase)

                Text("Your entry stays in your Personal Timeline. Selected Circles can view it later in their shared timeline.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if circles.isEmpty {
                Text("Create or join a Circle to share entries with trusted people.")
                    .font(.caption)
                    .foregroundStyle(CloseCutColors.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CloseCutColors.input)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(circles) { circle in
                        Button {
                            toggle(circle.id)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedCircleIds.contains(circle.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(selectedCircleIds.contains(circle.id) ? CloseCutColors.accentLight : CloseCutColors.textTertiary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(circle.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(CloseCutColors.textPrimary)
                                        .lineLimit(1)

                                    Text(circle.description?.isEmpty == false ? circle.description! : "\(max(circle.memberIds.count, 1)) members")
                                        .font(.caption)
                                        .foregroundStyle(CloseCutColors.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()
                            }
                            .padding(14)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
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

    private func toggle(_ circleId: String) {
        if selectedCircleIds.contains(circleId) {
            selectedCircleIds.remove(circleId)
        } else {
            selectedCircleIds.insert(circleId)
        }
    }
}
