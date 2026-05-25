//
//  Mood.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum Mood: String, CaseIterable, Identifiable, Codable {
    case heartbroken
    case moved
    case haunted
    case joyful
    case inspired
    case nostalgic
    case awestruck
    case unsettled
    case empty

    var id: String {
        rawValue
    }

    var label: String {
        switch self {
        case .heartbroken:
            return "Heartbroken"
        case .moved:
            return "Moved"
        case .haunted:
            return "Haunted"
        case .joyful:
            return "Joyful"
        case .inspired:
            return "Inspired"
        case .nostalgic:
            return "Nostalgic"
        case .awestruck:
            return "Awestruck"
        case .unsettled:
            return "Unsettled"
        case .empty:
            return "Empty"
        }
    }

    var emoji: String {
        switch self {
        case .heartbroken:
            return "💔"
        case .moved:
            return "🥺"
        case .haunted:
            return "👻"
        case .joyful:
            return "😄"
        case .inspired:
            return "✨"
        case .nostalgic:
            return "🌙"
        case .awestruck:
            return "🤩"
        case .unsettled:
            return "😶‍🌫️"
        case .empty:
            return "😶"
        }
    }

    var systemImage: String {
        switch self {
        case .heartbroken:
            return "heart.slash.fill"
        case .moved:
            return "heart.fill"
        case .haunted:
            return "moon.haze.fill"
        case .joyful:
            return "sun.max.fill"
        case .inspired:
            return "sparkles"
        case .nostalgic:
            return "moon.stars.fill"
        case .awestruck:
            return "star.fill"
        case .unsettled:
            return "cloud.fog.fill"
        case .empty:
            return "circle"
        }
    }

    var color: Color {
        switch self {
        case .heartbroken:
            return Color(hex: "#410E0D")
        case .moved:
            return Color(hex: "#0C2A4A")
        case .haunted:
            return Color(hex: "#2A1A3A")
        case .joyful:
            return Color(hex: "#2A1A0A")
        case .inspired:
            return Color(hex: "#1F2A1A")
        case .nostalgic:
            return Color(hex: "#1A2E1A")
        case .awestruck:
            return Color(hex: "#2A2000")
        case .unsettled:
            return Color(hex: "#1A1A2A")
        case .empty:
            return Color(hex: "#1C1C1E")
        }
    }

    var recommendationSignalWeight: Int {
        switch self {
        case .awestruck:
            return 5
        case .inspired:
            return 5
        case .moved:
            return 4
        case .joyful:
            return 4
        case .nostalgic:
            return 3
        case .heartbroken:
            return 2
        case .haunted:
            return 2
        case .unsettled:
            return 1
        case .empty:
            return 0
        }
    }

    var isStrongSignal: Bool {
        recommendationSignalWeight >= 4
    }

    var displayText: String {
        "\(emoji) \(label)"
    }

    static func from(_ value: String) -> Mood {
        let normalized = value
            .trimmed
            .lowercased()

        return Mood.allCases.first {
            $0.rawValue == normalized ||
            $0.label.lowercased() == normalized
        } ?? .empty
    }
}
