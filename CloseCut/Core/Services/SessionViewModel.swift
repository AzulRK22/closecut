//
//  SessionViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var profileState: ProfileState = .idle

    private let profileRepository = UserProfileRepository()

    // MARK: - Session Preparation

    func prepareSession(
        authUser: AuthUser,
        modelContext: ModelContext
    ) async {
        guard profileState.isLoading == false else {
            return
        }

        profileState = .loading

        do {
            let profile = try await profileRepository.ensureUserProfile(
                for: authUser,
                modelContext: modelContext
            )

            profileState = .ready(profile)
        } catch {
            profileState = .error(
                readableError(error)
            )
        }
    }

    func refreshProfile(
        authUser: AuthUser,
        modelContext: ModelContext
    ) async {
        do {
            let profile = try await profileRepository.ensureUserProfile(
                for: authUser,
                modelContext: modelContext
            )

            profileState = .ready(profile)
        } catch {
            profileState = .error(
                readableError(error)
            )
        }
    }

    func updateReadyProfile(
        _ profile: UserProfile
    ) {
        profileState = .ready(profile)
    }

    func reset() {
        profileState = .idle
    }

    // MARK: - Helpers

    private func readableError(_ error: Error) -> String {
        let message = error.localizedDescription.trimmed

        return message.isEmpty
            ? "We couldn’t prepare your profile. Please try again."
            : message
    }
}

// MARK: - Profile State

enum ProfileState: Equatable {
    case idle
    case loading
    case ready(UserProfile)
    case error(String)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var profile: UserProfile? {
        if case .ready(let profile) = self {
            return profile
        }

        return nil
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }

        return nil
    }
}
