// TaskDetailScreen.swift
// Redesigned to match HomeScreen light visual language:
// warm off-white bg, white card panel, dark text, accent orange-red
import SwiftUI
import SwiftData

struct TaskDetailScreen: View {

    // MARK: - Data
    @Bindable var task: EmberTask

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router

    // MARK: - State
    @State private var newSubtaskTitle:        String = ""
    @State private var isEditingTitle:         Bool   = false
    @State private var editedTitle:            String = ""
    @State private var showDeleteConfirmation: Bool   = false
    @FocusState private var isTitleFocused:    Bool
    @FocusState private var isSubtaskFocused:  Bool

    // MARK: - Computed
    private var sortedSubtasks: [Subtask] {
        task.subtasks.sorted { $0.displayOrder < $1.displayOrder }
    }
    private var completedSubtaskCount: Int {
        task.subtasks.filter { $0.isCompleted }.count
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Background — warm off-white, same as HomeScreen
            Color(hex: "EEEAE3").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Back nav + title area ─────────────────────────
                    backButton
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    // ── Task title ────────────────────────────────────
                    titleSection
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .onChange(of: isEditingTitle) { _, editing in
                            if editing { isTitleFocused = true }
                        }

                    // ── Metadata pills ────────────────────────────────
                    metadataRow
                        .padding(.horizontal, 24)
                        .padding(.top, 12)

                    // ── White content card ────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {

                        // Section header
                        HStack {
                            Text("Subtasks")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: "1A1A1A"))
                            Spacer()
                            if !task.subtasks.isEmpty {
                                Text("\(completedSubtaskCount)/\(task.subtasks.count)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color(hex: "9A9A9A"))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 14)

                        // Subtask list or empty state
                        if sortedSubtasks.isEmpty {
                            Text("No subtasks yet")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(sortedSubtasks) { subtask in
                                    lightSubtaskRow(subtask: subtask)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button("Delete", role: .destructive) {
                                                withAnimation(EmberAnimation.fadeOut) {
                                                    deleteSubtask(subtask)
                                                }
                                            }
                                        }
                                        .transition(
                                            .asymmetric(
                                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                                removal:   .opacity.combined(with: .move(edge: .trailing))
                                            )
                                        )
                                }
                            }
                            .padding(.bottom, 8)
                        }

                        // Divider
                        Rectangle()
                            .fill(Color(hex: "1A1A1A").opacity(0.06))
                            .frame(height: 1)
                            .padding(.horizontal, 20)

                        // Add subtask input
                        addSubtaskInput
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .animation(EmberAnimation.fadeIn, value: sortedSubtasks.count)

                    // ── Delete button ─────────────────────────────────
                    deleteButton
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 48)
                }
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
    }

    // MARK: - Back button

    private var backButton: some View {
        Button {
            router.goBack()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                Text("Today")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(Color(hex: "1A1A1A").opacity(0.55))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Title section

    @ViewBuilder
    private var titleSection: some View {
        if isEditingTitle {
            TextField("Task title", text: $editedTitle)
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .focused($isTitleFocused)
                .submitLabel(.done)
                .onSubmit { commitTitleEdit() }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
        } else {
            Text(task.title)
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .strikethrough(task.isCompleted, color: Color(hex: "1A1A1A").opacity(0.35))
                .opacity(task.isCompleted ? 0.50 : 1.0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    editedTitle   = task.title
                    isEditingTitle = true
                }
        }
    }

    // MARK: - Metadata row

    private var metadataRow: some View {
        HStack(spacing: 8) {
            // Status pill
            Text(task.isCompleted ? "Completed" : "In progress")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(task.isCompleted ? Color(hex: "4A7C59") : Color(hex: "E8562A"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(task.isCompleted
                              ? Color(hex: "96B89A").opacity(0.30)
                              : Color(hex: "E8562A").opacity(0.10))
                )

            // Carried forward badge
            if task.isCarriedForward {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 9, weight: .medium))
                    Text("Carried")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color(hex: "1A1A1A").opacity(0.50))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color(hex: "1A1A1A").opacity(0.07)))
            }

            Spacer()
        }
        .animation(EmberAnimation.subtaskCheck, value: task.isCompleted)
    }

    // MARK: - Light subtask row (inline, no dark theme)

    private func lightSubtaskRow(subtask: Subtask) -> some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(EmberAnimation.subtaskCheck) {
                    subtask.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(subtask.isCompleted ? Color(hex: "1A1A1A") : Color.clear)
                        .frame(width: 22, height: 22)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            Color(hex: "1A1A1A").opacity(subtask.isCompleted ? 0 : 0.20),
                            lineWidth: 1
                        )
                        .frame(width: 22, height: 22)
                    if subtask.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Title
            Text(subtask.title)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "1A1A1A").opacity(subtask.isCompleted ? 0.40 : 0.85))
                .strikethrough(subtask.isCompleted, color: Color(hex: "1A1A1A").opacity(0.30))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clear)
    }

    // MARK: - Add subtask input

    private var addSubtaskInput: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color(hex: "E8562A"))

            TextField("Add a subtask...", text: $newSubtaskTitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "1A1A1A"))
                .focused($isSubtaskFocused)
                .submitLabel(.done)
                .onSubmit { addSubtask() }
        }
    }

    // MARK: - Delete button

    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            Text("Delete Task")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.red.opacity(0.65))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func commitTitleEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { task.title = trimmed }
        isEditingTitle = false
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation(EmberAnimation.fadeIn) {
            let subtask = Subtask(title: trimmed, displayOrder: task.subtasks.count)
            modelContext.insert(subtask)
            task.subtasks.append(subtask)
        }
        newSubtaskTitle = ""
    }

    private func deleteSubtask(_ subtask: Subtask) {
        task.subtasks.removeAll { $0.id == subtask.id }
        modelContext.delete(subtask)
    }

    private func deleteTask() {
        modelContext.delete(task)
        router.goBack()
    }
}

// MARK: - Previews

#Preview("In Progress") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx   = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())
    let task  = EmberTask(title: "You Have A Meeting", displayOrder: 0, dayDate: today)
    ctx.insert(task)
    let s1 = Subtask(title: "Prep presentation deck", displayOrder: 0); s1.task = task; ctx.insert(s1)
    let s2 = Subtask(title: "Send calendar invite", displayOrder: 1); s2.task = task; ctx.insert(s2)
    let s3 = Subtask(title: "Book conference room", displayOrder: 2); s3.task = task; ctx.insert(s3)

    return NavigationStack {
        TaskDetailScreen(task: task)
    }
    .environment(EmberRouter())
    .modelContainer(container)
}

#Preview("Completed") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx   = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())
    let task  = EmberTask(title: "Call Wiz For Update", displayOrder: 0, dayDate: today)
    task.isCompleted = true
    ctx.insert(task)

    return NavigationStack {
        TaskDetailScreen(task: task)
    }
    .environment(EmberRouter())
    .modelContainer(container)
}
