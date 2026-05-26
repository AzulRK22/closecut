//
//  AppBuildInfo.swift
//  CloseCut
//
//  Created by Azul Ramirez Kuri on 29/04/26.
//

import Foundation

enum AppBuildInfo {
    static var appName: String {
        value(for: "CFBundleName", fallback: "CloseCut")
    }

    static var version: String {
        value(for: "CFBundleShortVersionString", fallback: "1.0")
    }

    static var build: String {
        value(for: "CFBundleVersion", fallback: "1")
    }

    static var displayVersion: String {
        "\(version) (\(build))"
    }

    static var shortDisplayVersion: String {
        "v\(version)"
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown.bundle"
    }

    private static func value(
        for key: String,
        fallback: String
    ) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String else {
            return fallback
        }

        let cleanedValue = value.trimmed

        return cleanedValue.isEmpty ? fallback : cleanedValue
    }
}
