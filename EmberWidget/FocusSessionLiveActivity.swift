// FocusSessionLiveActivity.swift
import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Configuration

@available(iOS 16.1, *)
struct FocusSessionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionAttributes.self) { context in
            FocusLockScreenView(
                taskTitle: context.attributes.taskTitle,
                completedCount: context.state.completedCount,
                startedAt: context.attributes.startedAt
            )
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(emberColor)
                            .frame(width: 8, height: 8)
                        Text("FOCUS")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completedCount)/3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(emberColor)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        // Mini 3-dot progress
                        HStack(spacing: 5) {
                            ForEach(0..<3, id: \.self) { i in
                                Capsule()
                                    .fill(i < context.state.completedCount ? emberColor : Color.white.opacity(0.18))
                                    .frame(width: 22, height: 4)
                            }
                        }
                        Spacer()
                        Text(context.attributes.taskTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // Compact leading — ember dot
                Circle()
                    .fill(emberColor)
                    .frame(width: 8, height: 8)
                    .padding(.leading, 4)
            } compactTrailing: {
                // Compact trailing — "1/3" progress
                Text("\(context.state.completedCount)/3")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(emberColor)
                    .monospacedDigit()
                    .padding(.trailing, 4)
            } minimal: {
                // Minimal — single ember dot
                Circle()
                    .fill(emberColor)
                    .frame(width: 10, height: 10)
            }
        }
    }

    private var emberColor: Color { Color(red: 1, green: 0.416, blue: 0) }
}

// MARK: - 8.3 Lock Screen View

@available(iOS 16.1, *)
private struct FocusLockScreenView: View {
    let taskTitle: String
    let completedCount: Int
    let startedAt: Date

    private let emberColor = Color(red: 1, green: 0.416, blue: 0)
    private let background = Color(red: 0.027, green: 0.027, blue: 0.027)
    private let textPrimary = Color(red: 0.969, green: 0.953, blue: 0.918)
    private let textSecondary = Color(red: 0.545, green: 0.545, blue: 0.525)
    private let panelColor = Color(red: 0.094, green: 0.094, blue: 0.094)

    var body: some View {
        HStack(spacing: 14) {
            // Orbit mini-view (12 dots)
            MiniOrbitView(completedCount: completedCount, accentColor: emberColor)
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(taskTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    // 3-slot progress capsules
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i < completedCount ? emberColor : textSecondary.opacity(0.28))
                                .frame(width: 18, height: 4)
                        }
                    }

                    Text("\(completedCount)/3 done")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(textSecondary)
                }
            }

            Spacer()

            // Elapsed time
            VStack(alignment: .trailing, spacing: 2) {
                Text("FOCUS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(textSecondary)

                Text(timerInterval: startedAt...Date(), countsDown: false)
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .foregroundStyle(emberColor)
                    .frame(minWidth: 44, alignment: .trailing)
            }
        }
        .padding(14)
        .background(background)
    }
}

// MARK: - Mini Orbit dots (12-dot ring for lock screen)

@available(iOS 16.1, *)
private struct MiniOrbitView: View {
    let completedCount: Int
    let accentColor: Color

    private let dotCount = 12

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.40
            let activeDots = Int(Double(completedCount) / 3.0 * Double(dotCount))

            ForEach(0..<dotCount, id: \.self) { i in
                let angle = Double(i) * (2 * Double.pi / Double(dotCount)) - Double.pi / 2
                let x = center.x + radius * CGFloat(cos(angle))
                let y = center.y + radius * CGFloat(sin(angle))

                Circle()
                    .fill(i < activeDots ? accentColor : Color.white.opacity(0.18))
                    .frame(width: i < activeDots ? 5 : 3.5,
                           height: i < activeDots ? 5 : 3.5)
                    .position(x: x, y: y)
            }

            // Center ember dot
            Circle()
                .fill(accentColor.opacity(0.72))
                .frame(width: 7, height: 7)
                .position(center)
        }
    }
}
