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
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository = UserStateRepository()

    func resolve(
        userId: String,
        modelContext: ModelContext
    ) {
        isLoading = true
        errorMessage = nil

        do {
            let state = try repository.fetchUserState(
                userId: userId,
                modelContext: modelContext
            )

            destination = LaunchStateResolver.resolve(onboardingState: state)
        } catch {
            errorMessage = error.localizedDescription
            destination = .onboarding
        }

        isLoading = false
    }

    func markNeedsRefresh() {
        destination = nil
    }

    func completeToMain() {
        destination = .mainHome
    }
}
