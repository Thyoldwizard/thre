import XCTest
@testable import Ember

@MainActor
final class EmberPreferencesTests: XCTestCase {

    override func setUp() async throws {
        EmberPreferences.resetForUITesting()
    }

    override func tearDown() async throws {
        EmberPreferences.resetForUITesting()
    }

    // MARK: - dismissedAutoSessions JSON round-trip

    func testDismissAndCheckSameTask() {
        let id = UUID()
        EmberPreferences.dismissAutoSession(for: id)
        XCTAssertTrue(EmberPreferences.hasAutoSessionBeenDismissed(for: id))
    }

    func testUndismissedTaskReturnsFalse() {
        let id = UUID()
        XCTAssertFalse(EmberPreferences.hasAutoSessionBeenDismissed(for: id))
    }

    func testDismissTwoDistinctTasksIndependently() {
        let id1 = UUID()
        let id2 = UUID()
        EmberPreferences.dismissAutoSession(for: id1)

        XCTAssertTrue(EmberPreferences.hasAutoSessionBeenDismissed(for: id1))
        XCTAssertFalse(EmberPreferences.hasAutoSessionBeenDismissed(for: id2))
    }

    func testCorruptedJSONReturnsEmpty() {
        let corruptData = Data("not valid json".utf8)
        UserDefaults.standard.set(corruptData, forKey: EmberPreferenceKey.dismissedAutoSessions)

        let id = UUID()
        XCTAssertFalse(EmberPreferences.hasAutoSessionBeenDismissed(for: id),
                       "Corrupted JSON must fall back to empty, returning false")
    }

    func testMissingJSONDataReturnsEmpty() {
        UserDefaults.standard.removeObject(forKey: EmberPreferenceKey.dismissedAutoSessions)
        let id = UUID()
        XCTAssertFalse(EmberPreferences.hasAutoSessionBeenDismissed(for: id))
    }

    // MARK: - freezeUsedDates round-trip

    func testFreezeUsedDatesRoundTrip() {
        let dates = [Date(), Date(timeIntervalSinceNow: 86400)]
        EmberPreferences.freezeUsedDates = dates

        let loaded = EmberPreferences.freezeUsedDates
        XCTAssertEqual(loaded.count, dates.count)
        for (stored, original) in zip(loaded, dates) {
            XCTAssertEqual(stored.timeIntervalSinceReferenceDate,
                           original.timeIntervalSinceReferenceDate, accuracy: 1)
        }
    }

    func testFreezeUsedDatesDefaultsToEmpty() {
        XCTAssertTrue(EmberPreferences.freezeUsedDates.isEmpty)
    }
}
