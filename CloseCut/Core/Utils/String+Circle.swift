//
//  String+Circle.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 01/05/26.
//

import Foundation

extension String {
    var normalizedInviteCode: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}
