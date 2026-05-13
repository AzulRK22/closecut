//
//  QuickAddTMDBResultRow.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct QuickAddTMDBResultRow: View {
    let result: TMDBMediaSearchResult
    let state: QuickAddRowState
    let action: () -> Void

    private var isDisabled: Bool {
        state == .added || state == .duplicate
    }

    var body: some View {
        Button {
            guard isDisabled == false else {
                return
            }

            action()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                MediaPosterView(
                    posterPath: result.posterPath,
                    mediaType: result.mediaType,
                    width: 58,
                    height: 86,
                    cornerRadius: 12
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(CloseCutColors.textPrimary)
                                .lineLimit(2)

                            Text(result.subtitle)
                                .font(.caption)
                                .foregroundStyle(CloseCutColors.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer(minLength: 8)

                        statusIcon
                    }

                    if let overview = cleanOptional(result.overview) {
                        Text(overview)
                            .font(.caption)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if state == .normal {
                        Text("Preview")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(CloseCutColors.input)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(12)
            .background(CloseCutColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: state == .normal ? 0.5 : 1)
            }
            .opacity(isDisabled ? 0.72 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.title), \(result.subtitle), \(accessibilityState)")
    }

    private var statusIcon: some View {
        switch state {
        case .normal:
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)

        case .added:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(CloseCutColors.synced)

        case .duplicate:
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundStyle(CloseCutColors.textTertiary)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:
            return CloseCutColors.separator
        case .added:
            return CloseCutColors.synced.opacity(0.8)
        case .duplicate:
            return CloseCutColors.subtleBorder
        }
    }

    private var accessibilityState: String {
        switch state {
        case .normal:
            return "ready to preview"
        case .added:
            return "already added"
        case .duplicate:
            return "already in your history"
        }
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
