//
//  LocalUserState.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation
import SwiftData

@Model
final class LocalUserState {
    @Attribute(.unique) var userId: String

    var hasCompletedOnboarding: Bool
    var selectedStartPathRaw: String?
    var onboardingVersion: Int
    var completedAt: Date?
    var quickAddCountAtCompletion: Int

    init(
        userId: String,
        hasCompletedOnboarding: Bool = false,
        selectedStartPath: OnboardingStartPath? = nil,
        onboardingVersion: Int = 1,
        completedAt: Date? = nil,
        quickAddCountAtCompletion: Int = 0
    ) {
        self.userId = userId
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedStartPathRaw = selectedStartPath?.rawValue
        self.onboardingVersion = onboardingVersion
        self.completedAt = completedAt
        self.quickAddCountAtCompletion = quickAddCountAtCompletion
    }
}

extension LocalUserState {
    var selectedStartPath: OnboardingStartPath? {
        OnboardingStartPath(rawValue: selectedStartPathRaw ?? "")
    }
}
