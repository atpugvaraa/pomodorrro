import XCTest

final class SmokeTests: XCTestCase {
    func test_targetRuns() {
        XCTAssertEqual(1 + 1, 2)
    }

    func test_fixtureBundled() throws {
        let url = Bundle(for: SmokeTests.self).url(forResource: "monza", withExtension: "svg")
        XCTAssertNotNil(url, "monza.svg fixture must be in the test bundle")
    }
}
