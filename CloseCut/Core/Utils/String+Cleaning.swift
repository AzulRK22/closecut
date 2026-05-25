//
//  String+Cleaning.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 09/05/26.
//

import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfBlank: String? {
        let cleaned = trimmed
        return cleaned.isEmpty ? nil : cleaned
    }

    var nilIfEmpty: String? {
        nilIfBlank
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }
}

extension Optional where Wrapped == String {
    var trimmedOrNil: String? {
        guard let value = self else {
            return nil
        }

        return value.nilIfBlank
    }

    var trimmedOrEmpty: String {
        self?.trimmed ?? ""
    }
}
