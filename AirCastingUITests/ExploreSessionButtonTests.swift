// Created by Lunar on 03/08/2022.
//

import XCTest

class ExploreSessionButtonTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launch()
        continueAfterFailure = false
    }

    func test_tappingExpoleSessionButtonAndThenGoingToCreateSessionScreen_shouldntTriggerSFScreenAsDefault() throws {
        let tabBar = app.tabBars["Tab Bar"]
        
        var searchFollowCancelButton: XCUIElement {
            let searchFollowScreen = app.navigationBars["_TtGC7SwiftUI19UIHosting"]
            return searchFollowScreen.buttons["Cancel"]
        }
        
        var exploreSessionButton: XCUIElement {
            let collectionViewCells = app.collectionViews/*@START_MENU_TOKEN@*/.cells/*[[".scrollViews.cells",".cells"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.scrollViews
            return collectionViewCells.otherElements.buttons["Explore existing sessions"]
        }
        
        exploreSessionButton.tap()
        searchFollowCancelButton.tap()
        tabBar.buttons["home"].tap()
        tabBar.buttons["plus"].tap()
        
        XCTAssertFalse(app.staticTexts["Search fixed sessions"].exists)
       
        app.buttons["Follow session search & follow fixed sessions "].tap()
        
        XCTAssert(app.staticTexts["Search fixed sessions"].exists)
    }
}
