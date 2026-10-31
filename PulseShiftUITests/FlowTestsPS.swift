import XCTest

final class FlowTestsPS: XCTestCase {
    @MainActor func testTutorialRestartUndoAndRelaunch() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ps-ui-testing", "--ps-reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["LEVEL 01"].waitForExistence(timeout: 15))
        let first = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pulse a,'")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let boardShot = XCTAttachment(screenshot: app.screenshot()); boardShot.name = "First Pulse board"; boardShot.lifetime = .keepAlways; add(boardShot)
        first.tap()
        XCTAssertTrue(app.staticTexts["PERFECT SHIFT"].waitForExistence(timeout: 8))
        continueResult(app)
        XCTAssertTrue(app.staticTexts["LEVEL 02"].waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pulse a,'")).firstMatch.tap()
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        let enabled = NSPredicate(format: "enabled == true")
        expectation(for: enabled, evaluatedWith: undo)
        waitForExpectations(timeout: 5)
        undo.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pulse a,'")).firstMatch.exists)
        app.buttons["Restart"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pulse a,'")).firstMatch.tap()
        let b = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pulse b,'")).firstMatch
        expectation(for: enabled, evaluatedWith: b); waitForExpectations(timeout: 5)
        b.tap()
        XCTAssertTrue(app.staticTexts["PERFECT SHIFT"].waitForExistence(timeout: 8))
        app.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["Find your flow."].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Home"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.terminate()
        app.launchArguments = ["--ps-ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Find your flow."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Level 03"].exists)
        app.buttons["CONTINUE"].tap()
        for id in ["c", "b", "a"] {
            let pulse = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pulse \(id),")).firstMatch
            expectation(for: enabled, evaluatedWith: pulse); waitForExpectations(timeout: 8)
            pulse.tap()
        }
        XCTAssertTrue(app.staticTexts["PERFECT SHIFT"].waitForExistence(timeout: 8))
        continueResult(app)
        app.buttons["Pause"].tap()
        app.buttons["Exit to Home"].tap()
        app.buttons["Daily"].tap()
        XCTAssertTrue(app.staticTexts["A daily shift."].waitForExistence(timeout: 5))
        app.buttons["Collection"].tap()
        XCTAssertTrue(app.staticTexts["Your wavelength."].waitForExistence(timeout: 5))
        capture(app, "Collection")
        app.buttons["Daily"].tap()
        XCTAssertTrue(app.staticTexts["A daily shift."].waitForExistence(timeout: 5))
        capture(app, "Daily")
        app.buttons["Levels"].tap()
        XCTAssertTrue(app.staticTexts["Follow the signal."].waitForExistence(timeout: 5))
        capture(app, "Chapters")
        app.buttons.containing(.staticText, identifier: "FIRST PULSE").firstMatch.tap()
        capture(app, "Level nodes")
    }
}


extension FlowTestsPS {
    @MainActor func testFinaleChainPolarityAndPortals() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ps-ui-testing", "--ps-reset", "--ps-level=60"]
        app.launch()
        XCTAssertTrue(app.staticTexts["LEVEL 60"].waitForExistence(timeout: 15))
        let before = XCTAttachment(screenshot: app.screenshot()); before.name = "Overload board"; before.lifetime = .keepAlways; add(before)
        for id in ["h", "g", "f", "f", "f", "d", "c", "F", "b", "a"] {
            let prefix = id == "F" ? "Polarity switch" : "Pulse"
            let pulse = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "\(prefix) \(id),")).firstMatch
            XCTAssertTrue(pulse.waitForExistence(timeout: 10))
            expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: pulse)
            waitForExpectations(timeout: 20)
            pulse.tap()
        }
        XCTAssertTrue(app.staticTexts["PERFECT SHIFT"].waitForExistence(timeout: 15))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: app.buttons["result-continue"])
        waitForExpectations(timeout: 5)
        let after = XCTAttachment(screenshot: app.screenshot()); after.name = "Perfect Shift"; after.lifetime = .keepAlways; add(after)
    }
}

extension FlowTestsPS {
    @MainActor func testFirstThreeTutorialLevelsReturnHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ps-ui-testing", "--ps-reset"]
        app.launch()
        XCTAssertTrue(app.staticTexts["LEVEL 01"].waitForExistence(timeout: 15))
        for (index, moves) in [["a"], ["a", "b"], ["c", "b", "a"]].enumerated() {
            for id in moves {
                let pulse = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Pulse \(id),")).firstMatch
                expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: pulse)
                waitForExpectations(timeout: 10)
                pulse.tap()
            }
            XCTAssertTrue(app.staticTexts["PERFECT SHIFT"].waitForExistence(timeout: 10))
            if index == 2 { XCTAssertTrue(app.buttons["BACK TO HOME"].exists) }
            continueResult(app)
        }
        XCTAssertTrue(app.staticTexts["Find your flow."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Level 04"].exists)
    }
}


extension FlowTestsPS {
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func continueResult(_ app: XCUIApplication) {
        let button = app.buttons["result-continue"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "enabled == true"), evaluatedWith: button)
        waitForExpectations(timeout: 5)
        button.tap()
    }
}

extension FlowTestsPS {
    @MainActor func testSettingsPersistAndLegalNavigationWorks() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ps-ui-testing", "--ps-reset"]
        app.launch()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 15))
        app.buttons["Pause"].tap()
        app.buttons["Settings"].tap()
        let options = ["Haptics", "Sound", "Music", "Reduced Effects", "Tutorial Tips"]
        var expected: [String: String] = [:]
        for name in options {
            let toggle = app.switches[name]
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            let wasOn = toggle.value as? String == "1"
            toggle.tap()
            expected[name] = wasOn ? "0" : "1"
            XCTAssertEqual(toggle.value as? String, expected[name])
        }
        app.buttons["Done"].tap()
        app.buttons["RESUME"].tap()
        let tutorial = app.descendants(matching: .any)["tutorial"].firstMatch
        XCTAssertEqual(tutorial.exists, expected["Tutorial Tips"] == "1")
        app.buttons["Pause"].tap()
        app.buttons["Exit to Home"].tap()
        app.terminate()
        app.launchArguments = ["--ps-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 15))
        app.buttons["Settings"].tap()
        for name in options { XCTAssertEqual(app.switches[name].value as? String, expected[name]) }
        app.swipeUp()
        app.swipeUp()
        app.buttons["Privacy"].tap()
        XCTAssertTrue(app.staticTexts["Your privacy."].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Terms"].tap()
        XCTAssertTrue(app.staticTexts["Terms of use."].waitForExistence(timeout: 5))
        capture(app, "Terms")
    }

    @MainActor func testDailyWeeklyAndStatisticsReset() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ps-ui-testing", "--ps-reset"]
        app.launch()
        let pulse = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pulse a,'")).firstMatch
        XCTAssertTrue(pulse.waitForExistence(timeout: 15))
        pulse.tap()
        XCTAssertTrue(app.staticTexts["PERFECT SHIFT"].waitForExistence(timeout: 8))
        app.buttons["Home"].tap()
        app.buttons["Settings"].tap()
        app.swipeUp()
        app.buttons["Reset statistics"].tap()
        app.buttons["confirm-reset"].firstMatch.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Level 02"].waitForExistence(timeout: 5))
        app.buttons["Daily"].tap()
        app.buttons["PLAY DAILY"].tap()
        XCTAssertTrue(app.staticTexts["DAILY SHIFT"].waitForExistence(timeout: 5))
        app.buttons["Pause"].tap()
        app.buttons["Exit to Home"].tap()
        app.buttons["Daily"].tap()
        app.swipeUp()
        app.buttons.containing(.staticText, identifier: "WEEKLY CIRCUIT").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Weekly Circuit"].waitForExistence(timeout: 5))
        app.buttons.containing(.staticText, identifier: "First Contact").firstMatch.tap()
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout: 5))
        app.buttons["Pause"].tap()
        app.buttons["Exit to Home"].tap()
        app.buttons["Settings"].tap()
        app.swipeUp()
        app.buttons["Reset progress"].tap()
        app.buttons["confirm-reset"].firstMatch.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Level 01"].waitForExistence(timeout: 5))
    }
}
