import XCTest
@testable import Ember

final class HapticServiceTests: XCTestCase {

    func testEscalatingHoldCadenceUsesSlowIntervalBeforeRamp() {
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: -1), 0.25)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 0), 0.25)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 0.49), 0.25)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 0.5), 0.25)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 0.849), 0.25)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 0.84), 0.25)
    }

    func testEscalatingHoldCadenceUsesFastIntervalAtFinalRamp() {
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 0.85), 0.08)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 1), 0.08)
        XCTAssertEqual(HapticService.escalatingHoldCadenceInterval(for: 1.5), 0.08)
    }
}
