//
//  LaunchViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class LaunchViewModel: ObservableObject {
    @Published private(set) var destination: LaunchDestination?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository = UserStateRepository()
    private var lastResolvedUserId: String?

    func resolveIfNeeded(
        userId: String,
        modelContext: ModelContext
    ) {
        guard destination == nil else {
            return
        }

        guard isLoading == false else {
            return
        }

        guard lastResolvedUserId != userId else {
            return
        }

        resolve(
            userId: userId,
            modelContext: modelContext
        )
    }

    func resolve(
        userId: String,
        modelContext: ModelContext
    ) {
        guard isLoading == false else {
            return
        }

        isLoading = true
        errorMessage = nil
        lastResolvedUserId = userId

        do {
            let state = try repository.fetchUserState(
                userId: userId,
                modelContext: modelContext
            )

            destination = LaunchStateResolver.resolve(
                onboardingState: state
            )
        } catch {
            errorMessage = error.localizedDescription
            destination = .onboarding

            #if DEBUG
            print("⚠️ Failed to resolve launch destination:", error.localizedDescription)
            #endif
        }

        isLoading = false
    }

    func markNeedsRefresh() {
        destination = nil
        lastResolvedUserId = nil
    }

    func completeToMain() {
        destination = .mainHome
    }
}
