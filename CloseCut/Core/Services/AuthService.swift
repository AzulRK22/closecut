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

    // MARK: - Auth State

    func listenToAuthState() {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
            self.authStateHandle = nil
        }

        authState = .loading

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else {
                return
            }

            Task { @MainActor in
                if let firebaseUser {
                    self.authState = .signedIn(
                        AuthUser(firebaseUser: firebaseUser)
                    )
                } else {
                    self.authState = .signedOut
                }
            }
        }
    }

    // MARK: - Email Auth

    func signUp(
        email: String,
        password: String
    ) async {
        let cleanedEmail = cleanEmail(email)

        guard cleanedEmail.isEmpty == false else {
            authState = .error("Enter a valid email address.")
            return
        }

        guard password.isEmpty == false else {
            authState = .error("Enter a password.")
            return
        }

        do {
            let result = try await Auth.auth().createUser(
                withEmail: cleanedEmail,
                password: password
            )

            authState = .signedIn(
                AuthUser(firebaseUser: result.user)
            )
        } catch {
            authState = .error(
                Self.readableError(error)
            )
        }
    }

    func signIn(
        email: String,
        password: String
    ) async {
        let cleanedEmail = cleanEmail(email)

        guard cleanedEmail.isEmpty == false else {
            authState = .error("Enter a valid email address.")
            return
        }

        guard password.isEmpty == false else {
            authState = .error("Enter your password.")
            return
        }

        do {
            let result = try await Auth.auth().signIn(
                withEmail: cleanedEmail,
                password: password
            )

            authState = .signedIn(
                AuthUser(firebaseUser: result.user)
            )
        } catch {
            authState = .error(
                Self.readableError(error)
            )
        }
    }

    // MARK: - Session

    func signOut() {
        do {
            try Auth.auth().signOut()
            authState = .signedOut
        } catch {
            authState = .error(
                Self.readableError(error)
            )
        }
    }

    func currentUser() -> AuthUser? {
        guard let firebaseUser = Auth.auth().currentUser else {
            return nil
        }

        return AuthUser(firebaseUser: firebaseUser)
    }

    // MARK: - Helpers

    private func cleanEmail(_ email: String) -> String {
        email.trimmed.lowercased()
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

        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."

        case .userDisabled:
            return "This account has been disabled."

        case .operationNotAllowed:
            return "This sign-in method is not enabled."

        default:
            return error.localizedDescription
        }
    }
}

// MARK: - Firebase Mapping

private extension AuthUser {
    init(firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email
        self.displayName = firebaseUser.displayName
        self.photoURL = firebaseUser.photoURL
        self.isAnonymous = firebaseUser.isAnonymous
    }
}
