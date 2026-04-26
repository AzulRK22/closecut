//
//  HomeSegment.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

enum HomeSegment: String, CaseIterable, Identifiable {
    case timeline
    case quickPick

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timeline:
            return "Timeline"
        case .quickPick:
            return "QuickPick"
        }
    }
}
