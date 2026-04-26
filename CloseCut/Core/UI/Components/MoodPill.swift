//
//  MoodPill.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum PillSize {
    case large
    case medium
    case small

    var font: Font {
        switch self {
        case .large: return .subheadline.weight(.semibold)
        case .medium: return .caption.weight(.semibold)
        case .small: return .caption2.weight(.semibold)
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .large: return 8
        case .medium: return 6
        case .small: return 4
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .large: return 12
        case .medium: return 10
        case .small: return 8
        }
    }
}

struct MoodPill: View {
    let mood: Mood
    var size: PillSize = .medium
    var isSelected: Bool = false
    var showLabel: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            Text(mood.emoji)

            if showLabel {
                Text(mood.label)
            }
        }
        .font(size.font)
        .foregroundStyle(.white)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(mood.color)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
        }
        .accessibilityLabel("Mood: \(mood.label)")
    }
}
