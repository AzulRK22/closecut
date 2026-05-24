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
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        configureFirestorePersistence()

        return true
    }

    private func configureFirestorePersistence() {
        guard FirebaseApp.app() != nil else {
            return
        }

        let db = Firestore.firestore()
        let settings = FirestoreSettings()

        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: AppEnvironment.firestoreCacheSizeBytes as NSNumber
        )

        db.settings = settings
        db.persistentCacheIndexManager?.enableIndexAutoCreation()
    }
}
