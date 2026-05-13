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
    @Published var currentStep = 0
    @Published var isCompleting = false
    @Published var errorMessage: String?

    let totalSteps = 4

    private let repository = UserStateRepository()

    var canGoBack: Bool {
        currentStep > 0 && isCompleting == false
    }

    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    var progressText: String {
        "\(currentStep + 1) of \(totalSteps)"
    }

    func continueTapped() {
        guard isCompleting == false else {
            return
        }

        guard currentStep < totalSteps - 1 else {
            return
        }

        errorMessage = nil
        currentStep += 1
    }

    func backTapped() {
        guard isCompleting == false else {
            return
        }

        guard currentStep > 0 else {
            return
        }

        errorMessage = nil
        currentStep -= 1
    }

    func complete(
        userId: String,
        path: OnboardingStartPath,
        modelContext: ModelContext
    ) async -> Bool {
        let cleanedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedUserId.isEmpty == false else {
            errorMessage = "Missing user. Please sign in again."
            return false
        }

        guard isCompleting == false else {
            return false
        }

        isCompleting = true
        errorMessage = nil
        defer { isCompleting = false }

        do {
            try repository.completeOnboarding(
                userId: cleanedUserId,
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
