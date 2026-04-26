//
//  AuthService.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import FirebaseAuth
import Combine


@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var authState: AuthState = .loading

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    func listenToAuthState() {
        authState = .loading

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }

            if let user {
                self.authState = .signedIn(AuthUser(firebaseUser: user))
            } else {
                self.authState = .signedOut
            }
        }
    }

    func signUp(email: String, password: String) async {
        do {
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )

            authState = .signedIn(AuthUser(firebaseUser: result.user))
        } catch {
            authState = .error(Self.readableError(error))
        }
    }

    func signIn(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )

            authState = .signedIn(AuthUser(firebaseUser: result.user))
        } catch {
            authState = .error(Self.readableError(error))
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            authState = .signedOut
        } catch {
            authState = .error(Self.readableError(error))
        }
    }

    func currentUser() -> AuthUser? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }

        return AuthUser(firebaseUser: user)
    }

    private static func readableError(_ error: Error) -> String {
        let nsError = error as NSError

        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return error.localizedDescription
        }

        switch code {
        case .invalidEmail:
            return "The email address is invalid."
        case .emailAlreadyInUse:
            return "This email is already in use."
        case .weakPassword:
            return "Password should be at least 6 characters."
        case .wrongPassword:
            return "The password is incorrect."
        case .userNotFound:
            return "No account was found with this email."
        case .invalidCredential:
            return "The email or password is incorrect, or this account does not exist yet."
        case .networkError:
            return "Network error. Please check your connection."
        default:
            return error.localizedDescription
        }
    }
}

private extension AuthUser {
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL
        self.isAnonymous = firebaseUser.isAnonymous
    }
}
