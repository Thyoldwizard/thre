// AddTaskSheet.swift
// Redesigned to match HomeScreen light visual language
import SwiftUI
import SwiftData

struct AddTaskSheet: View {

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries
    @Query private var todayTasks: [EmberTask]

    // MARK: - State
    @State private var taskTitle:    String = ""
    @State private var scheduleTime: Bool   = false
    @State private var selectedTime: Date   = {
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour], from: Date())
        comps.hour = (comps.hour ?? 0) + 1
        comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @FocusState private var isFocused: Bool

    // MARK: - Init
    init() {
        let today    = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { task in
                task.dayDate >= today && task.dayDate < tomorrow
            },
            sort: \EmberTask.displayOrder
        )
    }

    // MARK: - Computed
    private var todayTaskCount:  Int  { todayTasks.count }
    private var nextDisplayOrder: Int { todayTaskCount }
    private var isAtLimit: Bool       { todayTaskCount >= 3 }
    private var trimmedTitle: String  { taskTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool         { !trimmedTitle.isEmpty && !isAtLimit }

    private var sheetHeight: CGFloat {
        if isAtLimit { return 220 }
        return scheduleTime ? 360 : 260
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header row ────────────────────────────────────────
            HStack {
                Text("New Task")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(hex: "1A1A1A"))

                Spacer()

                // Slot indicator — e.g. "2 of 3"
                Text("\(todayTaskCount) of 3")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "9A9A9A"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // ── Input or limit message ────────────────────────────
            if isAtLimit {
                atLimitMessage
                    .padding(.horizontal, 24)
            } else {
                taskInputField
                    .padding(.horizontal, 24)

                // ── Time scheduling ───────────────────────────────
                timeSchedulingSection
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
            }

            Spacer()

            // ── Divider ───────────────────────────────────────────
            Rectangle()
                .fill(Color(hex: "1A1A1A").opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 24)

            // ── Save button ───────────────────────────────────────
            saveButton
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.white)
        .presentationCornerRadius(24)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: scheduleTime)
        .onAppear {
            if !isAtLimit { isFocused = true }
        }
    }

    // MARK: - Text field

    private var taskInputField: some View {
        ZStack(alignment: .topLeading) {
            if taskTitle.isEmpty {
                Text("What will you focus on?")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color(hex: "9A9A9A"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .allowsHitTesting(false)
            }

            TextField("", text: $taskTitle)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit { if canSave { saveTask() } }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "F5F2EC"))
        )
    }

    // MARK: - Time scheduling section

    private var timeSchedulingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Toggle row
            HStack {
                ZStack {
                    Circle()
                        .fill(scheduleTime ? Color(hex: "E8562A").opacity(0.10) : Color(hex: "1A1A1A").opacity(0.06))
                        .frame(width: 30, height: 30)
                    Image(systemName: "clock")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(scheduleTime ? Color(hex: "E8562A") : Color(hex: "9A9A9A"))
                }

                Text("Schedule a time")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(hex: "1A1A1A"))

                Spacer()

                Toggle("", isOn: $scheduleTime)
                    .labelsHidden()
                    .tint(Color(hex: "E8562A"))
            }

            // Compact time picker
            if scheduleTime {
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color(hex: "E8562A"))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - At-limit message

    private var atLimitMessage: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "96B89A"))

            Text("You've set your 3 tasks for today.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "9A9A9A"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "F5F2EC"))
        )
    }

    // MARK: - Save button

    private var saveButton: some View {
        Button {
            saveTask()
        } label: {
            Text(isAtLimit ? "Done" : "Save Task")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(canSave || isAtLimit ? Color.white : Color.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canSave || isAtLimit ? Color(hex: "1A1A1A") : Color(hex: "1A1A1A").opacity(0.25))
                )
        }
        .buttonStyle(.plain)
        .disabled(!canSave && !isAtLimit)
    }

    // MARK: - Save action

    private func saveTask() {
        if isAtLimit {
            router.showAddTask = false
            return
        }
        guard canSave else { return }

        let task = EmberTask(
            title: trimmedTitle,
            displayOrder: nextDisplayOrder,
            dayDate: DateService.shared.today,
            scheduledTime: scheduleTime ? selectedTime : nil
        )
        modelContext.insert(task)
        isFocused = false
        router.showAddTask = false
    }
}

// MARK: - Previews

#Preview("Empty") {
    Color(hex: "EEEAE3")
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AddTaskSheet()
                .environment(EmberRouter())
                .modelContainer(for: [EmberTask.self, DailyRecord.self, Reflection.self], inMemory: true)
        }
}

#Preview("At Limit") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx   = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())
    ctx.insert(EmberTask(title: "Task One",   displayOrder: 0, dayDate: today))
    ctx.insert(EmberTask(title: "Task Two",   displayOrder: 1, dayDate: today))
    ctx.insert(EmberTask(title: "Task Three", displayOrder: 2, dayDate: today))

    return Color(hex: "EEEAE3")
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AddTaskSheet()
                .environment(EmberRouter())
                .modelContainer(container)
        }
}
