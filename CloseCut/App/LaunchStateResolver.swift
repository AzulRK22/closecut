//
//  LaunchStateResolver.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 28/04/26.
//

import Foundation

enum LaunchDestination: Equatable {
    case onboarding
    case mainHome
}

enum LaunchStateResolver {
    static func resolve(onboardingState: OnboardingState) -> LaunchDestination {
        onboardingState.hasCompletedOnboarding ? .mainHome : .onboarding
    }
}
