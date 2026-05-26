//
//  Color+Hex.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        self = Color.fromHex(hex) ?? .clear
    }

    static func fromHex(_ hex: String) -> Color? {
        let cleanedHex = hex
            .trimmed
            .replacingOccurrences(of: "#", with: "")

        let expandedHex: String

        if cleanedHex.count == 3 {
            expandedHex = cleanedHex.map { "\($0)\($0)" }.joined()
        } else {
            expandedHex = cleanedHex
        }

        guard expandedHex.count == 6 || expandedHex.count == 8 else {
            #if DEBUG
            print("⚠️ Invalid hex color length:", hex)
            #endif
            return nil
        }

        var value: UInt64 = 0
        let scanner = Scanner(string: expandedHex)

        guard scanner.scanHexInt64(&value) else {
            #if DEBUG
            print("⚠️ Invalid hex color value:", hex)
            #endif
            return nil
        }

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if expandedHex.count == 8 {
            red = Double((value >> 24) & 0xFF) / 255.0
            green = Double((value >> 16) & 0xFF) / 255.0
            blue = Double((value >> 8) & 0xFF) / 255.0
            alpha = Double(value & 0xFF) / 255.0
        } else {
            red = Double((value >> 16) & 0xFF) / 255.0
            green = Double((value >> 8) & 0xFF) / 255.0
            blue = Double(value & 0xFF) / 255.0
            alpha = 1.0
        }

        return Color(
            red: red,
            green: green,
            blue: blue,
            opacity: alpha
        )
    }
}
