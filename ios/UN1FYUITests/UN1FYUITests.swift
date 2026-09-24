//
//  UN1FYUITests.swift
//  UN1FYUITests
//
//  Created by Rork on March 17, 2026.
//

import XCTest

final class UN1FYUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testMainNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        let tabs = app.tabBars
        XCTAssertTrue(tabs.buttons["Home"].waitForExistence(timeout: 15))
        XCTAssertEqual(tabs.buttons.count, 4)
        tabs.buttons["Progress"].tap()
        XCTAssertTrue(app.staticTexts["Showing up adds up."].waitForExistence(timeout: 5))
        let badges = app.buttons["progress.badges"]
        for _ in 0..<4 where !badges.isHittable { app.swipeUp() }
        XCTAssertTrue(badges.isHittable)
        badges.tap()
        XCTAssertTrue(app.staticTexts["Achievements"].waitForExistence(timeout: 5))

        tabs.buttons["Community"].tap()
        XCTAssertTrue(app.staticTexts["Stronger together."].waitForExistence(timeout: 5))
        let sections = app.segmentedControls["Community section"]
        sections.buttons["Ranks"].tap()
        XCTAssertTrue(sections.buttons["Ranks"].isSelected)
        sections.buttons["Challenges"].tap()
        XCTAssertTrue(sections.buttons["Challenges"].isSelected)
        sections.buttons["Feed"].tap()
        XCTAssertTrue(sections.buttons["Feed"].isSelected)
        tabs.buttons["You"].tap()
        XCTAssertTrue(app.staticTexts["Part of something stronger."].waitForExistence(timeout: 5))
        tabs.buttons["Home"].tap()
        let community = app.buttons["home.community"]
        // The full-feed link remains reachable from the Home preview.
        for _ in 0..<4 where !community.isHittable { app.swipeUp() }
        XCTAssertTrue(community.isHittable)
        community.tap()
        XCTAssertTrue(tabs.buttons["Community"].isSelected)
    }

    @MainActor
    func testAppearanceAndProfileShortcut() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Your profile"].waitForExistence(timeout: 15))
        app.buttons["Your profile"].tap()
        XCTAssertTrue(app.tabBars.buttons["You"].isSelected)
        let light = app.buttons["Light"]
        for _ in 0..<5 where !light.isHittable { app.swipeUp() }
        XCTAssertTrue(light.isHittable)
        for mode in ["Light", "Dark", "System"] {
            app.buttons[mode].tap()
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Profile-\(mode)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
