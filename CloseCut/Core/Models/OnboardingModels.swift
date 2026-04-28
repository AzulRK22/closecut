//
//  OnboardingModels.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation

enum OnboardingStartPath: String, Codable, CaseIterable {
    case quickAdd
    case startFresh
    case skipped
}

struct OnboardingState: Equatable {
    let userId: String
    var hasCompletedOnboarding: Bool
    var selectedStartPath: OnboardingStartPath?
    var onboardingVersion: Int
    var completedAt: Date?
    var quickAddCountAtCompletion: Int
}
