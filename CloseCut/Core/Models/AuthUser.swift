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

    var isAnonymous: Bool = false
}
