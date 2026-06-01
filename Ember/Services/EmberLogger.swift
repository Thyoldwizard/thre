// EmberLogger.swift
import OSLog

struct EmberLogger {
    static let home = EmberLogger(category: "ember.home")
    static let reminders = EmberLogger(category: "ember.reminders")
    static let records = EmberLogger(category: "ember.records")
    static let widget = EmberLogger(category: "ember.widget")

    private let logger: Logger

    private init(category: String) {
        logger = Logger(subsystem: "com.ember.focus", category: category)
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    func error(_ message: String, _ error: (any Error)? = nil) {
        if let error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .public)")
        }
    }
}
