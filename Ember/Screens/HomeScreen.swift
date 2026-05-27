// HomeScreen.swift — complete rebuild from zero
// Reference: sajon.co calendar left screen. Massive date block, two-column layout, white panel, colored cards.
import SwiftUI
import SwiftData
import Combine

struct HomeScreen: View {

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router
    @Environment(\.modelContext)   private var modelContext
    @Environment(\.scenePhase)     private var scenePhase

    // MARK: - Queries
    @Query private var todayTasks: [EmberTask]
    @Query(sort: \DailyRecord.date, order: .reverse) private var dailyRecords: [DailyRecord]
    @Query private var todayReflections: [Reflection]

    // MARK: - State
    @State private var hasAppeared = false
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // MARK: - Card colors
    private let cardColors: [Color] = [
        Color(hex: "D4B86A"),
        Color(hex: "8FA8B8"),
        Color(hex: "96B89A")
    ]

    // MARK: - Init
    init() {
        let today    = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { $0.dayDate >= today && $0.dayDate < tomorrow },
            sort: \EmberTask.displayOrder
        )
        _todayReflections = Query(
            filter: #Predicate<Reflection> { $0.date >= today && $0.date < tomorrow }
        )
    }

    // MARK: - Computed

    private var allCompleted: Bool {
        todayTasks.count == 3 && todayTasks.allSatisfy { $0.isCompleted }
    }

    private var completedCount: Int {
        todayTasks.filter { $0.isCompleted }.count
    }

    private var completionLabel: String { "\(completedCount)/3" }

    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: Date())
    }
    private var monthAbbr: String {
        let f = DateFormatter(); f.dateFormat = "MMM"
        return f.string(from: Date()).uppercased()
    }
    private var yearString: String {
        let f = DateFormatter(); f.dateFormat = "yyyy"
        return f.string(from: Date())
    }
    private var weekdayLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEEE"
        return f.string(from: Date()).uppercased()
    }
    private var timeString: String {
        let f = DateFormatter(); f.timeStyle = .short; f.dateStyle = .none
        return f.string(from: currentTime)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var bindableRouter = router

        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background — warm off-white
                Color(hex: "EEEAE3").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    // ── Navigation row ───────────────────────────────
                    HStack(spacing: 8) {
                        // "Today" black pill
                        Text("Today")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "1A1A1A"))
                            .clipShape(Capsule())

                        Spacer()

                        // "Month" warm pill — navigates to StreakScreen
                        Button {
                            router.navigate(to: .streak)
                        } label: {
                            Text("Month")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "1A1A1A"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: "E8E4DC"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        // "+" circle — add task
                        Button {
                            bindableRouter.showAddTask = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "1A1A1A"))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add a task")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // ── Date block ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        // Weekday label
                        Text(weekdayLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "9A9A9A"))
                            .tracking(3)

                        // Two-column date layout
                        HStack(alignment: .top, spacing: 0) {
                            // Left column — day number + month
                            VStack(alignment: .leading, spacing: -8) {
                                Text(dayNumber)
                                    .font(.system(size: 80, weight: .black))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text(monthAbbr)
                                    .font(.system(size: 48, weight: .black))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                            }

                            // Vertical divider
                            Rectangle()
                                .fill(Color(hex: "1A1A1A").opacity(0.15))
                                .frame(width: 1, height: 100)
                                .padding(.leading, 20)
                                .padding(.top, 12)

                            // Right column — year, time, city
                            VStack(alignment: .leading, spacing: 0) {
                                Text(yearString)
                                    .font(.system(size: 18, weight: .light))
                                    .foregroundStyle(Color(hex: "9A9A9A"))

                                Spacer().frame(height: 8)

                                Text(timeString)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                                    .onReceive(timer) { t in currentTime = t }

                                Spacer().frame(height: 4)

                                Text("Islamabad")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color(hex: "9A9A9A"))
                            }
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(weekdayLabel), \(dayNumber) \(monthAbbr) \(yearString)")

                    // ── White tasks container ────────────────────────
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 0) {
                            // Container header
                            HStack {
                                Text("Today's tasks")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color(hex: "1A1A1A"))

                                Spacer()

                                Text(completionLabel)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(hex: "9A9A9A"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 12)

                            // Cards
                            VStack(spacing: 10) {
                                ForEach(0..<3, id: \.self) { index in
                                    slotView(index: index)
                                        .opacity(hasAppeared ? 1 : 0)
                                        .offset(y: hasAppeared ? 0 : 20)
                                        .animation(
                                            EmberAnimation.staggeredCardAppear(index: index),
                                            value: hasAppeared
                                        )
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 20)

                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .frame(
                        minHeight: geo.size.height
                            - geo.safeAreaInsets.top
                            - 16   // nav top padding
                            - 44   // nav row height
                            - 20   // date top gap
                            - 140  // approximate date block height
                            - 24   // container top gap
                            - geo.safeAreaInsets.bottom,
                        alignment: .top
                    )
                    .padding(.bottom, geo.safeAreaInsets.bottom)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            triggerEntranceAnimation()
            handleDayBoundary()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { handleDayBoundary() }
        }
        .onChange(of: allCompleted) { _, isAllDone in
            if isAllDone {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    router.showTranscendence = true
                }
            }
        }
        .sheet(isPresented: $bindableRouter.showAddTask)               { AddTaskSheet() }
        .fullScreenCover(isPresented: $bindableRouter.showCarryForward) { CarryForwardView() }
        .fullScreenCover(isPresented: $bindableRouter.showTranscendence) { TranscendenceView() }
    }

    // MARK: - Slot dispatcher

    @ViewBuilder
    private func slotView(index: Int) -> some View {
        if let task = todayTasks[safe: index] {
            taskCard(task: task, color: cardColors[index])
        } else {
            emptyCard(color: cardColors[index])
        }
    }

    // MARK: - Task card

    private func taskCard(task: EmberTask, color: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(task.isCompleted ? color.opacity(0.50) : color)

            VStack(alignment: .leading, spacing: 0) {
                // Title — Bold 26pt, top-left
                Text(task.title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .opacity(task.isCompleted ? 0.45 : 1.0)
                    .strikethrough(task.isCompleted, color: Color(hex: "1A1A1A").opacity(0.5))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                    .padding(.trailing, task.isCompleted || task.isCarriedForward ? 44 : 16)

                Spacer().frame(minHeight: 16)

                // Bottom row — time info or subtask count
                bottomRow(task: task)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Completion checkmark — top right
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "1A1A1A").opacity(0.55))
                    .padding(14)
            }

            // Carried-forward badge — top right
            if task.isCarriedForward && !task.isCompleted {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 9, weight: .medium))
                    Text("carried")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.45))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "1A1A1A").opacity(0.08))
                .clipShape(Capsule())
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: task.scheduledTime != nil ? 140 : 120)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { router.navigate(to: .taskDetail(task)) }
        .contextMenu {
            Button(role: .destructive) {
                task.modelContext?.delete(task)
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
        .accessibilityLabel(task.title)
        .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
    }

    // MARK: - Bottom row (time-aware)

    @ViewBuilder
    private func bottomRow(task: EmberTask) -> some View {
        if let scheduled = task.scheduledTime {
            timeRow(scheduledTime: scheduled)
        } else {
            subtaskPill(task: task)
        }
    }

    private func timeRow(scheduledTime: Date) -> some View {
        HStack(spacing: 8) {
            // Scheduled time string
            Text(formattedTime(scheduledTime))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.80))

            // Relative time pill
            Text(relativeTimeLabel(scheduledTime))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.70))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "1A1A1A").opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .onReceive(timer) { _ in } // Triggers view refresh every minute via timer
    }

    private func subtaskPill(task: EmberTask) -> some View {
        let count = task.subtasks.count
        let label = count == 0 ? "No subtasks"
            : count == 1 ? "1 subtask"
            : "\(count) subtasks"

        return Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color(hex: "1A1A1A").opacity(0.60))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(hex: "1A1A1A").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: - Empty card

    private func emptyCard(color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color)

            Image(systemName: "plus")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.20))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 90)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture { router.showAddTask = true }
        .accessibilityLabel("Add a task")
    }

    // MARK: - Time formatting helpers

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    private func relativeTimeLabel(_ date: Date) -> String {
        let diff = date.timeIntervalSince(currentTime)
        let minutes = Int(diff / 60)

        if minutes < -60 {
            let hours = abs(minutes) / 60
            return "Overdue \(hours)h"
        } else if minutes < -5 {
            return "Overdue"
        } else if minutes <= 5 {
            return "Now"
        } else if minutes < 60 {
            return "in \(minutes)m"
        } else {
            let hours = minutes / 60
            let mins  = minutes % 60
            return mins == 0 ? "in \(hours)h" : "in \(hours)h \(mins)m"
        }
    }

    // MARK: - Helpers

    private func triggerEntranceAnimation() {
        guard !hasAppeared else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            hasAppeared = true
        }
    }

    private func handleDayBoundary() {
        guard DateService.shared.isNewDay() else {
            DateService.shared.recordActiveDate()
            return
        }
        let yesterday = DateService.shared.yesterday
        let today     = Calendar.current.date(byAdding: .day, value: 1, to: yesterday)!
        let descriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate<EmberTask> {
                $0.dayDate >= yesterday && $0.dayDate < today && $0.isCompleted == false
            }
        )
        let incomplete = (try? modelContext.fetch(descriptor)) ?? []
        if !incomplete.isEmpty { router.showCarryForward = true }
        DateService.shared.recordActiveDate()
    }
}

// MARK: - Previews

#Preview("Empty") {
    HomeScreen()
        .environment(EmberRouter())
        .modelContainer(for: [EmberTask.self, DailyRecord.self, Reflection.self], inMemory: true)
}

#Preview("With Tasks") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx   = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())

    // Task with scheduled time
    var timeComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    timeComps.hour = 15; timeComps.minute = 0
    let meetingTime = Calendar.current.date(from: timeComps)

    let t1 = EmberTask(title: "You Have A Meeting", displayOrder: 0, dayDate: today, scheduledTime: meetingTime)
    ctx.insert(t1)
    let s1 = Subtask(title: "Prep deck", displayOrder: 0); s1.task = t1; ctx.insert(s1)
    let s2 = Subtask(title: "Send invite", displayOrder: 1); s2.task = t1; ctx.insert(s2)

    // Task without scheduled time
    ctx.insert(EmberTask(title: "Call Wiz For Update", displayOrder: 1, dayDate: today))

    return HomeScreen()
        .environment(EmberRouter())
        .modelContainer(container)
}
