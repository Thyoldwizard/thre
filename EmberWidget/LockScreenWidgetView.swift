// LockScreenWidgetView.swift
import SwiftUI
import WidgetKit

// MARK: - Circular Lock Screen Widget

struct CircularLockScreenView: View {
    let entry: EmberWidgetEntry

    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 4)

            Circle()
                .trim(from: 0, to: CGFloat(entry.completedCount) / 3.0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Centre content
            VStack(spacing: 1) {
                Text("\(entry.completedCount)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("of 3")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Inline Lock Screen Widget

struct InlineLockScreenView: View {
    let entry: EmberWidgetEntry

    var body: some View {
        Group {
            if entry.streakCount > 0 {
                Label("\(entry.streakCount) day streak", systemImage: "circle.fill")
            } else {
                Label("\(entry.completedCount)/3 today", systemImage: "checkmark.circle")
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

// MARK: - Rectangular Lock Screen / StandBy Widget

struct RectangularLockScreenView: View {
    let entry: EmberWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        // Detect StandBy (landscape) vs normal lock screen rectangular.
        // StandBy widgets use .accessoryRectangular at a wider aspect ratio.
        // We use GeometryReader to adapt the layout.
        GeometryReader { geo in
            let isWide = geo.size.width > geo.size.height * 2.2  // StandBy landscape heuristic
            if isWide {
                standByLayout(geo: geo)
            } else {
                lockScreenLayout
            }
        }
        .containerBackground(for: .widget) { Color.black }
    }

    // MARK: - StandBy landscape layout

    private func standByLayout(geo: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left: compact orbit ring + count
            ZStack {
                // Orbit ring
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 3)
                    .frame(width: geo.size.height * 0.72, height: geo.size.height * 0.72)

                Circle()
                    .trim(from: 0, to: CGFloat(entry.completedCount) / 3.0)
                    .stroke(
                        Color(red: 1, green: 0.416, blue: 0),  // ember #FF6A00
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: geo.size.height * 0.72, height: geo.size.height * 0.72)

                Text("\(entry.completedCount)")
                    .font(.system(size: geo.size.height * 0.40, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            .frame(width: geo.size.height, height: geo.size.height)

            // Right: task list
            VStack(alignment: .leading, spacing: 2) {
                ForEach(0..<min(3, entry.tasks.count), id: \.self) { i in
                    let task = entry.tasks[i]
                    HStack(spacing: 5) {
                        Circle()
                            .fill(task.isCompleted
                                  ? Color(red: 1, green: 0.416, blue: 0)   // ember
                                  : Color.white.opacity(0.28))
                            .frame(width: 5, height: 5)

                        Text(task.title)
                            .font(.system(size: 11, weight: task.isCompleted ? .regular : .medium))
                            .foregroundStyle(task.isCompleted
                                             ? Color.white.opacity(0.45)
                                             : Color.white.opacity(0.92))
                            .strikethrough(task.isCompleted, color: .white.opacity(0.3))
                            .lineLimit(1)
                    }
                }

                if entry.tasks.isEmpty {
                    Text("No tasks set for today")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Normal lock screen rectangular layout

    private var lockScreenLayout: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                Text(entry.streakCount > 0
                     ? "\(entry.streakCount) day streak"
                    : "Start your streak")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)

            Text("\(entry.completedCount) of 3 tasks done")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
