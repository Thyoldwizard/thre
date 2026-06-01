import XCTest
@testable import Ember

@MainActor
final class EmberLoggerTests: XCTestCase {

    func testInfoOnAllSubsystems() {
        EmberLogger.home.info("test home info")
        EmberLogger.reminders.info("test reminders info")
        EmberLogger.records.info("test records info")
        EmberLogger.widget.info("test widget info")
    }

    func testDebugOnAllSubsystems() {
        EmberLogger.home.debug("test home debug")
        EmberLogger.reminders.debug("test reminders debug")
        EmberLogger.records.debug("test records debug")
        EmberLogger.widget.debug("test widget debug")
    }

    func testErrorWithoutException() {
        EmberLogger.home.error("error without exception")
        EmberLogger.records.error("records error without exception")
    }

    func testErrorWithException() {
        let err = NSError(domain: "com.ember.test", code: 42, userInfo: [NSLocalizedDescriptionKey: "test error"])
        EmberLogger.home.error("error with exception", err)
        EmberLogger.reminders.error("reminder error with exception", err)
    }
}
