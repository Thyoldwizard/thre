// HomeScreenWidgetView.swift
// Medium + Large widget — shows today's 3 tasks with completion state.
// Colors defined inline (matching EmberColors exactly) — no main-app dependency.
import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Widget Color Palette (mirrors EmberColors exactly)

private enum WC {
    static let background = Color(red: 0.027, green: 0.027, blue: 0.027) // #070707
    static let cardSurface = Color(red: 0.110, green: 0.110, blue: 0.110) // #1C1C1C
    static let textPrimary = Color(red: 0.969, green: 0.953, blue: 0.918) // #F7F3EA
    static let textSecondary = Color(red: 0.545, green: 0.545, blue: 0.525) // #8B8B86
    static let textTertiary = Color(red: 0.361, green: 0.361, blue: 0.349)
    static let textDone = Color(red: 0.420, green: 0.396, blue: 0.376)
    static let accent = Color(red: 1.000, green: 0.416, blue: 0.000) // #FF6A00
    static let ember = Color(red: 1.000, green: 0.416, blue: 0.000)
    static let glassStroke  = Color.white.opacity(0.08)
    static let streakMark = ember
}

// MARK: - Home Screen Widget View

struct HomeScreenWidgetView: View {
    let entry: EmberWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        ZStack {
            WC.background

            // Subtle ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [WC.ember.opacity(0.25), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 40)
                .offset(y: -60)

            VStack(alignment: .leading, spacing: 10) {
                // Header row
                headerRow

                // Task rows
                VStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        if let task = entry.tasks[safe: index] {
                            Button(intent: CompleteTaskIntent(taskID: task.id.uuidString)) {
                                taskRowContent(task: task)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Complete \(task.title)")
                        } else {
                            emptySlotRow
                        }
                    }
                }

                if entry.tasks.count < 3 {
                    addFocusButton
                }

                // Large widget only: progress summary
                if family == .systemLarge {
                    Spacer()
                    progressFooter
                }
            }
            .padding(16)
        }
        .containerBackground(for: .widget) { WC.background }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text(Date().emberWidgetDateHeader)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(WC.textPrimary)

            Spacer()

            if entry.streakCount > 0 {
                HStack(spacing: 3) {
                    Circle()
                        .strokeBorder(WC.streakMark.opacity(0.32), lineWidth: 1)
                        .frame(width: 11, height: 11)
                        .overlay {
                            Circle()
                                .fill(WC.streakMark)
                                .frame(width: 4, height: 4)
                        }
                    Text("\(entry.streakCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WC.textPrimary)
                }
            }
        }
    }

    // MARK: - Task Row

    private func taskRowContent(task: TaskSnapshot) -> some View {
        HStack(spacing: 8) {
            // Completion dot
            Circle()
                .fill(task.isCompleted ? WC.accent : WC.textTertiary.opacity(0.4))
                .frame(width: 6, height: 6)

            // Title
            Text(task.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(task.isCompleted ? WC.textDone : WC.textPrimary)
                .strikethrough(task.isCompleted, color: WC.textDone)
                .lineLimit(1)

            Spacer()

            // Completed checkmark
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(WC.accent)
            }

            // Carried forward indicator
            if task.isCarriedForward && !task.isCompleted {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 10))
                    .foregroundStyle(WC.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(WC.cardSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(WC.glassStroke, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Add Focus

    private var addFocusButton: some View {
        Button(intent: AddTaskIntent()) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Add focus")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(WC.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(WC.accent.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(WC.accent.opacity(0.24), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add focus")
    }

    // MARK: - Empty Slot Row

    private var emptySlotRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WC.textTertiary)
            Text("Add a task")
                .font(.system(size: 13))
                .foregroundStyle(WC.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    WC.textTertiary.opacity(0.2),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                )
        )
    }

    // MARK: - Large Widget Footer

    private var progressFooter: some View {
        HStack(spacing: 8) {
            // Progress dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < entry.completedCount ? WC.accent : WC.cardSurface)
                        .frame(width: 8, height: 8)
                }
            }

            Text("\(entry.completedCount)/3 completed")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(WC.textSecondary)

            Spacer()
        }
    }
}

// MARK: - Date Helper (widget-side, avoids importing Date+Extensions)

private extension Date {
    var emberWidgetDateHeader: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: self)
    }
}

// MARK: - Safe Collection Subscript (widget-side)

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
