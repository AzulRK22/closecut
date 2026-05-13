//
//  EntryMemoryCard.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 11/05/26.
//

import SwiftUI

struct EntryMemoryCard: View {
    @Binding var selectedMood: Mood?
    @Binding var takeaway: String
    let errors: [String]

    @FocusState.Binding var focusedField: EntryEditorFocusField?

    private var hasMoodError: Bool {
        errors.contains("Choose a mood.")
    }

    private var takeawayBorderColor: Color {
        takeaway.count > EntryValidation.maxTakeawayLength
            ? CloseCutColors.failed
            : CloseCutColors.separator
    }

    var body: some View {
        EntryEditorSectionCard(
            title: "Memory",
            subtitle: "Capture what it felt like and what stayed with you.",
            systemImage: "sparkles"
        ) {
            VStack(alignment: .leading, spacing: 18) {
                feelingSection

                takeawaySection
            }
        }
    }

    private var feelingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Feeling")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CloseCutColors.textSecondary)

                Spacer()

                if hasMoodError {
                    Text("Required")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CloseCutColors.failed)
                }
            }

            MoodPickerView(selectedMood: $selectedMood)

            if hasMoodError {
                Text("Choose the emotional tone that best matches this memory.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.failed)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var takeawaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you want to remember?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(CloseCutColors.textSecondary)

            TextEditor(text: $takeaway)
                .focused($focusedField, equals: .takeaway)
                .font(.body)
                .foregroundStyle(CloseCutColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 104)
                .padding(12)
                .background(CloseCutColors.input)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(takeawayBorderColor, lineWidth: 0.5)
                }
                .overlay(alignment: .topLeading) {
                    if takeaway.isEmpty {
                        Text("A thought, feeling, scene, or memory…")
                            .font(.body)
                            .foregroundStyle(CloseCutColors.textTertiary)
                            .padding(.horizontal, 17)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: takeaway) { _, newValue in
                    if newValue.count > EntryValidation.maxTakeawayLength {
                        takeaway = String(newValue.prefix(EntryValidation.maxTakeawayLength))
                    }
                }

            HStack {
                Text("Optional, but this is what makes CloseCut yours.")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)

                Spacer()

                Text("\(takeaway.count)/\(EntryValidation.maxTakeawayLength)")
                    .font(.caption2)
                    .foregroundStyle(
                        takeaway.count > EntryValidation.maxTakeawayLength
                        ? CloseCutColors.failed
                        : CloseCutColors.textTertiary
                    )
            }
        }
    }
}
