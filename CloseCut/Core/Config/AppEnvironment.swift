//
//  AppEnvironment.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import Foundation

enum AppEnvironment {
    // MARK: - App Identity

    static let appName = "CloseCut"

    // MARK: - Product Rules

    static let minimumQuickPickHistoryCount = 3
    static let minimumBattleOptionCount = 2
    static let minimumCircleQuickPickHistoryCount = 3

    // MARK: - Firestore

    static let firestoreCacheSizeBytes = 100 * 1024 * 1024

    // MARK: - UI / Experience

    static let defaultAnimationDuration: TimeInterval = 0.22
    static let shortFeedbackDurationNanoseconds: UInt64 = 1_500_000_000

    // MARK: - External Services

    static let tmdbSearchResultLimit = 10
    static let quickPickDiscoveryLimit = 10

    // MARK: - App Store / Support

    static let supportEmail = "support@closecut.app"
    static let privacyPolicyURLString = ""
    static let termsURLString = ""
}
