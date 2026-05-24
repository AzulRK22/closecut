//
//  AuthState.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

enum AuthState: Equatable {
    case loading
    case signedOut
    case signedIn(AuthUser)
    case error(String)
}
