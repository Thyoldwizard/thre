import XCTest

final class EmberUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchForUITesting(
        resetPreferences: Bool = false,
        startReflection: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-disableMorningRitual", "-uiTesting"]
        if resetPreferences {
            app.launchArguments.append("-resetPreferences")
        }
        if startReflection {
            app.launchArguments.append("-uiTestingStartReflection")
        }
        app.launch()
        let launchMarker = startReflection ? app.staticTexts["REFLECT"] : app.staticTexts["TODAY"]
        XCTAssertTrue(launchMarker.waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func createTask(named title: String, in app: XCUIApplication) {
        app.buttons["home.addTask"].tap()

        XCTAssertTrue(app.staticTexts["SET FOCUS"].waitForExistence(timeout: 5))
        let titleEditor = app.textViews["addTask.title"]
        XCTAssertTrue(titleEditor.waitForExistence(timeout: 5))
        titleEditor.tap()
        titleEditor.typeText(title)

        app.buttons["addTask.save"].tap()

        XCTAssertTrue(app.staticTexts["TODAY"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
    }

    @MainActor
    private func completeTask(named title: String, in app: XCUIApplication) {
        app.staticTexts[title].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["TASK"].waitForExistence(timeout: 5))
        app.buttons["taskDetail.completeToggle"].tap()
        app.buttons["taskDetail.back"].tap()

        XCTAssertTrue(app.staticTexts["TODAY"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSettingsRouteOpensFromHome() throws {
        let app = launchForUITesting()
        app.buttons["Settings"].tap()

        XCTAssertTrue(app.staticTexts["SETTINGS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["PREFERENCES"].exists)
    }

    @MainActor
    func testSettingsPreferencesPersistAfterRelaunch() throws {
        let app = launchForUITesting(resetPreferences: true)
        app.buttons["Settings"].tap()

        let soundSwitch = app.switches["settings.sound"]
        XCTAssertTrue(soundSwitch.waitForExistence(timeout: 5))
        XCTAssertEqual(soundSwitch.value as? String, "1")

        soundSwitch.tap()
        XCTAssertEqual(soundSwitch.value as? String, "0")

        app.terminate()
        app.launchArguments = ["-disableMorningRitual", "-uiTesting"]
        app.launch()
        XCTAssertTrue(app.staticTexts["TODAY"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()

        let relaunchedSoundSwitch = app.switches["settings.sound"]
        XCTAssertTrue(relaunchedSoundSwitch.waitForExistence(timeout: 5))
        XCTAssertEqual(relaunchedSoundSwitch.value as? String, "0")
    }

    @MainActor
    func testStreakRouteOpensFromHome() throws {
        let app = launchForUITesting()
        app.buttons["home.streak"].tap()

        XCTAssertTrue(app.staticTexts["RHYTHM"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["CURRENT STREAK"].exists)
        XCTAssertTrue(app.staticTexts["SIGNALS"].exists)
    }

    @MainActor
    func testReflectionSavesEntry() throws {
        let app = launchForUITesting(startReflection: true)

        let reflectionText = app.textViews["reflection.text"]
        XCTAssertTrue(reflectionText.waitForExistence(timeout: 5))
        reflectionText.tap()
        reflectionText.typeText("Small steps moved the day forward.")

        let saveButton = app.buttons["reflection.topSave"]
        saveButton.tap()
        let saved = NSPredicate(format: "value == %@", "saved")
        expectation(for: saved, evaluatedWith: saveButton)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testCompletingThreeTasksShowsTranscendenceAndReflects() throws {
        let app = launchForUITesting()
        let titles = [
            "Complete first focus",
            "Complete second focus",
            "Complete third focus"
        ]

        for title in titles {
            createTask(named: title, in: app)
        }

        for title in titles {
            completeTask(named: title, in: app)
        }

        XCTAssertTrue(app.staticTexts["All three. Done."].waitForExistence(timeout: 5))
        app.buttons["transcendence.reflect"].tap()
        XCTAssertTrue(app.staticTexts["REFLECT"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTaskDetailReminderToggleCanSetAndRemoveSchedule() throws {
        let app = launchForUITesting()
        createTask(named: "Schedule reminder QA", in: app)

        app.staticTexts["Schedule reminder QA"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["TASK"].waitForExistence(timeout: 5))
        let scheduleToggle = app.switches["taskDetail.scheduleToggle"]
        XCTAssertTrue(scheduleToggle.waitForExistence(timeout: 5))
        scheduleToggle.tap()

        XCTAssertTrue(app.staticTexts["Reminder set"].waitForExistence(timeout: 5))
        app.buttons["taskDetail.removeSchedule"].tap()
        XCTAssertTrue(app.staticTexts["No reminder"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAddTaskFlowCreatesHomeModule() throws {
        let app = launchForUITesting()
        createTask(named: "Ship the Ember QA pass", in: app)
    }

    @MainActor
    func testTaskDetailAddsAndChecksSubtask() throws {
        let app = launchForUITesting()
        createTask(named: "Prepare task detail QA", in: app)

        app.staticTexts["Prepare task detail QA"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["TASK"].waitForExistence(timeout: 5))
        let subtaskField = app.textFields["taskDetail.addSubtask"]
        XCTAssertTrue(subtaskField.waitForExistence(timeout: 5))
        subtaskField.tap()
        subtaskField.typeText("Confirm subtask controls\n")

        XCTAssertTrue(app.staticTexts["Confirm subtask controls"].waitForExistence(timeout: 5))
        app.buttons["Toggle subtask Confirm subtask controls"].tap()

        let progress = app.staticTexts["taskDetail.subtaskProgress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        XCTAssertEqual(progress.label, "1/1")
    }
}
