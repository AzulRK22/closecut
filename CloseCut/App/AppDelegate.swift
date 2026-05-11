//
//  AppDelegate.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import UIKit
import FirebaseCore
import FirebaseFirestore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureFirebaseIfNeeded()
        configureFirestore()

        return true
    }

    private func configureFirebaseIfNeeded() {
        guard FirebaseApp.app() == nil else {
            return
        }

        FirebaseApp.configure()
    }

    private func configureFirestore() {
        let database = Firestore.firestore()
        let settings = FirestoreSettings()

        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: 100 * 1024 * 1024 as NSNumber
        )

        database.settings = settings
        database.persistentCacheIndexManager?.enableIndexAutoCreation()
    }
}
