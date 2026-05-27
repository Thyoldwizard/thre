// CarryForwardView.swift
// Redesigned to match HomeScreen light visual language:
// warm off-white bg, large thin heading, white card for task selection
import SwiftUI
import SwiftData

struct CarryForwardView: View {

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router

    // MARK: - Queries
    @Query private var yesterdayIncompleteTasks: [EmberTask]
    @Query private var todayTasks: [EmberTask]

    // MARK: - State
    @State private var selectedForCarry: Set<UUID> = []
    @State private var hasAppeared = false

    // MARK: - Card colors (same palette as HomeScreen)
    private let cardColors: [Color] = [
        Color(hex: "D4B86A"),
        Color(hex: "8FA8B8"),
        Color(hex: "96B89A")
    ]

    // MARK: - Init
    init() {
        let yesterday = DateService.shared.yesterday
        let today     = DateService.shared.today
        let tomorrow  = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        _yesterdayIncompleteTasks = Query(
            filter: #Predicate<EmberTask> { task in
                task.dayDate >= yesterday &&
                task.dayDate < today &&
                task.isCompleted == false
            },
            sort: \EmberTask.displayOrder
        )

        _todayTasks = Query(
            filter: #Predicate<EmberTask> { task in
                task.dayDate >= today && task.dayDate < tomorrow
            },
            sort: \EmberTask.displayOrder
        )
    }

    // MARK: - Computed
    private var availableSlots: Int { max(0, 3 - todayTasks.count) }
    private var isOverLimit: Bool   { selectedForCarry.count > availableSlots }
    private var excess: Int         { max(0, selectedForCarry.count - availableSlots) }
    private var canCarryForward: Bool {
        !selectedForCarry.isEmpty && !isOverLimit && availableSlots > 0
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Background — warm off-white
            Color(hex: "EEEAE3").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Heading block ─────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Text("A NEW DAY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "9A9A9A"))
                            .tracking(3)

                        Text("Yesterday's\nunfinished tasks")
                            .font(.system(size: 46, weight: .thin))
                            .foregroundStyle(Color(hex: "1A1A1A"))
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .opacity(hasAppeared ? 1 : 0)
                    .animation(EmberAnimation.fadeIn, value: hasAppeared)

                    // ── White card — task selection ───────────────
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 0) {

                            // Header row inside card
                            HStack {
                                Text("Carry forward")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                                Spacer()
                                Text("\(selectedForCarry.count) selected")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(Color(hex: "9A9A9A"))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 14)

                            // Task cards
                            VStack(spacing: 10) {
                                ForEach(Array(yesterdayIncompleteTasks.enumerated()), id: \.1.id) { index, task in
                                    LightTaskSelectCard(
                                        task: task,
                                        color: cardColors[min(index, cardColors.count - 1)],
                                        isSelected: selectedForCarry.contains(task.id),
                                        isOverLimit: isOverLimit && selectedForCarry.contains(task.id)
                                    ) {
                                        withAnimation(EmberAnimation.subtaskCheck) {
                                            toggleSelection(task.id)
                                        }
                                    }
                                    .opacity(hasAppeared ? 1 : 0)
                                    .offset(y: hasAppeared ? 0 : 20)
                                    .animation(
                                        EmberAnimation.staggeredCardAppear(index: index),
                                        value: hasAppeared
                                    )
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 16)

                            // Slot / over-limit notice
                            if availableSlots > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: isOverLimit ? "exclamationmark.circle" : "info.circle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(isOverLimit
                                                         ? Color(hex: "E8562A")
                                                         : Color(hex: "9A9A9A"))

                                    if isOverLimit {
                                        Text("Deselect \(excess) to continue.")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundStyle(Color(hex: "E8562A"))
                                    } else {
                                        Text("Up to \(availableSlots) task(s) can be carried.")
                                            .font(.system(size: 13, weight: .regular))
                                            .foregroundStyle(Color(hex: "9A9A9A"))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                                .animation(EmberAnimation.fadeIn, value: isOverLimit)
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Color(hex: "9A9A9A"))
                                    Text("Today's tasks are already set.")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundStyle(Color(hex: "9A9A9A"))
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 14)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    // ── Action buttons ────────────────────────────
                    VStack(spacing: 12) {
                        // Primary — Carry Forward
                        Button {
                            carryForward()
                        } label: {
                            Text("Carry Forward")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(canCarryForward ? Color.white : Color.white.opacity(0.45))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(canCarryForward
                                              ? Color(hex: "1A1A1A")
                                              : Color(hex: "1A1A1A").opacity(0.25))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canCarryForward)

                        // Secondary — Let go
                        Button {
                            letGo()
                        } label: {
                            Text("Let them all go")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        .onAppear {
            selectedForCarry = Set(yesterdayIncompleteTasks.map { $0.id })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedForCarry.contains(id) {
            selectedForCarry.remove(id)
        } else {
            selectedForCarry.insert(id)
        }
    }

    private func carryForward() {
        guard canCarryForward else { return }

        let existingTitles = Set(todayTasks.map { $0.title.lowercased() })
        var nextOrder = todayTasks.count

        for task in yesterdayIncompleteTasks where selectedForCarry.contains(task.id) {
            guard !existingTitles.contains(task.title.lowercased()) else { continue }

            let newTask = EmberTask(
                title: task.title,
                displayOrder: nextOrder,
                dayDate: DateService.shared.today,
                isCarriedForward: true
            )

            for subtask in task.subtasks.sorted(by: { $0.displayOrder < $1.displayOrder }) {
                let newSubtask = Subtask(title: subtask.title, displayOrder: subtask.displayOrder)
                newSubtask.isCompleted = subtask.isCompleted
                newTask.subtasks.append(newSubtask)
                modelContext.insert(newSubtask)
            }

            modelContext.insert(newTask)
            nextOrder += 1
        }

        router.showCarryForward = false
    }

    private func letGo() {
        AudioService.shared.play("let-go")
        withAnimation(EmberAnimation.fadeOut) {}
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            router.showCarryForward = false
        }
    }
}

// MARK: - Light Task Select Card

private struct LightTaskSelectCard: View {
    let task:        EmberTask
    let color:       Color
    let isSelected:  Bool
    let isOverLimit: Bool
    let onTap:       () -> Void

    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? color : color.opacity(0.35))

            HStack(spacing: 12) {
                // Title
                Text(task.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .opacity(isSelected ? 1.0 : 0.50)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
                    .padding(.leading, 16)
                    .padding(.trailing, 48)
            }

            // Selection circle — top-right
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "1A1A1A").opacity(0.80) : Color(hex: "1A1A1A").opacity(0.08))
                    .frame(width: 26, height: 26)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .strokeBorder(Color(hex: "1A1A1A").opacity(0.20), lineWidth: 1)
                        .frame(width: 26, height: 26)
                }
            }
            .animation(EmberAnimation.subtaskCheck, value: isSelected)
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Over-limit red border
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isOverLimit ? Color.red.opacity(0.35) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(scale)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            withAnimation(EmberAnimation.cardPress)   { scale = 0.97 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(EmberAnimation.cardRelease) { scale = 1.0 }
            }
            onTap()
        }
        .animation(EmberAnimation.subtaskCheck, value: isOverLimit)
    }
}

// MARK: - Previews

#Preview("With Tasks") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, Subtask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx       = container.mainContext
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!

    ctx.insert(EmberTask(title: "You Have A Meeting", displayOrder: 0, dayDate: yesterday))
    ctx.insert(EmberTask(title: "Call Wiz For Update", displayOrder: 1, dayDate: yesterday))

    return CarryForwardView()
        .environment(EmberRouter())
        .modelContainer(container)
}
