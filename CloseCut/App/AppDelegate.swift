//
//  AppDelegate.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import FirebaseCore
import FirebaseFirestore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        let db = Firestore.firestore()
        let settings = FirestoreSettings()

        settings.cacheSettings = PersistentCacheSettings(
            sizeBytes: 100 * 1024 * 1024 as NSNumber
        )

        db.settings = settings
        db.persistentCacheIndexManager?.enableIndexAutoCreation()

        return true
    }
}

