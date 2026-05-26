//
//  CloseCutSpacing.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import CoreGraphics

enum CloseCutSpacing {
    static let zero: CGFloat = 0

    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 40

    // MARK: - Screen

    static let screenHorizontalPadding: CGFloat = 20
    static let screenTopPadding: CGFloat = 16
    static let screenBottomPadding: CGFloat = 24

    // MARK: - Cards / Sections

    static let cardPadding: CGFloat = 16
    static let heroCardPadding: CGFloat = 18
    static let compactCardPadding: CGFloat = 12

    static let sectionSpacing: CGFloat = 18
    static let sectionHeaderSpacing: CGFloat = 10
    static let rowSpacing: CGFloat = 12
    static let listRowSpacing: CGFloat = 10

    // MARK: - Forms

    static let formSpacing: CGFloat = 24
    static let fieldSpacing: CGFloat = 12
    static let fieldPadding: CGFloat = 14

    // MARK: - Bottom Bars

    static let stickyFooterTopPadding: CGFloat = 12
    static let stickyFooterBottomPadding: CGFloat = 16
}
