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

    var id: String { rawValue }

    var label: String {
        switch self {
        case .heartbroken: return "Heartbroken"
        case .moved: return "Moved"
        case .haunted: return "Haunted"
        case .joyful: return "Joyful"
        case .inspired: return "Inspired"
        case .nostalgic: return "Nostalgic"
        case .awestruck: return "Awestruck"
        case .unsettled: return "Unsettled"
        case .empty: return "Empty"
        }
    }

    var emoji: String {
        switch self {
        case .heartbroken: return "💔"
        case .moved: return "🥺"
        case .haunted: return "👻"
        case .joyful: return "😄"
        case .inspired: return "✨"
        case .nostalgic: return "🌙"
        case .awestruck: return "🤩"
        case .unsettled: return "😶‍🌫️"
        case .empty: return "😶"
        }
    }

    var color: Color {
        switch self {
        case .heartbroken: return Color(hex: "#410E0D")
        case .moved: return Color(hex: "#0C2A4A")
        case .haunted: return Color(hex: "#2A1A3A")
        case .joyful: return Color(hex: "#2A1A0A")
        case .inspired: return Color(hex: "#1F2A1A")
        case .nostalgic: return Color(hex: "#1A2E1A")
        case .awestruck: return Color(hex: "#2A2000")
        case .unsettled: return Color(hex: "#1A1A2A")
        case .empty: return Color(hex: "#1C1C1E")
        }
    }

    static func from(_ value: String) -> Mood {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return Mood.allCases.first {
            $0.rawValue == normalized || $0.label.lowercased() == normalized
        } ?? .empty
    }
}
