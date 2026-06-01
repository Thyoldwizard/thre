// TaskDetailScreen.swift
// Dark studio task control surface.
import SwiftUI
import SwiftData

struct TaskDetailScreen: View {

    // MARK: - Data
    @Bindable var task: EmberTask

    /// Matched geometry namespace injected from ContentView on iOS 18+.
    /// Nil on iOS 17 so all callers (including UI tests) compile without change.
    var namespace: Namespace.ID?

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router

    // MARK: - State
    @State private var newSubtaskTitle = ""
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    @State private var showDeleteConfirmation = false
    @State private var scheduleEnabled = false
    @State private var scheduleTime = Date()
    @State private var didInitializeScheduleControls = false
    @State private var completedSubtaskDisplayCount = 0
    @State private var totalSubtaskDisplayCount = 0
    @State private var focusSessionActive = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isSubtaskFocused: Bool

    // MARK: - Studio tokens
    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel
    private let row = EmberColors.nestedRow
    private let raised = EmberColors.raisedElement
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private let textTertiary = EmberColors.textTertiary
    private let hairline = EmberColors.divider
    private var ember: Color { EmberColors.ember }

    // MARK: - Computed
    private var sortedSubtasks: [Subtask] {
        task.subtasks.sorted { $0.displayOrder < $1.displayOrder }
    }

    private var completedSubtaskCount: Int {
        completedSubtaskDisplayCount
    }

    private var totalSubtaskCount: Int {
        totalSubtaskDisplayCount
    }

    private var statusLabel: String {
        task.isCompleted ? "complete" : "in motion"
    }

    private var slotLabel: String {
        "Slot \(min(max(task.displayOrder + 1, 1), 3)) of 3"
    }

    private var scheduleStatus: String {
        scheduleEnabled ? formattedTime(scheduleTime) : "No time set"
    }

    private var subtaskStatus: String {
        totalSubtaskCount == 0 ? "Optional" : "\(completedSubtaskCount)/\(totalSubtaskCount) done"
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    missionPanel
                    statusPanel
                    subtaskPanel
                    // 8.6 — focus session button (hidden when task is already complete)
                    if !task.isCompleted {
                        focusSessionPanel
                    }
                    deleteButton
                }
                .padding(.horizontal, EmberSpacing.screenHorizontal)
                .padding(.top, 14)
                .padding(.bottom, 42)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Delete this task?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Task", role: .destructive) { deleteTask() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will also remove all its subtasks.")
        }
        .onChange(of: isEditingTitle) { _, editing in
            if editing { isTitleFocused = true }
        }
        .onAppear {
            initializeScheduleControls()
            refreshSubtaskProgress()
            // 8.6 — sync session state
            focusSessionActive = FocusSessionService.shared.isActive(for: task.id.uuidString)
        }
        .onChange(of: scheduleEnabled) { _, isEnabled in
            guard didInitializeScheduleControls else { return }
            updateSchedule(isEnabled: isEnabled)
        }
        .onChange(of: scheduleTime) { _, newTime in
            guard didInitializeScheduleControls, scheduleEnabled else { return }
            task.scheduledTime = newTime
            Task { await TaskCompletionCoordinator.shared.scheduleReminder(for: task) }
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
                    .background(Circle().fill(raised))
                    .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("taskDetail.back")

            Spacer()

            VStack(spacing: 2) {
                Text("TASK")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(textSecondary)

                Text(statusLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textPrimary.opacity(0.72))
            }

            Spacer()

            Button {
                let wasCompleted = task.isCompleted
                Task {
                    if wasCompleted {
                        await TaskCompletionCoordinator.shared.uncomplete(task, in: modelContext)
                    } else {
                        await TaskCompletionCoordinator.shared.complete(task, in: modelContext)
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: task.isCompleted ? "checkmark" : "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .replaceCheck(task.isCompleted)

                    Text(task.isCompleted ? "DONE" : "FINISH")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundStyle(task.isCompleted ? textSecondary : background)
                .frame(width: 96, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .fill(task.isCompleted ? raised : ember)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .strokeBorder(task.isCompleted ? hairline : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")
            .accessibilityIdentifier("taskDetail.completeToggle")
        }
    }

    private var missionPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader("MISSION")

                Spacer()

                Text(slotLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textSecondary)
            }

            HStack(spacing: 10) {
                if #available(iOS 18, *), let ns = namespace {
                    Capsule()
                        .fill(task.isCompleted ? textTertiary : ember)
                        .frame(width: 4, height: 30)
                        .matchedGeometryEffect(id: "rail-\(task.id)", in: ns)
                } else {
                    Capsule()
                        .fill(task.isCompleted ? textTertiary : ember)
                        .frame(width: 4, height: 30)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(statusLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textSecondary)

                    Text(task.scheduledTime == nil ? "No time block" : "Time block \(formattedTime(task.scheduledTime ?? Date()))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(textSecondary)
                }
            }

            if isEditingTitle {
                TextField("Task title", text: $editedTitle)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(textPrimary)
                    .focused($isTitleFocused)
                    .submitLabel(.done)
                    .tint(textPrimary)
                    .onSubmit { commitTitleEdit() }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                            .fill(row)
                            .overlay(
                                RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                                    .strokeBorder(hairline, lineWidth: 1)
                            )
                    )
            } else {
                // Title — matched geometry destination (iOS 18+)
                if #available(iOS 18, *), let ns = namespace {
                    Text(task.title)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .strikethrough(task.isCompleted, color: textPrimary.opacity(0.35))
                        .opacity(task.isCompleted ? 0.55 : 1)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .matchedGeometryEffect(id: "title-\(task.id)", in: ns)
                        .onTapGesture {
                            editedTitle = task.title
                            isEditingTitle = true
                        }
                } else {
                    Text(task.title)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .strikethrough(task.isCompleted, color: textPrimary.opacity(0.35))
                        .opacity(task.isCompleted ? 0.55 : 1)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editedTitle = task.title
                            isEditingTitle = true
                        }
                }
            }
        }
        .padding(20)
        .background(
            // Panel background — matched geometry destination (iOS 18+)
            Group {
                if #available(iOS 18, *), let ns = namespace {
                    studioPanel
                        .matchedGeometryEffect(id: "card-\(task.id)", in: ns)
                } else {
                    studioPanel
                }
            }
        )
    }

    private var statusPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("DETAILS")

            VStack(spacing: 8) {
                groupedRow(
                    icon: task.isCompleted ? "checkmark.circle" : "circle.dotted",
                    title: "State",
                    subtitle: statusLabel
                ) {
                    Text(task.isCompleted ? "done" : "open")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(textSecondary)
                        .frame(width: 96, alignment: .trailing)
                }

                if task.isCarriedForward {
                    groupedRow(
                        icon: "arrow.forward.circle",
                        title: "Carried forward",
                        subtitle: "Moved from a previous day"
                    ) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(textSecondary)
                            .frame(width: 96, alignment: .trailing)
                    }
                }

                scheduleRow

                if scheduleEnabled {
                    timePickerRow
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(studioPanel)
        .animation(EmberAnimation.snappy, value: scheduleEnabled)
    }

    private var subtaskPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader("SUBTASKS")

                Spacer()

                Text(subtaskStatus)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .accessibilityIdentifier("taskDetail.subtaskProgress")
            }

            VStack(spacing: 8) {
                if sortedSubtasks.isEmpty {
                    emptySubtaskRow
                } else {
                    ForEach(sortedSubtasks) { subtask in
                        subtaskRow(subtask)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button("Delete", role: .destructive) {
                                    withAnimation(EmberAnimation.fadeOut) {
                                        deleteSubtask(subtask)
                                    }
                                }
                            }
                    }
                }

                addSubtaskInput
            }
        }
        .padding(20)
        .background(studioPanel)
        .animation(EmberAnimation.snappy, value: sortedSubtasks.count)
    }

    private var scheduleRow: some View {
        groupedRow(
            icon: "clock",
            title: "Time block",
            subtitle: scheduleStatus
        ) {
            HStack(spacing: 8) {
                if task.scheduledTime != nil {
                    Button {
                        removeSchedule()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(raised))
                            .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove schedule")
                    .accessibilityIdentifier("taskDetail.removeSchedule")
                }

                Toggle("", isOn: $scheduleEnabled)
                    .labelsHidden()
                    .tint(raised)
                    .frame(width: 58, alignment: .trailing)
                    .accessibilityIdentifier("taskDetail.scheduleToggle")
            }
            .frame(width: 96, alignment: .trailing)
        }
    }

    private var timePickerRow: some View {
        groupedRow(
            icon: "timer",
            title: "Starts",
            subtitle: "Today"
        ) {
            DatePicker(
                "",
                selection: $scheduleTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(textPrimary)
            .colorScheme(.dark)
            .frame(width: 96, alignment: .trailing)
            .accessibilityIdentifier("taskDetail.timePicker")
        }
    }

    private var addSubtaskInput: some View {
        groupedRowContent(icon: "plus") {
            TextField("Add a subtask...", text: $newSubtaskTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textPrimary)
                .focused($isSubtaskFocused)
                .submitLabel(.done)
                .tint(textPrimary)
                .onSubmit { addSubtask() }
                .accessibilityIdentifier("taskDetail.addSubtask")
        } trailing: {
            Image(systemName: "return")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(textTertiary)
                .frame(width: 96, alignment: .trailing)
        }
    }

    private var emptySubtaskRow: some View {
        groupedRow(
            icon: "checklist",
            title: "No subtasks yet",
            subtitle: "Keep the mission clean or add support steps"
        ) {
            Color.clear.frame(width: 96)
        }
    }

    // MARK: - 8.6 Focus session panel

    private var focusSessionPanel: some View {
        Button {
            Task {
                if focusSessionActive {
                    await FocusSessionService.shared.end()
                    focusSessionActive = false
                } else {
                    await FocusSessionService.shared.start(for: task, completedCount: completedSubtaskCount)
                    focusSessionActive = FocusSessionService.shared.isActive(for: task.id.uuidString)
                }
            }
        } label: {
            groupedRowContent(icon: focusSessionActive ? "stop.circle" : "play.circle") {
                rowText(
                    title: focusSessionActive ? "Focus session active" : "Start focus session",
                    subtitle: focusSessionActive ? "Live Activity is running" : "Lock Screen and Dynamic Island"
                )
            } trailing: {
                Image(systemName: focusSessionActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(textSecondary)
                    .frame(width: 96, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(focusSessionActive ? "End focus session" : "Start focus session")
        .accessibilityIdentifier("taskDetail.focusSession")
        .animation(EmberAnimation.snappy, value: focusSessionActive)
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Text("Delete Task")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.red.opacity(0.72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .fill(panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.16), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
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

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
            .fill(row)
            .overlay(
                RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                    .strokeBorder(hairline, lineWidth: 1)
            )
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .emberSectionLabel()
    }

    private func groupedRow<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        groupedRowContent(icon: icon) {
            rowText(title: title, subtitle: subtitle)
        } trailing: {
            trailing()
        }
    }

    private func groupedRowContent<Content: View, Trailing: View>(
        icon: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            rowIcon(icon)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(14)
        .background(rowBackground)
        .contentShape(RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous))
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(textSecondary)
            .frame(width: 32, height: 32)
            .background(Circle().fill(raised))
            .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
    }

    private func rowText(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(textSecondary)
                .lineLimit(1)
        }
    }

    private func subtaskRow(_ subtask: Subtask) -> some View {
        groupedRowContent(icon: subtask.isCompleted ? "checkmark" : "circle") {
            rowText(title: subtask.title, subtitle: subtask.isCompleted ? "complete" : "open")
                .opacity(subtask.isCompleted ? 0.56 : 1)
        } trailing: {
            Button {
                withAnimation(EmberAnimation.subtaskCheck) {
                    let isNowCompleted = !subtask.isCompleted
                    subtask.isCompleted = isNowCompleted
                    completedSubtaskDisplayCount += isNowCompleted ? 1 : -1
                }
                do { try modelContext.save() }
                catch { EmberLogger.records.error("subtask toggle save failed", error) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(subtask.isCompleted ? textPrimary : Color.clear)
                        .frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(subtask.isCompleted ? Color.clear : textSecondary.opacity(0.32), lineWidth: 1)
                        .frame(width: 24, height: 24)
                    if subtask.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(background)
                            .completeBounce(subtask.isCompleted)
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Toggle subtask \(subtask.title)")
            .accessibilityIdentifier("taskDetail.subtaskToggle")
            .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Actions
    private func commitTitleEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            task.title = trimmed
            do { try modelContext.save() }
            catch { EmberLogger.records.error("title edit save failed", error) }
            SpotlightService.reindex(task)
        }
        isEditingTitle = false
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(EmberAnimation.fadeIn) {
            let subtask = Subtask(title: trimmed, displayOrder: task.subtasks.count)
            modelContext.insert(subtask)
            task.subtasks.append(subtask)
            refreshSubtaskProgress()
        }
        do { try modelContext.save() }
        catch { EmberLogger.records.error("add subtask save failed", error) }
        newSubtaskTitle = ""
    }

    private func deleteSubtask(_ subtask: Subtask) {
        task.subtasks.removeAll { $0.id == subtask.id }
        modelContext.delete(subtask)
        do { try modelContext.save() }
        catch { EmberLogger.records.error("delete subtask save failed", error) }
        refreshSubtaskProgress()
    }

    private func refreshSubtaskProgress() {
        completedSubtaskDisplayCount = task.subtasks.filter { $0.isCompleted }.count
        totalSubtaskDisplayCount = task.subtasks.count
    }

    private func deleteTask() {
        TaskCompletionCoordinator.shared.deleteTask(task, in: modelContext)
        router.goBack()
    }

    private func initializeScheduleControls() {
        guard !didInitializeScheduleControls else { return }
        scheduleEnabled = task.scheduledTime != nil
        scheduleTime = task.scheduledTime ?? defaultScheduleTime()
        didInitializeScheduleControls = true
    }

    private func updateSchedule(isEnabled: Bool) {
        if isEnabled {
            task.scheduledTime = scheduleTime
            do { try modelContext.save() }
            catch { EmberLogger.records.error("schedule update save failed", error) }
            Task { await TaskCompletionCoordinator.shared.scheduleReminder(for: task) }
        } else {
            removeSchedule()
        }
    }

    private func removeSchedule() {
        scheduleEnabled = false
        task.scheduledTime = nil
        ReminderService.cancelReminder(for: task.id)
        do { try modelContext.save() }
        catch { EmberLogger.records.error("schedule remove save failed", error) }
    }

    private func defaultScheduleTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: nextHour)
        return calendar.date(from: components) ?? nextHour
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
