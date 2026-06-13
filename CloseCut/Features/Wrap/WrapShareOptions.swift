//
//  WrapShareOptions.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 12/06/26.
//

import Foundation

struct WrapShareOptions: Equatable {
    var includeWatchedCount: Bool = true
    var includeMediaSplit: Bool = true
    var includeTopGenres: Bool = true
    var includeMoodSignal: Bool = true
    var includeTopTitle: Bool = false
    var includePosterStrip: Bool = false
    var includeBranding: Bool = true

    static let privacySafeDefault = WrapShareOptions()
}
