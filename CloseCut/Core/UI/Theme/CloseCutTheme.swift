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
        static let lg: CGFloat = 18
        static let xl: CGFloat = 22
        static let xxl: CGFloat = 24
    }

    enum Size {
        static let iconSmall: CGFloat = 28
        static let iconMedium: CGFloat = 36
        static let iconLarge: CGFloat = 48

        static let buttonHeight: CGFloat = 46
        static let largeButtonHeight: CGFloat = 50

        static let posterSmallWidth: CGFloat = 54
        static let posterSmallHeight: CGFloat = 80

        static let posterMediumWidth: CGFloat = 72
        static let posterMediumHeight: CGFloat = 108
    }

    enum Shadow {
        static let cardColor = Color.black.opacity(0.18)
        static let accentColor = CloseCutColors.accent.opacity(0.25)

        static let softRadius: CGFloat = 12
        static let mediumRadius: CGFloat = 18
    }
}
