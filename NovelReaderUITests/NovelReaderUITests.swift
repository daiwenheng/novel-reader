import XCTest

final class NovelReaderUITests: XCTestCase {
    func testLaunchShowsBookshelf() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.navigationBars["书架"].waitForExistence(timeout: 10))
    }
}
