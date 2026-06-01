// AddTaskView.swift
// Full-screen add task — replaces AddTaskSheet
import SwiftUI
import SwiftData

struct AddTaskView: View {

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router

    // MARK: - Queries
    @Query private var todayTasks: [EmberTask]

    // MARK: - State
    @State private var taskTitle: String = ""
    @State private var scheduleTime: Bool = false
    @State private var selectedTime: Date = {
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: Date())
        comps.hour = (comps.hour ?? 0) + 1
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var subtaskDrafts: [SubtaskDraft] = []
    @State private var isAddingSubtask: Bool = false
    @State private var newSubtaskText: String = ""
    @FocusState private var titleFocused: Bool
    @FocusState private var subtaskFieldFocused: Bool

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

    // MARK: - Init
    init() {
        let today    = DateService.shared.today
        let tomorrow = DateService.shared.calendar.date(byAdding: .day, value: 1, to: today)!
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { $0.dayDate >= today && $0.dayDate < tomorrow },
            sort: \EmberTask.displayOrder
        )
    }

    // MARK: - Computed
    private var trimmedTitle: String { taskTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty && todayTasks.count < 3 }
    private var nextSlotLabel: String {
        todayTasks.count >= 3 ? "3/3 chosen" : "Slot \(todayTasks.count + 1) of 3"
    }
    private var todayLabel: String {
        DateService.shared.today.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
    private var selectedTimeLabel: String {
        selectedTime.formatted(date: .omitted, time: .shortened)
    }
    private var subtaskCountLabel: String {
        subtaskDrafts.isEmpty ? "Optional" : "\(subtaskDrafts.count) drafted"
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: EmberSpacing.cardGap) {
                        missionPanel
                        scheduleSheet
                        subtaskSheet
                    }
                    .padding(.horizontal, EmberSpacing.screenHorizontal)
                    .padding(.bottom, 44)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // 10.2 — consume pending title from deep link / AddTaskIntent
            if let pending = router.pendingAddTitle, !pending.isEmpty {
                taskTitle = pending
                router.pendingAddTitle = nil
            } else {
                titleFocused = true
            }
        }
    }

    // MARK: - Top bar

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
            .accessibilityIdentifier("addTask.back")

            Spacer()

            VStack(spacing: 2) {
                Text("SET FOCUS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(textSecondary)
                Text("\(todayTasks.count)/3 chosen")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(textPrimary.opacity(0.72))
            }

            Spacer()

            Button {
                saveTask()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))

                    Text("SAVE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundStyle(canSave ? background : textSecondary)
                .frame(width: 88, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .fill(canSave ? ember : raised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .strokeBorder(canSave ? Color.clear : hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .accessibilityLabel("Save task")
            .accessibilityIdentifier("addTask.save")
        }
        .padding(.horizontal, EmberSpacing.screenHorizontal)
        .padding(.top, 14)
        .padding(.bottom, 18)
    }

    // MARK: - Mission panel + grouped sheets

    private var missionPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader("MISSION")

                Spacer()

                Text(nextSlotLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(todayLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(textSecondary)

                ZStack(alignment: .topLeading) {
                    if taskTitle.isEmpty {
                        Text("Name the focus")
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(textTertiary)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $taskTitle)
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(textPrimary)
                        .focused($titleFocused)
                        .scrollDisabled(true)
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .tint(textPrimary)
                        .accessibilityLabel("Task title")
                        .accessibilityIdentifier("addTask.title")
                }
            }
        }
        .padding(20)
        .background(studioPanel)
    }

    private var scheduleSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SCHEDULE")

            VStack(spacing: 8) {
                groupedRow(
                    icon: "clock",
                    title: "Time block",
                    subtitle: scheduleTime ? selectedTimeLabel : "No time set"
                ) {
                    scheduleSwitch
                }

                if scheduleTime {
                    groupedRow(
                        icon: "timer",
                        title: "Starts",
                        subtitle: "Today"
                    ) {
                        DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(textPrimary)
                            .colorScheme(.dark)
                            .frame(width: 96, alignment: .trailing)
                            .accessibilityIdentifier("addTask.timePicker")
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(studioPanel)
        .animation(EmberAnimation.snappy, value: scheduleTime)
    }

    private var subtaskSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                sectionHeader("SUBTASKS")

                Spacer()

                Text(subtaskCountLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(Array(subtaskDrafts.enumerated()), id: \.element.id) { index, draft in
                    savedSubtaskRow(title: draft.title, index: index)
                }

                if isAddingSubtask {
                    newSubtaskRow
                } else {
                    addSubtaskRow
                }
            }
        }
        .padding(20)
        .background(studioPanel)
        .animation(EmberAnimation.snappy, value: subtaskDrafts.count)
        .animation(EmberAnimation.snappy, value: isAddingSubtask)
    }

    private var scheduleSwitch: some View {
        Button {
            scheduleTime.toggle()
        } label: {
            ZStack(alignment: scheduleTime ? .trailing : .leading) {
                Capsule()
                    .fill(raised.opacity(scheduleTime ? 1 : 0.78))
                    .overlay(Capsule().strokeBorder(hairline, lineWidth: 1))

                Circle()
                    .fill(scheduleTime ? textPrimary : textSecondary)
                    .frame(width: 26, height: 26)
                    .padding(4)
            }
            .frame(width: 58, height: 34)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Schedule task")
        .accessibilityValue(scheduleTime ? "On" : "Off")
        .accessibilityIdentifier("addTask.scheduleToggle")
    }

    private var addSubtaskRow: some View {
        Button {
            isAddingSubtask = true
            newSubtaskText = ""
            subtaskFieldFocused = true
        } label: {
            groupedRowContent(
                icon: "plus",
                title: "Add subtask",
                subtitle: subtaskDrafts.isEmpty ? "Optional support step" : "Add another support step"
            ) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(textTertiary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("addTask.addSubtask")
    }

    private var newSubtaskRow: some View {
        groupedRowContent(
            icon: "square.and.pencil",
            title: "",
            subtitle: ""
        ) {
            Button {
                commitSubtask()
            } label: {
                Image(systemName: "return")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .frame(width: 44, height: 32)
                    .background(Capsule().fill(raised))
                    .overlay(Capsule().strokeBorder(hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Commit subtask")
        } content: {
            TextField("Subtask title", text: $newSubtaskText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textPrimary)
                .focused($subtaskFieldFocused)
                .submitLabel(.done)
                .tint(textPrimary)
                .onSubmit { commitSubtask() }
                .accessibilityIdentifier("addTask.subtaskField")
        }
    }

    private func savedSubtaskRow(title: String, index: Int) -> some View {
        groupedRowContent(
            icon: "checklist.unchecked",
            title: title,
            subtitle: "Support step \(index + 1)"
        ) {
            Button {
                subtaskDrafts.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(raised))
                    .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove subtask")
        }
    }

    private func groupedRow<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        groupedRowContent(icon: icon, title: title, subtitle: subtitle, trailing: trailing)
    }

    private func groupedRowContent<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        groupedRowContent(icon: icon, title: title, subtitle: subtitle, trailing: trailing) {
            rowText(title: title, subtitle: subtitle)
        }
    }

    private func groupedRowContent<Content: View, Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            rowIcon(icon)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
                .frame(width: 96, alignment: .trailing)
        }
        .padding(14)
        .background(rowBackground)
        .contentShape(RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous))
    }

    private func rowText(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textPrimary)
                .lineLimit(1)

            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(textSecondary)
                .lineLimit(1)
        }
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(textSecondary)
            .frame(width: 32, height: 32)
            .background(Circle().fill(raised))
            .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .emberSectionLabel()
    }

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

    // MARK: - Actions

    private func commitSubtask() {
        let text = newSubtaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            subtaskDrafts.append(SubtaskDraft(title: text))
        }
        newSubtaskText = ""
        isAddingSubtask = false
    }

    private func saveTask() {
        guard canSave else { return }

        // Commit any pending subtask
        let pendingText = newSubtaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        if isAddingSubtask && !pendingText.isEmpty {
            subtaskDrafts.append(SubtaskDraft(title: pendingText))
        }

        let task = EmberTask(
            title: trimmedTitle,
            displayOrder: todayTasks.count,
            dayDate: DateService.shared.today,
            scheduledTime: scheduleTime ? selectedTime : nil
        )
        modelContext.insert(task)

        for (i, draft) in subtaskDrafts.enumerated() {
            let subtask = Subtask(title: draft.title, displayOrder: i)
            subtask.task = task
            modelContext.insert(subtask)
        }

        DailyRecordService.upsertRecord(in: modelContext)
        Task { await TaskCompletionCoordinator.shared.scheduleReminder(for: task) }
        // 10.1 — index new task in Spotlight
        SpotlightService.index(task)
        router.goBack()
    }
}

// MARK: - Local draft model (not persisted)

private struct SubtaskDraft {
    let id = UUID()
    var title: String
}
