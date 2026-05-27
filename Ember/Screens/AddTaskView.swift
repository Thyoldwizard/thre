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

    // MARK: - Init
    init() {
        let today    = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { $0.dayDate >= today && $0.dayDate < tomorrow },
            sort: \EmberTask.displayOrder
        )
    }

    // MARK: - Computed
    private var trimmedTitle: String { taskTitle.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty && todayTasks.count < 3 }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "F7F5F2").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // ── Top bar ─────────────────────────────────────────
                HStack {
                    Button {
                        router.goBack()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .regular))
                        }
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.55))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        saveTask()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(canSave ? Color(hex: "E8562A") : Color(hex: "C4C0BA"))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {

                        // ── Large title input ────────────────────────
                        ZStack(alignment: .topLeading) {
                            if taskTitle.isEmpty {
                                Text("What will you focus on?")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundStyle(Color(hex: "C0C0C0"))
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $taskTitle)
                                .font(.system(size: 28, weight: .regular))
                                .foregroundStyle(Color(hex: "1A1A1A"))
                                .focused($titleFocused)
                                .scrollDisabled(true)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                        .padding(.horizontal, 24)

                        // ── Schedule time ────────────────────────────
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(scheduleTime ? Color(hex: "E8562A") : Color(hex: "9A9A9A"))
                                Text("Schedule a time")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                                Spacer()
                                Toggle("", isOn: $scheduleTime)
                                    .labelsHidden()
                                    .tint(Color(hex: "E8562A"))
                            }

                            if scheduleTime {
                                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(Color(hex: "E8562A"))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // ── Subtasks section ─────────────────────────
                        VStack(alignment: .leading, spacing: 0) {
                            Text("SUBTASKS")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                                .tracking(1.5)
                                .padding(.bottom, 14)

                            // Itinerary thread
                            if !subtaskDrafts.isEmpty || isAddingSubtask {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(Array(subtaskDrafts.enumerated()), id: \.offset) { i, draft in
                                        subtaskRow(title: draft.title, index: i)
                                        if i < subtaskDrafts.count - 1 || isAddingSubtask {
                                            connectorLine
                                        }
                                    }

                                    // Inline add field at bottom of thread
                                    if isAddingSubtask {
                                        HStack(alignment: .center, spacing: 10) {
                                            // Dot
                                            Circle()
                                                .strokeBorder(Color(hex: "1A1A1A").opacity(0.30), lineWidth: 1)
                                                .frame(width: 7, height: 7)

                                            TextField("Subtask title", text: $newSubtaskText)
                                                .font(.system(size: 15, weight: .regular))
                                                .foregroundStyle(Color(hex: "1A1A1A"))
                                                .focused($subtaskFieldFocused)
                                                .submitLabel(.done)
                                                .onSubmit { commitSubtask() }
                                        }
                                    }
                                }
                            }

                            // "+ Add subtask" button
                            if !isAddingSubtask {
                                Button {
                                    isAddingSubtask = true
                                    newSubtaskText = ""
                                    subtaskFieldFocused = true
                                } label: {
                                    HStack(spacing: 8) {
                                        // Dot placeholder in thread position
                                        Circle()
                                            .strokeBorder(Color(hex: "1A1A1A").opacity(0.20), lineWidth: 1)
                                            .frame(width: 7, height: 7)
                                        Text("+ Add subtask")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(Color(hex: "9A9A9A"))
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.top, subtaskDrafts.isEmpty ? 0 : 8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { titleFocused = true }
    }

    // MARK: - Subtask row (itinerary dot + title)

    private func subtaskRow(title: String, index: Int) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Circle()
                .fill(Color(hex: "1A1A1A").opacity(0.75))
                .frame(width: 7, height: 7)

            Text(title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.85))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Remove button
            Button {
                subtaskDrafts.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "1A1A1A").opacity(0.30))
            }
            .buttonStyle(.plain)
        }
    }

    // 1pt connector line between subtask rows
    private var connectorLine: some View {
        Rectangle()
            .fill(Color(hex: "1A1A1A").opacity(0.20))
            .frame(width: 1, height: 10)
            .padding(.leading, 3) // align to dot center (7pt dot / 2 = 3.5 → 3)
            .padding(.vertical, 2)
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

        router.goBack()
    }
}

// MARK: - Local draft model (not persisted)

private struct SubtaskDraft {
    let id = UUID()
    var title: String
}
