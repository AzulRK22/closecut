//
//  OnboardingViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var isCompleting: Bool = false
    @Published var errorMessage: String?

    let totalSteps = 3

    private let repository = UserStateRepository()

    var canGoBack: Bool {
        currentStep > 0
    }

    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    func continueTapped() {
        guard currentStep < totalSteps - 1 else {
            return
        }

        currentStep += 1
    }

    func backTapped() {
        guard currentStep > 0 else {
            return
        }

        currentStep -= 1
    }

    func complete(
        userId: String,
        path: OnboardingStartPath,
        modelContext: ModelContext
    ) async -> Bool {
        isCompleting = true
        defer { isCompleting = false }

        do {
            try repository.completeOnboarding(
                userId: userId,
                selectedStartPath: path,
                quickAddCountAtCompletion: 0,
                modelContext: modelContext
            )

            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
