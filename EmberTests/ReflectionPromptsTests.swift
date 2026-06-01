import XCTest
@testable import Ember

@MainActor
final class ReflectionPromptsTests: XCTestCase {

    private func dateForDayOfYear(_ dayOfYear: Int, year: Int = 2025) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        let jan1 = Calendar.current.date(from: components)!
        return Calendar.current.date(byAdding: .day, value: dayOfYear - 1, to: jan1)!
    }

    // MARK: - Deterministic rotation

    func testSameDateReturnsSamePrompt() {
        let date = dateForDayOfYear(5)
        let service = DateService(clock: FixedClock(now: date))
        let prompts = ReflectionPrompts(dateService: service)
        let first = prompts.prompt(for: date)
        let second = prompts.prompt(for: date)
        XCTAssertEqual(first, second)
    }

    func testDifferentDaysMayReturnDifferentPrompts() {
        let date1 = dateForDayOfYear(1)
        let date2 = dateForDayOfYear(2)
        let service = DateService(clock: FixedClock(now: date1))
        let prompts = ReflectionPrompts(dateService: service)
        // Different days should produce different indices (1 % 10 != 2 % 10)
        let p1 = prompts.prompt(for: date1)
        let p2 = prompts.prompt(for: date2)
        XCTAssertNotEqual(p1, p2)
    }

    // MARK: - Wrap at array length

    func testPromptWrapsAtArrayLength() {
        // Day of year 10 → ordinality = 10, 10 % 10 = 0 → index 0
        // Day of year 20 → ordinality = 20, 20 % 10 = 0 → index 0 (same)
        let date10 = dateForDayOfYear(10)
        let date20 = dateForDayOfYear(20)
        let service10 = DateService(clock: FixedClock(now: date10))
        let service20 = DateService(clock: FixedClock(now: date20))
        let p10 = ReflectionPrompts(dateService: service10).prompt(for: date10)
        let p20 = ReflectionPrompts(dateService: service20).prompt(for: date20)
        XCTAssertEqual(p10, p20, "Day 10 and day 20 both produce index 0 (10 % 10 == 0, 20 % 10 == 0)")
    }

    func testPromptNeverEmpty() {
        let service = DateService(clock: FixedClock(now: Date()))
        let prompts = ReflectionPrompts(dateService: service)
        for dayOfYear in 1...366 {
            let date = dateForDayOfYear(dayOfYear)
            let prompt = prompts.prompt(for: date)
            XCTAssertFalse(prompt.isEmpty, "Day \(dayOfYear) must return a non-empty prompt")
        }
    }

    // MARK: - Leap day (day 366 in a leap year)

    func testLeapDay366() {
        let leapDate = dateForDayOfYear(366, year: 2024)
        let service = DateService(clock: FixedClock(now: leapDate))
        let prompts = ReflectionPrompts(dateService: service)
        let prompt = prompts.prompt(for: leapDate)
        XCTAssertFalse(prompt.isEmpty)
    }
}
