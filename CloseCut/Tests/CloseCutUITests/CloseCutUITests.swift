//
//  CloseCutUITests.swift
//  CloseCutUITests
//
//  Created by Azul Ramirez Kuri on 25/04/26.
//

import XCTest

final class CloseCutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-uiTesting")
        app.launch()

        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: 5),
            "App should launch into foreground."
        )
    }
}
