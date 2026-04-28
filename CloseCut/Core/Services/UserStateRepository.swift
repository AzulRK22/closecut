//
//  UserStateRepository.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation
import SwiftData

@MainActor
final class UserStateRepository {
    func fetchUserState(
        userId: String,
        modelContext: ModelContext
    ) throws -> OnboardingState {
        let localState = try fetchLocalUserState(
            userId: userId,
            modelContext: modelContext
        )

        if let localState {
            return OnboardingState(
                userId: localState.userId,
                hasCompletedOnboarding: localState.hasCompletedOnboarding,
                selectedStartPath: localState.selectedStartPath,
                onboardingVersion: localState.onboardingVersion,
                completedAt: localState.completedAt,
                quickAddCountAtCompletion: localState.quickAddCountAtCompletion
            )
        }

        let newState = LocalUserState(userId: userId)
        modelContext.insert(newState)
        try modelContext.save()

        return OnboardingState(
            userId: userId,
            hasCompletedOnboarding: false,
            selectedStartPath: nil,
            onboardingVersion: 1,
            completedAt: nil,
            quickAddCountAtCompletion: 0
        )
    }

    func completeOnboarding(
        userId: String,
        selectedStartPath: OnboardingStartPath,
        quickAddCountAtCompletion: Int = 0,
        modelContext: ModelContext
    ) throws {
        let localState: LocalUserState

        if let existing = try fetchLocalUserState(
            userId: userId,
            modelContext: modelContext
        ) {
            localState = existing
        } else {
            localState = LocalUserState(userId: userId)
            modelContext.insert(localState)
        }

        localState.hasCompletedOnboarding = true
        localState.selectedStartPathRaw = selectedStartPath.rawValue
        localState.onboardingVersion = 1
        localState.completedAt = Date()
        localState.quickAddCountAtCompletion = quickAddCountAtCompletion

        try modelContext.save()
    }

    func resetOnboarding(
        userId: String,
        modelContext: ModelContext
    ) throws {
        guard let localState = try fetchLocalUserState(
            userId: userId,
            modelContext: modelContext
        ) else {
            return
        }

        localState.hasCompletedOnboarding = false
        localState.selectedStartPathRaw = nil
        localState.completedAt = nil
        localState.quickAddCountAtCompletion = 0

        try modelContext.save()
    }

    private func fetchLocalUserState(
        userId: String,
        modelContext: ModelContext
    ) throws -> LocalUserState? {
        let descriptor = FetchDescriptor<LocalUserState>(
            predicate: #Predicate { state in
                state.userId == userId
            }
        )

        return try modelContext.fetch(descriptor).first
    }
}
