//
//  EntryDetailMemoryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/05/26.
//

import SwiftUI

struct EntryDetailMemoryCard: View {
    let entry: Entry
    let onCompleteMemory: () -> Void

    private var hasTakeaway: Bool {
        cleanOptional(entry.takeaway) != nil
    }

    private var isQuickAdd: Bool {
        entry.sourceType == .quickAdd
    }

    var body: some View {
        EntryDetailSectionCard(
            title: "Memory",
            subtitle: "The part that makes this more than a watch log.",
            systemImage: "sparkles"
        ) {
            VStack(alignment: .leading, spacing: 14) {
                if let takeaway = cleanOptional(entry.takeaway) {
                    Text(takeaway)
                        .font(.body.italic())
                        .foregroundStyle(CloseCutColors.textPrimary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    emptyTakeaway
                }

                if isQuickAdd || hasTakeaway == false {
                    Button {
                        onCompleteMemory()
                    } label: {
                        Text(isQuickAdd ? "Complete memory" : "Add memory")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CloseCutColors.accentLight)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(CloseCutColors.input)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyTakeaway: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "quote.opening")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textTertiary)
                .padding(.top, 2)

            Text("No personal memory added yet. Add what stayed with you, why it mattered, or the feeling you want to remember.")
                .font(.caption)
                .foregroundStyle(CloseCutColors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(CloseCutColors.input)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}
