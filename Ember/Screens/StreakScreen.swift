// StreakScreen.swift
// Dark studio rhythm and calendar surface.
import SwiftUI
import SwiftData

struct StreakScreen: View {

    // MARK: - Queries
    @Query(sort: \DailyRecord.date, order: .reverse) private var records: [DailyRecord]
    @Query(sort: \EmberTask.displayOrder) private var tasks: [EmberTask]
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    // MARK: - State
    @State private var displayedMonth: Date = Date()
    @State private var activeSheet: ActiveSheet?
    @State private var longPressedDate: Date?

    // MARK: - Studio tokens (locked Ember color set)
    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel        // #121212 — section panels
    private let panelElevated = EmberColors.raisedElement // #242424 — tiles / circular controls
    private let panelMuted = EmberColors.nestedRow      // #1A1A1A — dim / empty markers
    private let textPrimary = EmberColors.textPrimary   // #F5F0E8
    private let textSecondary = EmberColors.textSecondary // #8A8680
    private let hairline = EmberColors.divider          // rgba(245,240,232,0.08)
    private var ember: Color { EmberColors.ember }

    // MARK: - Computed
    private var currentStreak: Int { StreakService.shared.currentStreak(from: records) }
    private var longestStreak: Int { StreakService.shared.longestStreak(from: records) }
    private var totalCompletedDays: Int { StreakService.shared.totalCompletedDays(from: records) }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var monthYearLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    heroPanel
                    repairCTAPanel
                    analyticsPanel
                    calendarPanel
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .history(let selectedHistoryDate):
                DayHistorySheet(
                    date: selectedHistoryDate,
                    record: record(for: selectedHistoryDate),
                    tasks: tasks(for: selectedHistoryDate),
                    reflection: reflection(for: selectedHistoryDate)
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(background)

            case .reflection(let selectedReflectionDate):
                if let reflection = reflection(for: selectedReflectionDate) {
                    PastReflectionSheet(reflection: reflection)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackground(background)
                }
            }
        }
        .onChange(of: activeSheet?.id) { _, newValue in
            if newValue == nil {
                longPressedDate = nil
            }
        }
    }

    // MARK: - Layout
    private var topBar: some View {
        HStack {
            Button {
                router.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(panelElevated))
                    .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("streak.back")

            Spacer()

            Text("RHYTHM")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.0)
                .foregroundStyle(textSecondary)

            Spacer()

            Circle()
                .fill(panelElevated)
                .frame(width: 42, height: 42)
                .overlay(
                    ZStack {
                        Circle()
                            .strokeBorder(hairline, lineWidth: 1)
                            .frame(width: 18, height: 18)

                        Circle()
                            .fill(ember)
                            .frame(width: 7, height: 7)
                    }
                )
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CURRENT STREAK")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.0)
                .foregroundStyle(textSecondary)

            HStack(alignment: .bottom, spacing: 12) {
                Text("\(currentStreak)")
                    .font(.system(size: 104, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(textPrimary)
                    .minimumScaleFactor(0.7)

                Text(currentStreak == 1 ? "DAY" : "DAYS")
                    .font(.system(size: 30, weight: .thin))
                    .tracking(1.2)
                    .foregroundStyle(textPrimary.opacity(0.72))
                    .padding(.bottom, 18)
            }

            weekStrip

            HStack(spacing: 10) {
                statBlock(value: longestStreak, label: "best")
                statBlock(value: totalCompletedDays, label: "perfect")
            }
        }
        .padding(20)
        .background(studioPanel)
    }

    // Streak Proof — half-fill day circles for the last 7 days.
    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(recentWeekDays, id: \.self) { date in
                weekDayCircle(date)
            }
        }
    }

    private func weekDayCircle(_ date: Date) -> some View {
        let rec = record(for: date)
        let completed = rec?.completedCount ?? 0
        let fraction = min(1, CGFloat(completed) / 3)
        let isToday = Calendar.current.isDateInToday(date)
        let isFrozen = rec?.isFrozen ?? false

        return VStack(spacing: 7) {
            ZStack(alignment: .bottom) {
                Circle().fill(panelMuted)

                if completed >= 3 {
                    Circle().fill(ember)
                } else if isFrozen {
                    Circle().fill(ember.opacity(0.4))
                } else if fraction > 0 {
                    Rectangle()
                        .fill(ember.opacity(0.92))
                        .frame(height: 30 * fraction)
                }
            }
            .frame(width: 30, height: 30)
            .clipShape(Circle())
            .overlay(
                Circle().strokeBorder(isToday ? ember : hairline, lineWidth: isToday ? 1.5 : 1)
            )

            Text(weekdayLetter(for: date))
                .font(.system(size: 10, weight: isToday ? .semibold : .medium))
                .foregroundStyle(isToday ? ember : textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(date.emberShortDate), \(completed) of 3 completed")
    }

    private var calendarPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(panelElevated))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(textPrimary)

                Spacer()

                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isCurrentMonth ? textSecondary.opacity(0.35) : textPrimary)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(panelElevated.opacity(isCurrentMonth ? 0.5 : 1)))
                }
                .disabled(isCurrentMonth)
                .buttonStyle(.plain)
            }

            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                spacing: 8
            ) {
                ForEach(Array(calendarDays.enumerated()), id: \.0) { _, maybeDate in
                    if let date = maybeDate {
                        dayCell(for: date)
                    } else {
                        Color.clear.frame(width: 36, height: 36)
                    }
                }
            }

            if records.isEmpty {
                Text("Complete all 3 tasks to light up a day")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .background(studioPanel)
    }

    // Insight Card — small accent glyph/header + plain-language interpretation,
    // body greyscale, with supporting stat tiles beneath.
    private var analyticsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ember)

                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.0)
                    .foregroundStyle(textSecondary)

                Spacer()

                Text(rhythmLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textSecondary)
            }

            Text(insightSentence)
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(3)
                .foregroundStyle(textPrimary.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                metricBlock(value: partialDayCount, label: "partial")
                metricBlock(value: carriedTaskCount, label: "carried")
                metricBlock(value: averageCompletionText, label: "avg")
            }
        }
        .padding(20)
        .background(studioPanel)
    }

    // MARK: - Components
    private var studioPanel: some View {
        RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
            .fill(panel)
            .overlay(
                RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                    .strokeBorder(hairline, lineWidth: 1)
            )
    }

    private func statBlock(value: Int, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(.system(size: 28, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(textPrimary)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(EmberColors.nestedRow)
        )
    }

    private func metricBlock(value: some CustomStringConvertible, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value.description)
                .font(.system(size: 22, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(EmberColors.nestedRow)
        )
    }

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let calendar = Calendar.current
        let record = record(for: date)
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()
        let dayNum = calendar.component(.day, from: date)
        let completed = record?.completedCount ?? 0
        let isPast = !isToday && !isFuture && record == nil
        let isFrozen = record?.isFrozen ?? false

        let fillColor: Color = {
            if isFuture { return Color.clear }
            if isFrozen { return panelMuted.opacity(0.5) }
            switch completed {
            case 3: return ember
            case 2: return textPrimary.opacity(0.55)
            case 1: return textPrimary.opacity(0.26)
            default: return isPast || record != nil ? panelMuted : Color.clear
            }
        }()

        let numColor: Color = {
            if isFuture { return textSecondary.opacity(0.32) }
            if isFrozen { return ember }
            if completed >= 2 { return background }
            if completed == 1 { return textPrimary }
            return textSecondary
        }()

        Button {
            let selectedDate = Calendar.current.startOfDay(for: date)
            if longPressedDate == selectedDate {
                longPressedDate = nil
                return
            }
            guard !isFuture else { return }
            activeSheet = .history(selectedDate)
        } label: {
            ZStack {
                Circle()
                    .fill(fillColor)
                    .frame(width: 36, height: 36)

                if isFrozen {
                    Circle()
                        .strokeBorder(ember.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round, dash: [3, 2]))
                        .frame(width: 36, height: 36)
                } else {
                    Circle()
                        .strokeBorder(isToday ? ember : Color.clear, lineWidth: 1.4)
                        .frame(width: 36, height: 36)
                }

                Text("\(dayNum)")
                    .font(.system(size: 15, weight: (completed >= 1 || isFrozen) ? .semibold : .regular))
                    .foregroundStyle(numColor)
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .onLongPressGesture(minimumDuration: 0.45) {
            guard !isFuture else { return }
            let selectedDate = Calendar.current.startOfDay(for: date)
            guard reflection(for: selectedDate) != nil else { return }
            longPressedDate = selectedDate
            activeSheet = .reflection(selectedDate)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(historyAccessibilityLabel(for: date, record: record))
    }

    // MARK: - Helpers
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        comps.day = 1
        let firstOfMonth = calendar.date(from: comps)!
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 0..<range.count {
            days.append(calendar.date(byAdding: .day, value: day, to: firstOfMonth))
        }

        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: nil, count: 7 - remainder)
        }
        return days
    }

    private var recentWeekDays: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset - 6, to: today)
        }
    }

    private var partialDayCount: Int {
        records.filter { $0.completedCount > 0 && !$0.allThreeCompleted }.count
    }

    private var carriedTaskCount: Int {
        tasks.filter(\.isCarriedForward).count
    }

    private var averageCompletionText: String {
        let activeRecords = records.filter { $0.taskCount > 0 }
        guard !activeRecords.isEmpty else { return "0%" }

        let completed = activeRecords.reduce(0) { $0 + min($1.completedCount, 3) }
        let possible = activeRecords.reduce(0) { $0 + min(max($1.taskCount, 1), 3) }
        guard possible > 0 else { return "0%" }

        return "\(Int((Double(completed) / Double(possible) * 100).rounded()))%"
    }

    private var rhythmLabel: String {
        let perfectThisWeek = recentWeekDays.filter { record(for: $0)?.allThreeCompleted == true }.count
        if perfectThisWeek == 7 { return "FULL WEEK" }
        if perfectThisWeek > 0 { return "\(perfectThisWeek)/7 PERFECT" }
        if recentWeekDays.contains(where: { (record(for: $0)?.completedCount ?? 0) > 0 }) { return "PARTIAL WEEK" }
        return "QUIET WEEK"
    }

    private var insightSentence: String {
        let perfect = recentWeekDays.filter { record(for: $0)?.allThreeCompleted == true }.count
        let active = recentWeekDays.filter { (record(for: $0)?.completedCount ?? 0) > 0 }.count
        if perfect == 7 { return "A clean week — all three, every day. This is the rhythm." }
        if perfect > 0 { return "You completed all three on \(perfect) of the last 7 days, and showed up on \(active)." }
        if active > 0 { return "You showed up on \(active) of the last 7 days. Finish one full day to start a streak." }
        return "A quiet week. Choose three today and begin again."
    }

    private func record(for date: Date) -> DailyRecord? {
        records.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func tasks(for date: Date) -> [EmberTask] {
        tasks
            .filter { Calendar.current.isDate($0.dayDate, inSameDayAs: date) }
            .sorted { $0.displayOrder < $1.displayOrder }
    }

    private func reflection(for date: Date) -> Reflection? {
        reflections.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func historyAccessibilityLabel(for date: Date, record: DailyRecord?) -> String {
        let completed = record?.completedCount ?? 0
        let chosen = record?.taskCount ?? 0
        return "\(date.emberShortDate), \(completed) of \(chosen) completed"
    }

    private func weekdayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        withAnimation(EmberAnimation.fadeIn) { displayedMonth = newMonth }
    }

    // MARK: - Streak Repair Helpers

    private var showRepairCTA: Bool {
        let calendar = Calendar.current
        let yesterday = DateService.shared.yesterday
        let yesterdayRecord = record(for: yesterday)

        // Yesterday is a gap if there is no record for yesterday, or it is neither completed nor frozen
        let isYesterdayGap = yesterdayRecord == nil || (!yesterdayRecord!.allThreeCompleted && !yesterdayRecord!.isFrozen)

        guard isYesterdayGap else { return false }

        // Check if a freeze was already used in the current month
        let currentMonth = calendar.component(.month, from: DateService.shared.now)
        let currentYear = calendar.component(.year, from: DateService.shared.now)
        let hasUsedFreezeThisMonth = EmberPreferences.freezeUsedDates.contains { date in
            calendar.component(.month, from: date) == currentMonth &&
            calendar.component(.year, from: date) == currentYear
        }

        return !hasUsedFreezeThisMonth
    }

    private func repairYesterday() {
        let yesterday = DateService.shared.yesterday

        // 1. Consume the freeze
        var currentFreezes = EmberPreferences.freezeUsedDates
        currentFreezes.append(DateService.shared.now)
        EmberPreferences.freezeUsedDates = currentFreezes

        // 2. Flip/create yesterday's record
        if let existing = record(for: yesterday) {
            existing.isFrozen = true
        } else {
            let newRecord = DailyRecord(date: yesterday, taskCount: 0, completedCount: 0, isFrozen: true)
            modelContext.insert(newRecord)
        }

        do {
            try modelContext.save()
        } catch {
            EmberLogger.records.error("Failed to save frozen yesterday record", error)
        }
    }

    // Prose Status Line / Insight Card — quiet at-risk treatment, not a loud warning box.
    @ViewBuilder
    private var repairCTAPanel: some View {
        if showRepairCTA {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ember)

                    Text("STREAK AT RISK")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(3.0)
                        .foregroundStyle(textSecondary)
                }

                Text("Yesterday's streak broke. You have one monthly freeze left — use it to keep the streak whole.")
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(3)
                    .foregroundStyle(textPrimary.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    withAnimation(.bouncy) {
                        repairYesterday()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Repair yesterday")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(ember)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("streak.repair")
            }
            .padding(20)
            .background(studioPanel)
            .transition(.opacity)
        }
    }
}

private enum ActiveSheet: Identifiable {
    case history(Date)
    case reflection(Date)

    var id: String {
        switch self {
        case .history(let date):
            return "history-\(date.timeIntervalSince1970)"
        case .reflection(let date):
            return "reflection-\(date.timeIntervalSince1970)"
        }
    }
}

private struct DayHistorySheet: View {
    let date: Date
    let record: DailyRecord?
    let tasks: [EmberTask]
    let reflection: Reflection?

    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel
    private let panelElevated = EmberColors.nestedRow
    private let panelMuted = EmberColors.raisedElement
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private let hairline = EmberColors.divider
    private var ember: Color { EmberColors.ember }
    private let slotTwo = EmberColors.textTertiary
    private let slotThree = EmberColors.textTertiary

    private var completedCount: Int { record?.completedCount ?? tasks.filter(\.isCompleted).count }
    private var taskCount: Int { record?.taskCount ?? tasks.count }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerPanel
                    taskSlotsPanel

                    if let reflection, !reflection.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        reflectionPanel(reflection)
                    }
                }
                .padding(18)
                .padding(.bottom, 18)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateLabel)
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.0)
                .foregroundStyle(textSecondary)

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(completedCount)/3")
                    .font(.system(size: 58, weight: .thin))
                    .monospacedDigit()
                    .foregroundStyle(completedCount == 3 ? ember : (record?.isFrozen == true ? ember : textPrimary))

                Text(statusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(textSecondary)
                    .padding(.bottom, 10)
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index < completedCount ? ember : panelMuted)
                        .frame(height: 5)
                }
            }
        }
        .padding(18)
        .background(studioPanel)
    }

    private var taskSlotsPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TASKS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.0)
                .foregroundStyle(textSecondary)

            ForEach(0..<3, id: \.self) { slot in
                if let task = task(for: slot) {
                    historyTaskRow(task, slot: slot)
                } else {
                    emptyTaskRow(slot: slot)
                }
            }
        }
        .padding(18)
        .background(studioPanel)
    }

    private func reflectionPanel(_ reflection: Reflection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REFLECTION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.0)
                .foregroundStyle(textSecondary)

            Text(reflection.text)
                .font(.system(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(textPrimary)
        }
        .padding(18)
        .background(studioPanel)
    }

    private func historyTaskRow(_ task: EmberTask, slot: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            slotNumber(slot)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? textSecondary : textPrimary)
                        .strikethrough(task.isCompleted, color: textSecondary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? ember : textSecondary)
                }

                HStack(spacing: 6) {
                    if let scheduledTime = task.scheduledTime {
                        pill(formattedTime(scheduledTime))
                    }

                    if !task.subtasks.isEmpty {
                        pill("\(completedSubtasks(for: task))/\(task.subtasks.count) subtasks")
                    }

                    if task.isCarriedForward {
                        pill("carried")
                    }

                    if task.scheduledTime == nil && task.subtasks.isEmpty && !task.isCarriedForward {
                        pill(task.isCompleted ? "completed" : "open")
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panelElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(slotColor(slot).opacity(0.24), lineWidth: 1)
                )
        )
    }

    private func emptyTaskRow(slot: Int) -> some View {
        HStack(spacing: 12) {
            slotNumber(slot)

            Text(slot < taskCount ? "No task data" : "Open slot")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textSecondary)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panelElevated.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(slotColor(slot).opacity(0.16), lineWidth: 1)
                )
        )
    }

    private func slotNumber(_ slot: Int) -> some View {
        Text(String(format: "%02d", slot + 1))
            .font(.system(size: 30, weight: .thin))
            .monospacedDigit()
            .foregroundStyle(slotColor(slot).opacity(0.72))
            .frame(width: 44, alignment: .leading)
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(panelMuted))
    }

    private var studioPanel: some View {
        RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
            .fill(panel)
            .overlay(
                RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                    .strokeBorder(hairline, lineWidth: 1)
            )
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date).uppercased()
    }

    private var statusLabel: String {
        if record?.isFrozen == true { return "FROZEN" }
        if completedCount == 3 && taskCount == 3 { return "COMPLETE" }
        if completedCount > 0 { return "IN MOTION" }
        if taskCount > 0 { return "CHOSEN" }
        return "UNSHAPED"
    }

    private func task(for slot: Int) -> EmberTask? {
        if let task = tasks.first(where: { $0.displayOrder == slot }) {
            return task
        }

        guard tasks.indices.contains(slot) else { return nil }
        return tasks[slot]
    }

    private func completedSubtasks(for task: EmberTask) -> Int {
        task.subtasks.filter(\.isCompleted).count
    }

    private func slotColor(_ slot: Int) -> Color {
        switch slot {
        case 0: return ember
        case 1: return slotTwo
        default: return slotThree
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
