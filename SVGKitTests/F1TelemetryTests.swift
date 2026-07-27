import XCTest
import CoreGraphics
@testable import pomodorrro

final class F1TelemetryTests: XCTestCase {
    func test_monzaReferenceLoadsAndIsMeanNormalized() {
        let telemetry = F1Telemetry.reference(for: .monza)
        XCTAssertNotNil(telemetry)
        let mean = telemetry!.speed.reduce(0, +) / CGFloat(telemetry!.speed.count)
        XCTAssertEqual(mean, 1, accuracy: 0.02)          // mean-normalized
        XCTAssertGreaterThan(telemetry!.speed.count, 50)
    }
    func test_lookupClampsEnds() {
        let telemetry = F1Telemetry.reference(for: .monza)!
        XCTAssertEqual(telemetry.speed(atLapDistance: -1), telemetry.speed.first!, accuracy: 1e-6)
        XCTAssertEqual(telemetry.speed(atLapDistance: 2), telemetry.speed.last!, accuracy: 1e-6)
    }
    func test_madridHasNoTelemetry() {
        XCTAssertNil(F1Telemetry.reference(for: .madring))
    }
}
