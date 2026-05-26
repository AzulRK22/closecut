//
//  Collection+Safe.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 09/05/26.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
