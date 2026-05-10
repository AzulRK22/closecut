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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Mood.allCases) { mood in
                    Button {
                        selectedMood = mood
                    } label: {
                        MoodPill(
                            mood: mood,
                            size: .large,
                            isSelected: selectedMood == mood,
                            showLabel: true
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Mood \(mood.label)")
                    .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
    }
}
