//
//  CloseCutSharePayload.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 02/06/26.
//

import Foundation
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CloseCutSharePayload: Transferable {
    let imageData: Data
    let fallbackText: String

    var previewImage: UIImage? {
        UIImage(data: imageData)
    }

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { payload in
            payload.imageData
        }
    }
}
