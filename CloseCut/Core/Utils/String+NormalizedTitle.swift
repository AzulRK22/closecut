//
//  String+NormalizedTitle.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 27/04/26.
//

import Foundation

extension String {
    var normalizedTitleKey: String {
        self
            .lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
