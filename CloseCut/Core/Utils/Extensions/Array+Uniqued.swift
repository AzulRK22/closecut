//
//  Array+Uniqued.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()

        return filter { element in
            seen.insert(element).inserted
        }
    }
}

extension Array {
    func uniqued<Key: Hashable>(
        by keyPath: KeyPath<Element, Key>
    ) -> [Element] {
        uniqued { element in
            element[keyPath: keyPath]
        }
    }

    func uniqued<Key: Hashable>(
        by keyProvider: (Element) -> Key
    ) -> [Element] {
        var seen = Set<Key>()

        return filter { element in
            seen.insert(keyProvider(element)).inserted
        }
    }
}
