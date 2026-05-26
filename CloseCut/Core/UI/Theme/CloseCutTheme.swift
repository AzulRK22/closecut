//
//  CloseCutTheme.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum CloseCutTheme {
    enum Radius {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let hero: CGFloat = 24
        static let sheet: CGFloat = 28
        static let pill: CGFloat = 999
    }

    enum Size {
        static let iconTiny: CGFloat = 24
        static let iconSmall: CGFloat = 30
        static let iconMedium: CGFloat = 38
        static let iconLarge: CGFloat = 48
        static let iconHero: CGFloat = 50

        static let buttonHeight: CGFloat = 46
        static let largeButtonHeight: CGFloat = 52
        static let compactButtonHeight: CGFloat = 38

        static let posterTinyWidth: CGFloat = 42
        static let posterTinyHeight: CGFloat = 62

        static let posterSmallWidth: CGFloat = 54
        static let posterSmallHeight: CGFloat = 80

        static let posterMediumWidth: CGFloat = 72
        static let posterMediumHeight: CGFloat = 108

        static let posterLargeWidth: CGFloat = 94
        static let posterLargeHeight: CGFloat = 138
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.18)
        static let softCardColor = Color.black.opacity(0.12)
        static let accentColor = CloseCutColors.accent.opacity(0.25)

        static let softRadius: CGFloat = 12
        static let mediumRadius: CGFloat = 18
        static let strongRadius: CGFloat = 24

        static let softYOffset: CGFloat = 6
        static let mediumYOffset: CGFloat = 10
        static let strongYOffset: CGFloat = 14
    }

    enum Opacity {
        static let disabled: Double = 0.58
        static let secondary: Double = 0.72
        static let pressed: Double = 0.86
        static let subtle: Double = 0.10
        static let selected: Double = 0.14
    }

    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.18)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.22)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.32)
        static let spring = SwiftUI.Animation.spring(response: 0.32, dampingFraction: 0.86)
    }

    enum Layout {
        static let maxReadableWidth: CGFloat = 560
        static let maxCardWidth: CGFloat = 620
    }
}
