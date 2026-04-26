//
//  Array+Uniqued.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

//
//  Array+Uniqued.swift
//  CloseCut
//

import Foundation

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()

        return filter { element in
            if seen.contains(element) {
                return false
            } else {
                seen.insert(element)
                return true
            }
        }
    }
}
