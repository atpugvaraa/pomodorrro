import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1FollowerTests: XCTestCase {
    func test_convergesToTarget() {
        let follower = CameraFollower()
        follower.reset(to: .zero)
        var now = Date(timeIntervalSince1970: 0)
        let target = CGSize(width: 100, height: 0)
        for _ in 0..<600 { now.addTimeInterval(1.0 / 60.0); _ = follower.smoothedOffset(movingToward: target, inertia: 0.1, at: now) }
        XCTAssertEqual(follower.value.width, 100, accuracy: 0.5)
    }
    func test_lagsBehindTarget() {
        let follower = CameraFollower()
        follower.reset(to: .zero)
        let start = Date(timeIntervalSince1970: 0)
        _ = follower.smoothedOffset(movingToward: CGSize(width: 100, height: 0), inertia: 0.2, at: start) // baseline frame
        let stepped = follower.smoothedOffset(movingToward: CGSize(width: 100, height: 0), inertia: 0.2,
                                              at: start.addingTimeInterval(1.0 / 60.0))
        XCTAssertGreaterThan(stepped.width, 0)
        XCTAssertLessThan(stepped.width, 100)   // eased, did not snap
    }
    func test_resetIsImmediate() {
        let follower = CameraFollower()
        follower.reset(to: CGSize(width: 42, height: 7))
        XCTAssertEqual(follower.value.width, 42, accuracy: 1e-9)
        XCTAssertEqual(follower.value.height, 7, accuracy: 1e-9)
    }
    func test_frameRateIndependence() {
        let fast = CameraFollower(); fast.reset(to: .zero)
        let slow = CameraFollower(); slow.reset(to: .zero)
        let target = CGSize(width: 100, height: 0)
        var fastClock = Date(timeIntervalSince1970: 0)
        for _ in 0..<120 { fastClock.addTimeInterval(1.0 / 120.0); _ = fast.smoothedOffset(movingToward: target, inertia: 0.15, at: fastClock) }
        var slowClock = Date(timeIntervalSince1970: 0)
        for _ in 0..<30 { slowClock.addTimeInterval(1.0 / 30.0); _ = slow.smoothedOffset(movingToward: target, inertia: 0.15, at: slowClock) }
        XCTAssertEqual(fast.value.width, slow.value.width, accuracy: 1.0)
    }
}
