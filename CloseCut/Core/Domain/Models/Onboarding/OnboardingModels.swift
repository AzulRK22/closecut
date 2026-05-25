//
//  OnboardingModels.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation

enum OnboardingStartPath: String, Codable, CaseIterable, Identifiable {
    case quickAdd
    case startFresh
    case skipped

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .quickAdd:
            return "Quick Add Past Watches"
        case .startFresh:
            return "Start Fresh"
        case .skipped:
            return "Skipped"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .quickAdd:
            return "Quick Add"
        case .startFresh:
            return "Start Fresh"
        case .skipped:
            return "Skipped"
        }
    }

    var analyticsName: String {
        rawValue
    }

    var isActivationPath: Bool {
        switch self {
        case .quickAdd:
            return true
        case .startFresh, .skipped:
            return false
        }
    }
}

struct OnboardingState: Equatable {
    static let currentVersion = 1

    let userId: String
    var hasCompletedOnboarding: Bool
    var selectedStartPath: OnboardingStartPath?
    var onboardingVersion: Int
    var completedAt: Date?
    var quickAddCountAtCompletion: Int

    var needsOnboarding: Bool {
        hasCompletedOnboarding == false
    }

    var hasCompletedCurrentOnboardingVersion: Bool {
        hasCompletedOnboarding &&
        onboardingVersion >= Self.currentVersion
    }

    var usedActivationPath: Bool {
        selectedStartPath?.isActivationPath == true
    }

    var completedWithQuickAdd: Bool {
        selectedStartPath == .quickAdd
    }

    var completedWithoutHistory: Bool {
        hasCompletedOnboarding &&
        quickAddCountAtCompletion == 0
    }

    var activationSummaryText: String {
        guard hasCompletedOnboarding else {
            return "Onboarding not completed"
        }

        guard let selectedStartPath else {
            return "Completed onboarding"
        }

        switch selectedStartPath {
        case .quickAdd:
            return quickAddCountAtCompletion == 1
                ? "Started with 1 past watch"
                : "Started with \(quickAddCountAtCompletion) past watches"

        case .startFresh:
            return "Started fresh"

        case .skipped:
            return "Skipped onboarding"
        }
    }

    static func fresh(
        userId: String
    ) -> OnboardingState {
        OnboardingState(
            userId: userId,
            hasCompletedOnboarding: false,
            selectedStartPath: nil,
            onboardingVersion: currentVersion,
            completedAt: nil,
            quickAddCountAtCompletion: 0
        )
    }

    func completed(
        path: OnboardingStartPath,
        quickAddCount: Int,
        completedAt: Date = Date()
    ) -> OnboardingState {
        OnboardingState(
            userId: userId,
            hasCompletedOnboarding: true,
            selectedStartPath: path,
            onboardingVersion: Self.currentVersion,
            completedAt: completedAt,
            quickAddCountAtCompletion: max(quickAddCount, 0)
        )
    }
}
