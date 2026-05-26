//
//  OnboardingViewModel.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation
import Combine
import SwiftData

struct OnboardingStepContent: Identifiable, Equatable {
    let id: Int
    let title: String
    let message: String
    let systemImage: String
    let isLogo: Bool
    let pills: [OnboardingHeroPill]
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 0
    @Published var isCompleting = false
    @Published var errorMessage: String?
    @Published var showSkipConfirmation = false

    let steps: [OnboardingStepContent] = [
        OnboardingStepContent(
            id: 0,
            title: "Your private taste library.",
            message: "Build a personal record of the movies and series that stayed with you — not just what you watched.",
            systemImage: "film.stack",
            isLogo: true,
            pills: [
                OnboardingHeroPill(icon: "lock.fill", text: "Private"),
                OnboardingHeroPill(icon: "rectangle.stack.fill", text: "Your history")
            ]
        ),
        OnboardingStepContent(
            id: 1,
            title: "Start with what you already watched.",
            message: "Add a few past watches quickly so CloseCut starts feeling personal from the first session.",
            systemImage: "bolt.fill",
            isLogo: false,
            pills: [
                OnboardingHeroPill(icon: "magnifyingglass", text: "Search"),
                OnboardingHeroPill(icon: "plus.circle.fill", text: "Add fast"),
                OnboardingHeroPill(icon: "heart.fill", text: "React")
            ]
        ),
        OnboardingStepContent(
            id: 2,
            title: "Choose better next time.",
            message: "QuickPick uses your own history, moods, tags, and rewatch signals to suggest something that fits you.",
            systemImage: "sparkles",
            isLogo: false,
            pills: [
                OnboardingHeroPill(icon: "wand.and.stars", text: "Personal picks"),
                OnboardingHeroPill(icon: "arrow.triangle.2.circlepath", text: "No repeats")
            ]
        )
    ]

    private let repository = UserStateRepository()

    var totalSteps: Int {
        steps.count + 1
    }

    var canGoBack: Bool {
        currentStep > 0 && isCompleting == false
    }

    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    var progressText: String {
        "\(currentStep + 1) of \(totalSteps)"
    }

    var currentStepContent: OnboardingStepContent? {
        steps.first { $0.id == currentStep }
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

    func requestSkipConfirmation() {
        guard isCompleting == false else {
            return
        }

        showSkipConfirmation = true
    }

    func complete(
        userId: String,
        path: OnboardingStartPath,
        modelContext: ModelContext
    ) async -> Bool {
        let cleanedUserId = userId.trimmed

        guard cleanedUserId.isEmpty == false else {
            errorMessage = "Missing user. Please sign in again."
            return false
        }

        guard isCompleting == false else {
            return false
        }

        isCompleting = true
        errorMessage = nil

        defer {
            isCompleting = false
        }

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
