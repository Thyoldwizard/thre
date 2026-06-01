import SwiftUI
import SwiftData

struct ScheduleTimelineScreen: View {
    @Environment(EmberRouter.self) private var router
    @Query private var todayTasks: [EmberTask]

    private let calendar = Calendar.current
    private let timelineStartHour = 6
    private let timelineEndHour = 23
    private let pointsPerHour: CGFloat = 92
    private let hourLabelWidth: CGFloat = 54
    private let cardHeight: CGFloat = 82
    private let cardSpacing: CGFloat = 14

    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel
    private let row = EmberColors.nestedRow
    private let raised = EmberColors.raisedElement
    private let border = EmberColors.divider
    private let divider = EmberColors.divider
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private let textMuted = EmberColors.textTertiary
    private var ember: Color { EmberColors.ember }

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { $0.dayDate >= today && $0.dayDate < tomorrow },
            sort: \EmberTask.displayOrder
        )
    }

    private var scheduledTasks: [EmberTask] {
        todayTasks
            .filter { $0.scheduledTime != nil }
            .sorted {
                guard let lhs = $0.scheduledTime, let rhs = $1.scheduledTime else { return false }
                if lhs == rhs { return $0.displayOrder < $1.displayOrder }
                return lhs < rhs
            }
    }

    private var completedScheduledCount: Int {
        scheduledTasks.filter(\.isCompleted).count
    }

    private var timelineRangeHours: Int {
        timelineEndHour - timelineStartHour
    }

    private var timelineHeight: CGFloat {
        CGFloat(timelineRangeHours) * pointsPerHour + cardHeight
    }

    private var nowMarkerOffset: CGFloat? {
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        guard let hour = components.hour, let minute = components.minute else { return nil }
        guard hour >= timelineStartHour && hour <= timelineEndHour else { return nil }
        return yOffset(forHour: hour, minute: minute)
    }

    var body: some View {
        GeometryReader { geo in
            let viewportWidth = max(0, geo.size.width - (EmberSpacing.screenHorizontal * 2))
            let contentWidth = max(
                0,
                geo.size.width - (EmberSpacing.screenHorizontal * 2) - 36 - 16 - hourLabelWidth - 14
            )
            let placements = timelinePlacements(contentWidth: contentWidth)

            ZStack {
                background.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        topBar
                            .padding(.top, 18)

                        summaryPanel

                        if scheduledTasks.isEmpty {
                            emptyState
                        } else {
                            timelinePanel(contentWidth: contentWidth, placements: placements)
                                .frame(width: viewportWidth, alignment: .leading)
                                .clipped()
                        }
                    }
                    .padding(.horizontal, EmberSpacing.screenHorizontal)
                    .frame(width: viewportWidth, alignment: .leading)
                    .padding(.bottom, max(32, geo.safeAreaInsets.bottom + 24))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                router.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(raised))
                    .overlay(Circle().strokeBorder(border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 4) {
                Text("SCHEDULE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.8)
                    .foregroundStyle(textSecondary)

                Text(dateLine)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(textPrimary)
            }

            Spacer()

            Text("\(scheduledTasks.count)")
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(textPrimary)
                .frame(width: 42, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .fill(raised)
                        .overlay(
                            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                                .strokeBorder(border, lineWidth: 1)
                        )
                )
                .accessibilityLabel("\(scheduledTasks.count) scheduled tasks")
        }
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Timeline")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(textPrimary)

                Spacer(minLength: 12)

                Text("\(completedScheduledCount)/\(scheduledTasks.count) done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack(spacing: 12) {
                summaryCell(title: "First", value: scheduledTasks.first.flatMap { formattedTime($0.scheduledTime) } ?? "--")
                summaryCell(title: "Last", value: scheduledTasks.last.flatMap { formattedTime($0.scheduledTime) } ?? "--")
                summaryCell(title: "Open", value: "\(max(0, scheduledTasks.count - completedScheduledCount))")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                .fill(panel)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                )
        )
    }

    private func summaryCell(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(textMuted)

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timelinePanel(
        contentWidth: CGFloat,
        placements: [TaskPlacement]
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Operating View")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(textSecondary)

                Spacer()

                Text("6 AM-11 PM")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(textMuted)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                    .fill(panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                            .strokeBorder(border, lineWidth: 1)
                    )

                timelineGrid(contentWidth: contentWidth)

                if let nowMarkerOffset {
                    currentTimeMarker(contentWidth: contentWidth)
                        .offset(y: nowMarkerOffset)
                }

                ForEach(placements) { placement in
                    timelineTaskCard(task: placement.task, width: placement.width)
                        .frame(width: placement.width, height: cardHeight)
                        .offset(x: hourLabelWidth + 14 + placement.xOffset, y: placement.yOffset)
                }
            }
            .frame(height: timelineHeight + 28)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                .fill(panel)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                )
        )
    }

    private func timelineGrid(contentWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(timelineStartHour...timelineEndHour, id: \.self) { hour in
                let y = yOffset(forHour: hour, minute: 0)

                HStack(alignment: .top, spacing: 14) {
                    Text(hourLabel(for: hour))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(textMuted)
                        .frame(width: hourLabelWidth, alignment: .leading)

                    Rectangle()
                        .fill(divider)
                        .frame(height: 1)
                        .frame(width: contentWidth, alignment: .leading)
                }
                .offset(y: y)
            }
        }
        .padding(.top, 14)
        .padding(.leading, 16)
    }

    private func currentTimeMarker(contentWidth: CGFloat) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(ember)
                .frame(width: 7, height: 7)

            Rectangle()
                .fill(ember.opacity(0.9))
                .frame(width: contentWidth + 6, height: 1)
        }
        .padding(.leading, hourLabelWidth + 8)
        .padding(.top, 14)
        .accessibilityHidden(true)
    }

    private func timelineTaskCard(task: EmberTask, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Text(slotLabel(for: task))
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(ember)

                VStack(alignment: .leading, spacing: 5) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? textSecondary : textPrimary)
                        .strikethrough(task.isCompleted, color: textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(formattedTime(task.scheduledTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(textSecondary)
                }

                Spacer(minLength: 8)

                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(task.isCompleted ? ember : textMuted)
            }

            HStack(spacing: 8) {
                if !task.subtasks.isEmpty {
                    timelinePill("\(completedSubtasks(for: task))/\(task.subtasks.count) subtasks")
                }

                if task.isCarriedForward {
                    timelinePill("carried")
                }

                if task.subtasks.isEmpty && !task.isCarriedForward {
                    timelinePill(task.isCompleted ? "closed" : "live")
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(row)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(task.isCompleted ? border : ember.opacity(0.30), lineWidth: 1)
                )
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(task.isCompleted ? textMuted : ember)
                .frame(width: 3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: task))
    }

    private func timelinePill(_ label: String) -> some View {
        Text(label.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(1.2)
            .foregroundStyle(textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.04))
                    .overlay(Capsule().strokeBorder(border, lineWidth: 1))
            )
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("No scheduled blocks")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(textPrimary)

            Text("Add a time to one of today’s three tasks and it will land here.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textSecondary)

            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panel)
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(border, style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                )
                .overlay {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(textMuted)

                        Text("Schedule stays quiet until you place a task on the day.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(textMuted)
                    }
                }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                .fill(panel)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                        .strokeBorder(border, lineWidth: 1)
                )
        )
    }

    private func timelinePlacements(contentWidth: CGFloat) -> [TaskPlacement] {
        let tasks = scheduledTasks
        guard !tasks.isEmpty else { return [] }

        let columns = max(1, laneAssignments(for: tasks).map(\.lane).max().map { $0 + 1 } ?? 1)
        let totalSpacing = CGFloat(columns - 1) * cardSpacing
        let cardWidth = max(132, (contentWidth - totalSpacing) / CGFloat(columns))

        return laneAssignments(for: tasks).map { item in
            TaskPlacement(
                task: item.task,
                xOffset: CGFloat(item.lane) * (cardWidth + cardSpacing),
                yOffset: yOffset(for: item.task),
                width: cardWidth
            )
        }
    }

    private func laneAssignments(for tasks: [EmberTask]) -> [(task: EmberTask, lane: Int)] {
        var laneBottoms: [CGFloat] = []
        var assignments: [(task: EmberTask, lane: Int)] = []

        for task in tasks {
            let top = yOffset(for: task)
            let lane = laneBottoms.firstIndex(where: { top >= $0 + 10 }) ?? laneBottoms.count

            if lane == laneBottoms.count {
                laneBottoms.append(top + cardHeight)
            } else {
                laneBottoms[lane] = top + cardHeight
            }

            assignments.append((task: task, lane: lane))
        }

        return assignments
    }

    private func yOffset(for task: EmberTask) -> CGFloat {
        guard let scheduledTime = task.scheduledTime else { return 0 }
        let components = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        return yOffset(forHour: components.hour ?? timelineStartHour, minute: components.minute ?? 0)
    }

    private func yOffset(forHour hour: Int, minute: Int) -> CGFloat {
        let clampedHour = max(timelineStartHour, min(hour, timelineEndHour))
        let minutesFromStart = ((clampedHour - timelineStartHour) * 60) + minute
        return CGFloat(minutesFromStart) / 60 * pointsPerHour
    }

    private func hourLabel(for hour: Int) -> String {
        let date = calendar.date(from: DateComponents(hour: hour)) ?? .now
        return date.formatted(.dateTime.hour(.defaultDigits(amPM: .abbreviated)))
            .lowercased()
    }

    private var dateLine: String {
        Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func formattedTime(_ date: Date?) -> String {
        guard let date else { return "--" }
        return date.formatted(.dateTime.hour().minute())
    }

    private func completedSubtasks(for task: EmberTask) -> Int {
        task.subtasks.filter(\.isCompleted).count
    }

    private func slotLabel(for task: EmberTask) -> String {
        String(format: "%02d", task.displayOrder + 1)
    }

    private func accessibilityLabel(for task: EmberTask) -> String {
        var segments = [slotLabel(for: task), task.title, formattedTime(task.scheduledTime)]
        if task.isCompleted {
            segments.append("completed")
        }
        if task.isCarriedForward {
            segments.append("carried forward")
        }
        if !task.subtasks.isEmpty {
            segments.append("\(completedSubtasks(for: task)) of \(task.subtasks.count) subtasks completed")
        }
        return segments.joined(separator: ", ")
    }
}

private struct TaskPlacement: Identifiable {
    let task: EmberTask
    let xOffset: CGFloat
    let yOffset: CGFloat
    let width: CGFloat

    var id: UUID { task.id }
}

private func schedulePreviewTime(on day: Date, hour: Int, minute: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: day)
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? day
}

private struct ScheduleTimelinePreviewHost: View {
    private let container: ModelContainer

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(
            for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
            configurations: config
        )

        let context = container.mainContext
        let today = Calendar.current.startOfDay(for: Date())

        let first = EmberTask(
            title: "Studio standup",
            displayOrder: 0,
            dayDate: today,
            scheduledTime: schedulePreviewTime(on: today, hour: 8, minute: 30)
        )

        let second = EmberTask(
            title: "Ship schedule timeline",
            displayOrder: 1,
            dayDate: today,
            scheduledTime: schedulePreviewTime(on: today, hour: 13, minute: 0)
        )
        second.subtasks = [
            Subtask(title: "Layout grid", displayOrder: 0),
            Subtask(title: "Wire route", displayOrder: 1)
        ]
        second.subtasks[0].isCompleted = true

        let third = EmberTask(
            title: "Evening review call",
            displayOrder: 2,
            dayDate: today,
            isCarriedForward: true,
            scheduledTime: schedulePreviewTime(on: today, hour: 18, minute: 15)
        )
        third.isCompleted = true
        third.completionDate = Date()

        context.insert(first)
        context.insert(second)
        context.insert(third)
    }

    var body: some View {
        NavigationStack {
            ScheduleTimelineScreen()
                .environment(EmberRouter())
        }
        .modelContainer(container)
    }
}

#Preview("Timeline") {
    ScheduleTimelinePreviewHost()
}
