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

    func prepareSession(
        authUser: AuthUser,
        modelContext: ModelContext
    ) async {
        profileState = .loading

        do {
            let profile = try await profileRepository.ensureUserProfile(
                for: authUser,
                modelContext: modelContext
            )

            profileState = .ready(profile)
        } catch {
            profileState = .error(error.localizedDescription)
        }
    }

    func reset() {
        profileState = .idle
    }
}

enum ProfileState: Equatable {
    case idle
    case loading
    case ready(UserProfile)
    case error(String)
}
