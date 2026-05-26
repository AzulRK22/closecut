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

    var isNotBlank: Bool {
        isBlank == false
    }

    var lowercasedTrimmed: String {
        trimmed.lowercased()
    }

    func limited(to maxLength: Int) -> String {
        guard maxLength > 0 else {
            return ""
        }

        let cleaned = trimmed

        guard cleaned.count > maxLength else {
            return cleaned
        }

        return String(cleaned.prefix(maxLength))
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

    var isNilOrBlank: Bool {
        trimmedOrNil == nil
    }
}
