//
//  CloseCutTypography.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import SwiftUI

enum CloseCutTypography {
    // MARK: - Display

    static let heroTitle: Font = .largeTitle.weight(.semibold)
    static let screenTitle: Font = .title2.weight(.semibold)
    static let sheetTitle: Font = .title3.weight(.semibold)

    // MARK: - Sections / Cards

    static let sectionTitle: Font = .headline.weight(.semibold)
    static let sectionEyebrow: Font = .caption2.weight(.semibold)
    static let cardTitle: Font = .subheadline.weight(.semibold)
    static let cardTitleLarge: Font = .headline.weight(.semibold)

    // MARK: - Body

    static let body: Font = .body
    static let bodyEmphasis: Font = .body.weight(.semibold)
    static let secondary: Font = .subheadline
    static let secondaryEmphasis: Font = .subheadline.weight(.semibold)

    // MARK: - Metadata

    static let caption: Font = .caption
    static let captionEmphasis: Font = .caption.weight(.semibold)
    static let micro: Font = .caption2
    static let microEmphasis: Font = .caption2.weight(.semibold)

    // MARK: - Actions

    static let button: Font = .subheadline.weight(.semibold)
    static let largeButton: Font = .headline.weight(.semibold)
    static let smallButton: Font = .caption.weight(.semibold)

    // MARK: - Utility

    static let statValue: Font = .title3.weight(.semibold)
    static let statLabel: Font = .caption2.weight(.semibold)
}
