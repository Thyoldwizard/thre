// HomeScreen.swift
// Studio dashboard direction: dark shell, Daily Orbit progress, three focus modules.
import SwiftUI
import SwiftData
import Combine
import UIKit

fileprivate struct PendingUndo: Equatable {
    let taskID: UUID
    let title: String
}

@MainActor
fileprivate enum LaunchAssemblySession {
    static var didRun = false
}

struct HomeScreen: View {

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Namespace (for matched geometry transition, injected from ContentView)
    var cardNamespace: Namespace.ID

    // MARK: - Queries
    @Query private var todayTasks: [EmberTask]
    @Query(sort: \DailyRecord.date, order: .reverse) private var dailyRecords: [DailyRecord]
    @Query private var todayReflections: [Reflection]

    // MARK: - State
    @State private var hasAppeared = false
    @State private var currentTime = Date()
    @State private var holdStartedAt: [UUID: Date] = [:]
    @State private var holdProgress: [UUID: CGFloat] = [:]
    @State private var holdLocations: [UUID: CGPoint] = [:]
    @State private var pressedTaskID: UUID?
    @State private var pendingUndo: PendingUndo?
    @State private var isReordering: Bool = false
    @State private var draggingTaskID: UUID?
    @State private var dragTranslationY: CGFloat = 0
    @State private var settingsSymbolTrigger = false
    @State private var addSymbolTrigger = false
    @State private var hasAssembled: Bool = false
    /// 6.4 — tracks last user interaction for idle breathing
    @State private var lastInteractionAt: Date = Date()
    /// 10.4 — Focus Filter: show only slot 01 when active
    @AppStorage(EmberPreferenceKey.focusFilterShowOnlyPrimary) private var focusFilterActive = false
    @AppStorage(EmberPreferenceKey.currentTheme) private var currentThemeRaw = EmberTheme.ember.rawValue
    @AppStorage(EmberPreferenceKey.oledBlackEnabled) private var oledBlackEnabled = false
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    private let holdDuration: TimeInterval = 1.5
    private let reorderSlotHeight: CGFloat = 126

    // MARK: - Visual tokens (all from the locked Ember color set)
    private var currentTheme: EmberTheme { EmberTheme(rawValue: currentThemeRaw) ?? .ember }
    private var background: Color { EmberColors.studioBackground }   // #070707 / OLED #000
    private let panel = EmberColors.primaryPanel        // #121212 — large surfaces
    private let raised = EmberColors.raisedElement      // #242424 — circular controls / pills
    private let panelMuted = EmberColors.raisedElement  // #242424 — inactive orbit dots
    private let textPrimary = EmberColors.textPrimary   // #F5F0E8 — warm off-white
    private let textSecondary = EmberColors.textSecondary // #8A8680
    private let textTertiary = EmberColors.textTertiary   // #5A5650
    private let hairline = EmberColors.divider          // rgba(245,240,232,0.08)
    private var ember: Color { currentTheme.accent }

    // Slot 01 carries the single dominant accent moment; 02 and 03 recede to
    // tertiary so the rail reads as one accent, not three (Three Focus Rail).
    private var moduleColors: [Color] {
        [
            currentTheme.accent,
            EmberColors.textTertiary,
            EmberColors.textTertiary
        ]
    }

    private let emptyPrompts = [
        "Choose one thing",
        "Choose what matters next",
        "Leave room for life"
    ]

    // MARK: - Init
    init(cardNamespace: Namespace.ID) {
        self.cardNamespace = cardNamespace
        let today = DateService.shared.today
        let tomorrow = DateService.shared.calendar.date(byAdding: .day, value: 1, to: today)!
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { $0.dayDate >= today && $0.dayDate < tomorrow },
            sort: \EmberTask.displayOrder
        )
        var reflectionDescriptor = FetchDescriptor<Reflection>(
            predicate: #Predicate<Reflection> { $0.date >= today && $0.date < tomorrow }
        )
        reflectionDescriptor.fetchLimit = 1
        _todayReflections = Query(reflectionDescriptor)
    }

    // MARK: - Computed
    private var allCompleted: Bool {
        todayTasks.count == 3 && todayTasks.allSatisfy { $0.isCompleted }
    }

    private var completedCount: Int {
        todayTasks.filter { $0.isCompleted }.count
    }

    private var hasScheduledTasks: Bool {
        todayTasks.contains { $0.scheduledTime != nil }
    }

    private var dayStateLabel: String {
        switch completedCount {
        case 0: return "chosen"
        case 1, 2: return "in motion"
        default: return "complete"
        }
    }

    private var virtualReorderIndex: Int? {
        guard let draggingID = draggingTaskID,
              let originalIndex = todayTasks.firstIndex(where: { $0.id == draggingID }) else {
            return nil
        }
        let count = todayTasks.count
        guard count > 0 else { return nil }
        let stepDelta = Int((dragTranslationY / reorderSlotHeight).rounded())
        return max(0, min(count - 1, originalIndex + stepDelta))
    }

    private func reorderOffsetY(for slotIndex: Int) -> CGFloat {
        guard let draggingID = draggingTaskID,
              let originalIndex = todayTasks.firstIndex(where: { $0.id == draggingID }) else {
            return 0
        }

        if slotIndex == originalIndex {
            return dragTranslationY
        }

        guard let virtualIndex = virtualReorderIndex else { return 0 }

        if virtualIndex < originalIndex {
            if slotIndex >= virtualIndex && slotIndex < originalIndex {
                return reorderSlotHeight
            }
        } else if virtualIndex > originalIndex {
            if slotIndex > originalIndex && slotIndex <= virtualIndex {
                return -reorderSlotHeight
            }
        }
        return 0
    }

    fileprivate static let dateLineFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    fileprivate static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    private var dateLine: String { Self.dateLineFormatter.string(from: Date()) }
    private var timeString: String { Self.timeFormatter.string(from: currentTime) }

    private var cornerVignette: some View {
        RadialGradient(
            colors: [
                Color.black.opacity(0),
                Color.black.opacity(0),
                Color.black.opacity(0.03)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 600
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Body
    var body: some View {
        @Bindable var bindableRouter = router

        ZStack(alignment: .bottom) {
            background.ignoresSafeArea()
            GrainOverlay(opacity: oledBlackEnabled ? 0.01 : 0.02)
            cornerVignette

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                        .padding(.top, 16)

                    orbitSection

                    taskGrid

                    if allCompleted {
                        completionNote
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(isReordering)

            if let pendingUndo {
                undoToast(pendingUndo)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                    // 6.3 — scale-in entrance: pops up with bouncy spring overshoot
                    .transition(
                        .scale(scale: 0.92)
                        .combined(with: .opacity)
                        .combined(with: .move(edge: .bottom))
                    )
            }

            if !hasAssembled {
                LaunchAssembly {
                    completeLaunchAssembly()
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        // 6.3 — toast uses bouncy spring so scale+move entrance has overshoot
        .animation(.bouncy, value: pendingUndo)
        .animation(.easeOut(duration: 0.22), value: hasAssembled)
        .toolbar(.hidden, for: .navigationBar)
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: currentThemeRaw)
        .animation(.easeInOut(duration: 0.18), value: oledBlackEnabled)
        .onAppear {
            prepareLaunchAssembly()
            triggerEntranceAnimation()
            handleDayBoundary()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await ScheduledSessionWatcher().evaluate(tasks: todayTasks, completedCount: completedCount)
        }
        .onReceive(timer) { currentTime = $0 }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                handleDayBoundary()
            } else {
                dismissUndo()
            }
        }
        .onChange(of: router.showCarryForward) { _, isShowing in
            if !isShowing {
                presentMorningRitualIfNeeded()
            }
        }
        .onChange(of: allCompleted) { _, isAllDone in
            if isAllDone {
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard allCompleted else { return }
                    router.showTranscendence = true
                }
            }
        }
        .fullScreenCover(isPresented: $bindableRouter.showCarryForward) {
            CarryForwardView()
                .emberCoverEntrance(edge: .bottom)
        }
        .fullScreenCover(isPresented: $bindableRouter.showMorningRitual) {
            MorningRitualView()
                .emberCoverEntrance(edge: .bottom)
        }
        .fullScreenCover(isPresented: $bindableRouter.showTranscendence) {
            TranscendenceView()
                .emberCoverEntrance(edge: .bottom)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.0)
                    .foregroundStyle(textSecondary)

                Text(dateLine)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(textPrimary)

                Text(timeString)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(textSecondary)

                if hasScheduledTasks {
                    Button {
                        dismissUndo()
                        router.navigate(to: .schedule)
                    } label: {
                        HStack(spacing: 8) {
                            Text("VIEW SCHEDULE")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1.6)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(raised)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(hairline, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                    .accessibilityLabel("View schedule")
                    .accessibilityIdentifier("home.viewSchedule")
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    dismissUndo()
                    settingsSymbolTrigger.toggle()
                    router.navigate(to: .settings)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(raised))
                        .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
                        .completeBounce(settingsSymbolTrigger)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")

                Button {
                    dismissUndo()
                    router.navigate(to: .streak)
                } label: {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(raised))
                        .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Streak and rhythm")
                .accessibilityIdentifier("home.streak")

                Button {
                    dismissUndo()
                    addSymbolTrigger.toggle()
                    router.navigate(to: .addTask)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(background)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(textPrimary))
                        .completeBounce(addSymbolTrigger)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a task")
                .accessibilityIdentifier("home.addTask")
            }
        }
    }

    // MARK: - Daily orbit
    // Orbit Hero: the orbit owns the top of the screen as the single hero object.
    // It floats directly on the studio shell — no boxed-widget container, no
    // decorative numeral, no second progress rail competing with it.
    private var orbitSection: some View {
        DailyOrbitView(
            completedCount: completedCount,
            totalCount: 3,
            accent: ember,
            muted: panelMuted,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            stateLabel: dayStateLabel,
            lastInteractionAt: lastInteractionAt
        )
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .opacity(hasAppeared && hasAssembled ? 1 : 0)
        .offset(y: hasAppeared && hasAssembled ? 0 : 14)
        .animation(EmberAnimation.cardAppear, value: hasAppeared)
        .animation(EmberAnimation.cardAppear, value: hasAssembled)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily Orbit, \(completedCount) of 3 tasks complete, \(dayStateLabel)")
    }

    // MARK: - Task grid
    private var taskGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("THREE FOR TODAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.0)
                    .foregroundStyle(textSecondary)

                Spacer()

                if todayTasks.count >= 2 {
                    Button {
                        dismissUndo()
                        if isReordering {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                isReordering = false
                                draggingTaskID = nil
                                dragTranslationY = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                isReordering = true
                            }
                        }
                    } label: {
                        Text(isReordering ? "DONE" : "REORDER")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2.0)
                            .foregroundStyle(isReordering ? background : textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(isReordering ? ember : raised)
                            )
                            .overlay(
                                Capsule().strokeBorder(isReordering ? Color.clear : hairline, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.reorderToggle")
                    .accessibilityLabel(isReordering ? "Done reordering" : "Reorder tasks")
                }
            }

            VStack(spacing: 12) {
                // 10.4 — when Focus filter is active, only render slot 0 (primary focus)
                let visibleIndices = focusFilterActive ? [0] : [0, 1, 2]
                ForEach(visibleIndices, id: \.self) { index in
                    let task = todayTasks[safe: index]
                    slotView(index: index)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                        .animation(
                            EmberAnimation.staggeredCardAppear(index: index + 1),
                            value: hasAppeared
                        )
                        .offset(y: reorderOffsetY(for: index))
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.82), value: virtualReorderIndex)
                        .zIndex(task?.id == draggingTaskID ? 10 : 0)
                }

                if focusFilterActive {
                    // Focus mode notice
                    HStack(spacing: 8) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(ember.opacity(0.72))
                        Text("FOCUS MODE — showing primary slot only")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 2)
                    .transition(.opacity)
                }
            }
        }
    }

    @ViewBuilder
    private func slotView(index: Int) -> some View {
        if let task = todayTasks[safe: index] {
            FocusModuleCard(
                task: task,
                slotNumber: index + 1,
                color: moduleColors[index],
                cardNamespace: cardNamespace,
                holdProgress: holdProgress[task.id] ?? 0,
                holdStartedAt: holdStartedAt[task.id],
                holdDuration: holdDuration,
                pressedLocation: holdLocations[task.id],
                isPressed: pressedTaskID == task.id,
                isReordering: isReordering,
                isDragging: draggingTaskID == task.id,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                background: background,
                panel: panel,
                onTap: {
                    dismissUndo()
                    router.navigate(to: .taskDetail(task))
                },
                onHoldStart: { location in
                    dismissUndo()
                    startHold(for: task, at: location)
                },
                onHoldCancel: {
                    cancelHold(for: task)
                },
                onHoldProgress: { progress in
                    handleHoldProgress(for: task, progress: progress)
                },
                onReorderBegan: {
                    if EmberPreferences.hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    draggingTaskID = task.id
                    dragTranslationY = 0
                },
                onReorderChanged: { translationY in
                    dragTranslationY = translationY
                },
                onReorderEnded: {
                    commitReorderIfNeeded(for: task)
                }
            )
        } else {
            EmptyFocusModule(
                slotNumber: index + 1,
                prompt: emptyPrompts[index],
                color: moduleColors[index],
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                background: background
            ) {
                dismissUndo()
                router.navigate(to: .addTask)
            }
        }
    }

    private func undoToast(_ pending: PendingUndo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ember)
                .frame(width: 22, height: 22)
                .background(Circle().fill(ember.opacity(0.14)))
                .toastPulse(pendingUndo != nil)

            Text("Marked \"\(pending.title)\" complete.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(textPrimary.opacity(0.85))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                undoCompletion()
            } label: {
                Text("Undo")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ember)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(ember.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home.undo")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(hairline, lineWidth: 1)
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Task completed. Tap Undo to revert.")
    }

    private var completionNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ember)

            Text("You showed up today.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(textPrimary)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(hairline, lineWidth: 1)
                )
        )
    }

    // MARK: - Hold to complete
    private func startHold(for task: EmberTask, at location: CGPoint) {
        guard !task.isCompleted, holdStartedAt[task.id] == nil else { return }
        lastInteractionAt = Date() // 6.4 — hold = interaction
        pressedTaskID = task.id
        holdStartedAt[task.id] = Date()
        holdProgress[task.id] = 0
        holdLocations[task.id] = location
        HapticService.shared.playEscalatingHoldCadence(progress: 0)
    }

    private func handleHoldProgress(for task: EmberTask, progress: CGFloat) {
        guard holdStartedAt[task.id] != nil, !task.isCompleted else { return }

        holdProgress[task.id] = progress
        HapticService.shared.playEscalatingHoldCadence(progress: progress)

        guard progress >= 1 else { return }
        holdStartedAt.removeValue(forKey: task.id)
        holdLocations.removeValue(forKey: task.id)
        complete(task)
    }

    private func cancelHold(for task: EmberTask) {
        holdStartedAt.removeValue(forKey: task.id)
        holdLocations.removeValue(forKey: task.id)
        pressedTaskID = nil

        withAnimation(EmberAnimation.completionExhale) {
            holdProgress[task.id] = 0
        }
    }

    private func complete(_ task: EmberTask) {
        if EmberPreferences.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task {
                try? await Task.sleep(for: .milliseconds(120))
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        let snapshot = PendingUndo(taskID: task.id, title: task.title)

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            holdProgress[task.id] = 0
            holdLocations.removeValue(forKey: task.id)
            pressedTaskID = nil
        }
        Task {
            await TaskCompletionCoordinator.shared.complete(task, in: modelContext)
        }
        pendingUndo = snapshot
    }

    private func commitReorderIfNeeded(for task: EmberTask) {
        let originalIndex = todayTasks.firstIndex { $0.id == task.id }
        let target = virtualReorderIndex

        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
            draggingTaskID = nil
            dragTranslationY = 0
        }

        guard let originalIndex, let target, target != originalIndex else { return }

        var ordered = todayTasks
        let moved = ordered.remove(at: originalIndex)
        ordered.insert(moved, at: target)
        for (i, t) in ordered.enumerated() {
            t.displayOrder = i
        }

        if EmberPreferences.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func dismissUndo() {
        guard pendingUndo != nil else { return }
        pendingUndo = nil
        lastInteractionAt = Date() // 6.4 — any dismiss = interaction
    }

    private func undoCompletion() {
        guard let snapshot = pendingUndo,
              let task = todayTasks.first(where: { $0.id == snapshot.taskID }) else {
            pendingUndo = nil
            return
        }

        if EmberPreferences.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        Task {
            await TaskCompletionCoordinator.shared.uncomplete(task, in: modelContext)
        }
        pendingUndo = nil
    }

    // MARK: - Helpers
    private func prepareLaunchAssembly() {
        guard LaunchAssemblySession.didRun else { return }
        hasAssembled = true
    }

    private func completeLaunchAssembly() {
        guard !hasAssembled else { return }
        LaunchAssemblySession.didRun = true
        hasAssembled = true
    }

    private func triggerEntranceAnimation() {
        guard !hasAppeared else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(50))
            hasAppeared = true
        }
    }

    private func handleDayBoundary() {
        guard DateService.shared.isNewDay() else {
            DateService.shared.recordActiveDate()
            presentMorningRitualIfNeeded()
            return
        }

        let yesterday = DateService.shared.yesterday
        let today = Calendar.current.date(byAdding: .day, value: 1, to: yesterday)!
        let descriptor = FetchDescriptor<EmberTask>(
            predicate: #Predicate<EmberTask> {
                $0.dayDate >= yesterday && $0.dayDate < today && $0.isCompleted == false
            }
        )
        let incomplete = (try? modelContext.fetch(descriptor)) ?? []
        if !incomplete.isEmpty {
            router.showCarryForward = true
        } else {
            presentMorningRitualIfNeeded()
        }
        DateService.shared.recordActiveDate()
    }

    private func presentMorningRitualIfNeeded() {
        guard !ProcessInfo.processInfo.arguments.contains("-disableMorningRitual") else { return }
        guard ProcessInfo.processInfo.environment["EMBER_DISABLE_MORNING_RITUAL"] != "1" else { return }
        guard !EmberPreferences.hasShownMorningRitualToday else { return }
        guard !router.showCarryForward, !router.showTranscendence, !router.showMorningRitual else { return }

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !EmberPreferences.hasShownMorningRitualToday else { return }
            guard !router.showCarryForward, !router.showTranscendence, !router.showMorningRitual else { return }
            router.showMorningRitual = true
        }
    }
}

// MARK: - Daily Orbit View
private struct DailyOrbitView: View {
    let completedCount: Int
    let totalCount: Int
    let accent: Color
    let muted: Color
    let textPrimary: Color
    let textSecondary: Color
    let stateLabel: String
    let lastInteractionAt: Date

    private let tickCount = 72
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let orbitPhase = reducedMotionEnabled ? 0 : elapsed * 0.42
            let wavePhase = reducedMotionEnabled ? 0 : elapsed * 1.9

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let radius = size * 0.38
                let activeTicks = activeTickCount

                ZStack {
                    ForEach(0..<tickCount, id: \.self) { index in
                        let isMajor = index % 6 == 0
                        let isActive = index < activeTicks
                        let angle = (Double(index) / Double(tickCount)) * 2 * Double.pi
                        let wave = (sin(wavePhase + Double(index) * 0.34) + 1) / 2
                        let activeLift: CGFloat = isActive ? 4.5 : 2
                        let tickLength = CGFloat(isMajor ? 17 : 11) + CGFloat(wave) * activeLift

                        Capsule(style: .continuous)
                            .fill(isActive ? accent : muted)
                            .frame(width: isMajor ? 2.6 : 1.6, height: tickLength)
                            .opacity(isActive ? 0.74 + wave * 0.26 : 0.26 + wave * 0.18)
                            .shadow(color: isActive ? accent.opacity(0.16 + wave * 0.08) : .clear, radius: 8, y: 0)
                            .offset(y: -radius)
                            .rotationEffect(.radians(angle + orbitPhase))
                    }

                    // 6.4 — idle breathing: scale 1.0 ↔ 1.02 when no interaction for 8s
                    IdleBreathingGuideRing(
                        radius: radius,
                        orbitPhase: wavePhase,
                        lastInteractionAt: lastInteractionAt
                    )

                    VStack(spacing: 4) {
                        // 6.1 — bouncy numericText roll-up
                        Text("\(completedCount)/\(totalCount)")
                            .font(EmberTypography.orbitHero)
                            .foregroundStyle(textPrimary)
                            .contentTransition(.numericText(countsDown: false))
                            .animation(.bouncy, value: completedCount)

                        Text(stateLabel)
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(textSecondary)
                            .textCase(.uppercase)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private var activeTickCount: Int {
        let safeTotal = max(totalCount, 1)
        let progress = min(max(Double(completedCount) / Double(safeTotal), 0), 1)
        return Int((progress * Double(tickCount)).rounded(.down))
    }
}

// MARK: - Idle Breathing Guide Ring
/// Replaces the plain orbit guide ring. Breathes 1.0 ↔ 1.02 in a 4s cycle
/// after 8s of no user interaction on HomeScreen. Stops the moment anything is tapped.
/// Respects EmberPreferences.reducedMotionEnabled.
private struct IdleBreathingGuideRing: View {
    let radius: CGFloat
    let orbitPhase: Double
    let lastInteractionAt: Date

    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false
    @State private var isIdle = false
    @State private var breatheScale: CGFloat = 1.0
    private let idleThreshold: TimeInterval = 8
    private let checkTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Circle()
            .stroke(EmberColors.divider, lineWidth: 1)
            .frame(width: radius * 1.35, height: radius * 1.35)
            // Orbit-phase breathing (always present, low amplitude)
            .scaleEffect(1 + CGFloat(sin(orbitPhase) * 0.018))
            // Idle breathing overlay (kicks in after 8s idle)
            .scaleEffect(breatheScale)
            .onReceive(checkTimer) { _ in
                guard !reducedMotionEnabled else {
                    if isIdle { stopBreathing() }
                    return
                }
                let idle = Date().timeIntervalSince(lastInteractionAt) >= idleThreshold
                if idle && !isIdle {
                    startBreathing()
                } else if !idle && isIdle {
                    stopBreathing()
                }
            }
            .onChange(of: lastInteractionAt) { _, _ in
                if isIdle { stopBreathing() }
            }
    }

    private func startBreathing() {
        isIdle = true
        withAnimation(
            .easeInOut(duration: 4).repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.02
        }
    }

    private func stopBreathing() {
        isIdle = false
        withAnimation(.easeOut(duration: 0.4)) {
            breatheScale = 1.0
        }
    }
}

// MARK: - Focus Module Card
private struct FocusModuleCard: View {
    @Bindable var task: EmberTask

    let slotNumber: Int
    let color: Color
    let cardNamespace: Namespace.ID
    let holdProgress: CGFloat
    let holdStartedAt: Date?
    let holdDuration: TimeInterval
    let pressedLocation: CGPoint?
    let isPressed: Bool
    let isReordering: Bool
    let isDragging: Bool
    let textPrimary: Color
    let textSecondary: Color
    let background: Color
    let panel: Color
    let onTap: () -> Void
    let onHoldStart: (CGPoint) -> Void
    let onHoldCancel: () -> Void
    let onHoldProgress: (CGFloat) -> Void
    let onReorderBegan: () -> Void
    let onReorderChanged: (CGFloat) -> Void
    let onReorderEnded: () -> Void

    @State private var dragBeganAt: Date?
    @State private var didMove = false

    var body: some View {
        let foreground = task.isCompleted ? textPrimary.opacity(0.72) : moduleForeground

        ZStack(alignment: .bottomLeading) {
            // Card background — matched geometry source for the card morph (iOS 18+)
            if #available(iOS 18, *) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(moduleFill)
                    .matchedGeometryEffect(id: "card-\(task.id)", in: cardNamespace)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(moduleFill)
            }

            // Accent rail — matched geometry source (iOS 18+)
            if #available(iOS 18, *) {
                accentRail
                    .matchedGeometryEffect(id: "rail-\(task.id)", in: cardNamespace)
            } else {
                accentRail
            }

            if !task.isCompleted {
                holdRadialWipe
            }

            HStack(alignment: .top, spacing: 14) {
                Text(String(format: "%02d", slotNumber))
                    .font(.system(size: 38, weight: .light, design: .default).monospacedDigit())
                    .foregroundStyle(color.opacity(task.isCompleted ? 0.38 : 0.82))
                    .frame(width: 54, alignment: .leading)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        // Title — matched geometry source (iOS 18+)
                        if #available(iOS 18, *) {
                            Text(task.title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(foreground)
                                .strikethrough(task.isCompleted, color: foreground.opacity(0.5))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .matchedGeometryEffect(id: "title-\(task.id)", in: cardNamespace)
                        } else {
                            Text(task.title)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(foreground)
                                .strikethrough(task.isCompleted, color: foreground.opacity(0.5))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }

                        Spacer(minLength: 10)

                        if isReordering {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(textSecondary)
                                .symbolEffect(.appear, isActive: isReordering)
                                .emberSymbolEffectsRespectReducedMotion()
                                .transition(.opacity)
                        } else if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(foreground.opacity(0.65))
                                .replaceCheck(task.isCompleted)
                        }
                    }

                    HStack(spacing: 8) {
                        if let scheduled = task.scheduledTime {
                            modulePill(formattedTime(scheduled), foreground: foreground)
                        }

                        if !task.subtasks.isEmpty {
                            let completed = task.subtasks.filter { $0.isCompleted }.count
                            modulePill("\(completed)/\(task.subtasks.count) subtasks", foreground: foreground)
                        }

                        if task.isCarriedForward && !task.isCompleted {
                            modulePill("carried", foreground: foreground)
                        }

                        if task.scheduledTime == nil && task.subtasks.isEmpty && !task.isCarriedForward {
                            Text(task.isCompleted ? "done" : "hold to complete")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(foreground.opacity(0.56))
                        }

                        Spacer()
                    }
                }
            }
            .padding(16)
        }
        .frame(minHeight: task.isCompleted ? 78 : 116)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(task.isCompleted ? 0.12 : 0.24), lineWidth: 1)
        )
        .scaleEffect(isDragging ? 1.03 : (isPressed ? 0.985 : 1))
        // 6.2 — drag tilt: 2° rotation lift when dragging
        .rotationEffect(.degrees(isDragging ? 2 : 0))
        // 6.2 — drag shadow: heavier lift (8% → 18% opacity, larger radius)
        .shadow(color: Color.black.opacity(isDragging ? 0.45 : 0.08), radius: isDragging ? 22 : 6, x: 0, y: isDragging ? 12 : 3)
        .animation(EmberAnimation.snappy, value: isPressed)
        .animation(EmberAnimation.snappy, value: isDragging)
        .animation(EmberAnimation.smooth, value: task.isCompleted)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .gesture(combinedGesture)
        .accessibilityLabel(task.title)
        .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint(isReordering ? "Drag to reorder." : (task.isCompleted ? "Tap to see details." : "Press and hold to complete. Tap to see details."))
        .accessibilityIdentifier("home.task.\(slotNumber)")
    }

    private var moduleFill: Color {
        if task.isCompleted { return EmberColors.primaryPanel.opacity(0.9) }
        return EmberColors.nestedRow
    }

    private var moduleForeground: Color {
        textPrimary
    }

    private var accentRail: some View {
        Rectangle()
            .fill(color)
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blendMode(.screen)
                .frame(height: 8)
            }
            .frame(width: 3)
            .frame(maxHeight: .infinity)
            .opacity(task.isCompleted ? 0.36 : 0.9)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var holdRadialWipe: some View {
        GeometryReader { geo in
            if let holdStartedAt {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(holdStartedAt)
                    let progress = min(max(CGFloat(elapsed / holdDuration), 0), 1)
                    let origin = pressedLocation ?? CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let maxRadius = maxDistance(from: origin, in: geo.size)
                    let diameter = max(1, maxRadius * 2 * progress)
                    let _ = DispatchQueue.main.async {
                        onHoldProgress(progress)
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.42),
                                    color.opacity(0.28),
                                    color.opacity(0.04)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: max(1, diameter / 2)
                            )
                        )
                        .frame(width: diameter, height: diameter)
                        .position(origin)
                        .animation(.linear(duration: 0.08), value: progress)
                }
            }
        }
        .opacity(holdProgress > 0 || holdStartedAt != nil ? 1 : 0)
        .allowsHitTesting(false)
    }

    private var combinedGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if isReordering {
                    if dragBeganAt == nil {
                        dragBeganAt = Date()
                        onReorderBegan()
                    }
                    onReorderChanged(value.translation.height)
                } else {
                    guard !task.isCompleted else { return }
                    if dragBeganAt == nil {
                        dragBeganAt = Date()
                        didMove = false
                        onHoldStart(value.location)
                    }
                    if abs(value.translation.width) > 12 || abs(value.translation.height) > 12 {
                        didMove = true
                        onHoldCancel()
                    }
                }
            }
            .onEnded { _ in
                if isReordering {
                    dragBeganAt = nil
                    onReorderEnded()
                } else {
                    let elapsed = dragBeganAt.map { Date().timeIntervalSince($0) } ?? 0
                    let shouldTap = elapsed < 0.18 && !didMove && holdProgress < 1
                    dragBeganAt = nil
                    didMove = false
                    onHoldCancel()
                    if shouldTap || (task.isCompleted && elapsed < 0.18) {
                        onTap()
                    }
                }
            }
    }

    private func modulePill(_ text: String, foreground: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(foreground.opacity(0.72))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(foreground.opacity(task.isCompleted ? 0.08 : 0.12))
            )
    }

    private func formattedTime(_ date: Date) -> String {
        HomeScreen.timeFormatter.string(from: date)
    }

    private func maxDistance(from point: CGPoint, in size: CGSize) -> CGFloat {
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: size.width, y: 0),
            CGPoint(x: 0, y: size.height),
            CGPoint(x: size.width, y: size.height)
        ]
        return corners.map { hypot($0.x - point.x, $0.y - point.y) }.max() ?? 1
    }
}

// MARK: - Empty Focus Module
private struct EmptyFocusModule: View {
    let slotNumber: Int
    let prompt: String
    let color: Color
    let textPrimary: Color
    let textSecondary: Color
    let background: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(String(format: "%02d", slotNumber))
                    .font(.system(size: 38, weight: .light, design: .default).monospacedDigit())
                    .foregroundStyle(color.opacity(0.55))
                    .frame(width: 54, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(textPrimary.opacity(0.82))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("tap to set focus")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundStyle(textSecondary)
                }

                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(background)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(color))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 96)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(EmberColors.nestedRow)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(color.opacity(0.22), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add task. \(prompt)")
    }
}

// MARK: - Previews
@available(iOS 17, *)
private struct HomeScreenPreviews: View {
    @Namespace var ns
    var body: some View { HomeScreen(cardNamespace: ns) }
}

#Preview("Empty State") {
    HomeScreenPreviews()
        .environment(EmberRouter())
        .modelContainer(for: [EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self], inMemory: true)
}

#Preview("One Task") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())

    var timeComps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    timeComps.hour = 14
    timeComps.minute = 30
    let scheduledTime = Calendar.current.date(from: timeComps)

    let task = EmberTask(title: "Strategy Review Call", displayOrder: 0, dayDate: today, scheduledTime: scheduledTime)
    ctx.insert(task)

    return HomeScreenPreviews()
        .environment(EmberRouter())
        .modelContainer(container)
}

#Preview("All Complete") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())

    let titles = ["Morning standup", "Write the brief", "Call the client"]
    for (i, title) in titles.enumerated() {
        let task = EmberTask(title: title, displayOrder: i, dayDate: today)
        task.isCompleted = true
        task.completionDate = Date()
        ctx.insert(task)
    }

    return HomeScreenPreviews()
        .environment(EmberRouter())
        .modelContainer(container)
}

#Preview("Mixed") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())

    let first = EmberTask(title: "Morning run", displayOrder: 0, dayDate: today)
    first.isCompleted = true
    first.completionDate = Date()
    ctx.insert(first)

    let second = EmberTask(title: "Prepare the deck", displayOrder: 1, dayDate: today)
    ctx.insert(second)
    let s1 = Subtask(title: "Gather data", displayOrder: 0)
    s1.task = second
    ctx.insert(s1)
    let s2 = Subtask(title: "Design slides", displayOrder: 1)
    s2.task = second
    ctx.insert(s2)
    let s3 = Subtask(title: "Review with team", displayOrder: 2)
    s3.task = second
    ctx.insert(s3)

    return HomeScreenPreviews()
        .environment(EmberRouter())
        .modelContainer(container)
}
