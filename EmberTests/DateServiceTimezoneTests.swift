import XCTest
@testable import Ember

@MainActor
final class DateServiceTimezoneTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let suiteName = "com.ember.test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, tz: String) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = hour; c.minute = minute
        c.timeZone = TimeZone(identifier: tz)
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    private func calendar(tz: String) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: tz)!
        return cal
    }

    func testTodayInHonolulu() {
        // midnight UTC on June 15 = June 14 at 2pm Honolulu time (UTC-10)
        let ref = date(year: 2025, month: 6, day: 15, hour: 0, tz: "UTC")
        let honolulu = calendar(tz: "Pacific/Honolulu")
        let service = DateService(clock: FixedClock(now: ref), calendar: honolulu)

        let comps = honolulu.dateComponents([.year, .month, .day], from: service.today)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 14)
    }

    func testTodayInTokyo() {
        // 11pm UTC on June 14 = 8am June 15 in Tokyo (UTC+9)
        let ref = date(year: 2025, month: 6, day: 14, hour: 23, tz: "UTC")
        let tokyo = calendar(tz: "Asia/Tokyo")
        let service = DateService(clock: FixedClock(now: ref), calendar: tokyo)

        let comps = tokyo.dateComponents([.year, .month, .day], from: service.today)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.day, 15)
    }

    func testIsNewDayAcrossMidnight() {
        let tz = "America/New_York"
        let cal = calendar(tz: tz)

        let lastActive = date(year: 2025, month: 6, day: 14, hour: 23, minute: 30, tz: tz)
        let nowDate = date(year: 2025, month: 6, day: 15, hour: 0, minute: 1, tz: tz)

        let service = DateService(clock: FixedClock(now: nowDate), calendar: cal, userDefaults: freshDefaults())
        service.lastActiveDate = lastActive

        XCTAssertTrue(service.isNewDay())
    }

    func testIsNotNewDaySameDay() {
        let tz = "America/New_York"
        let cal = calendar(tz: tz)

        let lastActive = date(year: 2025, month: 6, day: 14, hour: 9, tz: tz)
        let nowDate = date(year: 2025, month: 6, day: 14, hour: 15, tz: tz)

        let service = DateService(clock: FixedClock(now: nowDate), calendar: cal, userDefaults: freshDefaults())
        service.lastActiveDate = lastActive

        XCTAssertFalse(service.isNewDay())
    }

    func testYesterdayIsOneDayBefore() {
        let tz = "UTC"
        let cal = calendar(tz: tz)
        let ref = date(year: 2025, month: 3, day: 1, hour: 12, tz: tz)
        let service = DateService(clock: FixedClock(now: ref), calendar: cal)

        let comps = cal.dateComponents([.year, .month, .day], from: service.yesterday)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertEqual(comps.month, 2)
        XCTAssertEqual(comps.day, 28)
    }
}
