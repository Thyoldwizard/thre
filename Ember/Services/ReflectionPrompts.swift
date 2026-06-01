import Foundation

struct ReflectionPrompts {
    static let shared = ReflectionPrompts()

    private let dateService: DateService
    private let prompts: [String] = [
        "What changed after you showed up?",
        "Where did you stay exact instead of drifting?",
        "What earned your full attention today?",
        "Which decision moved the day forward?",
        "Where did you create real traction?",
        "What held up under pressure?",
        "Which moment felt most deliberate?",
        "What became clearer by evening?",
        "Where did your energy go on purpose?",
        "What do you trust more tonight than this morning?"
    ]

    init(dateService: DateService = .shared) {
        self.dateService = dateService
    }

    func prompt(for date: Date) -> String {
        let normalizedDate = dateService.calendar.startOfDay(for: date)
        let dayOfYear = dateService.calendar.ordinality(of: .day, in: .year, for: normalizedDate) ?? 1
        let index = dayOfYear % prompts.count
        return prompts[index]
    }
}
