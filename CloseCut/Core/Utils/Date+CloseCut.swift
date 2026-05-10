//
//  Date+CloseCut.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 09/05/26.
//

import Foundation

extension Date {
    var closeCutShortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var closeCutShortDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var closeCutYear: Int {
        Calendar.current.component(.year, from: self)
    }

    func isWithinLastDays(_ days: Int) -> Bool {
        guard days > 0 else {
            return false
        }

        let threshold = Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        ) ?? Date()

        return self >= threshold
    }
}
