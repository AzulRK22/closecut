//
//  AppModelContainer.swift
//  CloseCut
//

import SwiftData

enum AppModelContainer {
    static let models: [any PersistentModel.Type] = [
        LocalEntry.self,
        LocalCircle.self,
        LocalCircleMembership.self,
        LocalUserProfile.self,
        LocalUserState.self,
        PendingAction.self,
        LocalBattleResult.self,
        LocalWatchlistItem.self,
        LocalWatchPlan.self,
        LocalWatchPlanResponse.self
    ]
}
