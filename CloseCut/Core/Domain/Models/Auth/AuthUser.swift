//
//  AuthUser.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

struct AuthUser: Identifiable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let isAnonymous: Bool

    init(
        id: String,
        email: String?,
        displayName: String?,
        photoURL: URL?,
        isAnonymous: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isAnonymous = isAnonymous
    }
}
