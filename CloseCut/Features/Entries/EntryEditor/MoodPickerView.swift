//
//  MoodPickerView.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

struct MoodPickerView: View {
    @Binding var selectedMood: Mood?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Mood.allCases) { mood in
                        moodButton(mood)
                    }
                }
                .padding(.vertical, 2)
            }

            if let selectedMood {
                Text("Selected: \(selectedMood.emoji) \(selectedMood.label)")
                    .font(.caption2)
                    .foregroundStyle(CloseCutColors.textTertiary)
            }
        }
    }

    private func moodButton(_ mood: Mood) -> some View {
        let isSelected = selectedMood == mood

        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                selectedMood = mood
            }
        } label: {
            MoodPill(
                mood: mood,
                size: .large,
                isSelected: isSelected,
                showLabel: true
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel("Mood \(mood.label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
