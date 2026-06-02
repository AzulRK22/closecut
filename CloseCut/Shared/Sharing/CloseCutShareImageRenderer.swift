//
//  CloseCutShareImageRenderer.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import SwiftUI
import UIKit

@MainActor
enum CloseCutShareImageRenderer {

    static func renderShareCard(
        item: CloseCutShareItem,
        scale: CGFloat? = nil
    ) -> UIImage? {
        let resolvedScale = scale ?? UIScreen.main.scale

        let view = CloseCutShareCardSnapshotView(item: item)
            .preferredColorScheme(.dark)

        let renderer = ImageRenderer(content: view)
        renderer.scale = resolvedScale
        renderer.isOpaque = true

        return renderer.uiImage
    }

    static func renderShareCardPNGData(
        item: CloseCutShareItem,
        scale: CGFloat? = nil
    ) -> Data? {
        renderShareCard(
            item: item,
            scale: scale
        )?
        .pngData()
    }
}
