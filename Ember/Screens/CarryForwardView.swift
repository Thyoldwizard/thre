// CarryForwardView.swift
// Dark studio decision surface for unfinished tasks.
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
    @State private var noticeSymbolTrigger = false

    // MARK: - Studio tokens
    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel
    private let panelElevated = EmberColors.nestedRow
    private let panelMuted = EmberColors.raisedElement
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private let hairline = EmberColors.divider
    private var ember: Color { EmberColors.ember }

    // MARK: - Init
    init() {
        let yesterday = DateService.shared.yesterday
        let today = DateService.shared.today
        let tomorrow = DateService.shared.calendar.date(byAdding: .day, value: 1, to: today)!

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
    private var isOverLimit: Bool { selectedForCarry.count > availableSlots }
    private var excess: Int { max(0, selectedForCarry.count - availableSlots) }
    private var canCarryForward: Bool {
        !selectedForCarry.isEmpty && !isOverLimit && availableSlots > 0
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerPanel
                    selectionPanel
                    actionPanel
                }
                .padding(.horizontal, EmberSpacing.screenHorizontal)
                .padding(.top, 44)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            selectedForCarry = Set(yesterdayIncompleteTasks.map { $0.id })
            Task {
                try? await Task.sleep(for: .milliseconds(50))
                hasAppeared = true
                noticeSymbolTrigger.toggle()
            }
        }
        .onChange(of: isOverLimit) { _, _ in
            noticeSymbolTrigger.toggle()
        }
    }

    // MARK: - Layout
    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A NEW DAY")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(textSecondary)

            Text("Decide what still matters.")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(textPrimary)
                .lineLimit(3)

            Text("\(availableSlots) open slot\(availableSlots == 1 ? "" : "s") for today")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ember)
                .padding(.top, 4)
        }
        .padding(EmberSpacing.screenHorizontal)
        .background(studioPanel)
        .opacity(hasAppeared ? 1 : 0)
        .animation(EmberAnimation.fadeIn, value: hasAppeared)
    }

    private var selectionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CARRY FORWARD")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.4)
                    .foregroundStyle(textSecondary)

                Spacer()

                Text("\(selectedForCarry.count) selected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isOverLimit ? EmberColors.risk.opacity(0.78) : ember)
            }

            VStack(spacing: 10) {
                ForEach(Array(yesterdayIncompleteTasks.enumerated()), id: \.1.id) { index, task in
                    StudioTaskSelectCard(
                        task: task,
                        isSelected: selectedForCarry.contains(task.id),
                        isOverLimit: isOverLimit && selectedForCarry.contains(task.id)
                    ) {
                        withAnimation(EmberAnimation.subtaskCheck) {
                            toggleSelection(task.id)
                        }
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(EmberAnimation.staggeredCardAppear(index: index), value: hasAppeared)
                }
            }

            noticeRow
        }
        .padding(EmberSpacing.screenHorizontal)
        .background(studioPanel)
    }

    private var noticeRow: some View {
        HStack(spacing: 8) {
            Image(systemName: isOverLimit ? "exclamationmark.circle" : "info.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isOverLimit ? EmberColors.risk.opacity(0.8) : textSecondary)
                .completeBounce(noticeSymbolTrigger)

            Text(noticeText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(isOverLimit ? EmberColors.risk.opacity(0.8) : textSecondary)

            Spacer()
        }
    }

    private var noticeText: String {
        if availableSlots == 0 { return "Today's three slots are already set." }
        if isOverLimit { return "Deselect \(excess) to continue." }
        return "Carry only what still deserves a slot."
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            Button {
                carryForward()
            } label: {
                Text("Carry Forward")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canCarryForward ? background : textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                            .fill(canCarryForward ? ember : panelMuted)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canCarryForward)

            Button {
                letGo()
            } label: {
                Text("Let Them Go")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(EmberSpacing.screenHorizontal)
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

        DailyRecordService.upsertRecord(in: modelContext)
        router.showCarryForward = false
    }

    private func letGo() {
        AudioService.shared.play("let-go")
        Task {
            try? await Task.sleep(for: .milliseconds(200))
            router.showCarryForward = false
        }
    }
}

// MARK: - Studio Task Select Card
private struct StudioTaskSelectCard: View {
    let task: EmberTask
    let isSelected: Bool
    let isOverLimit: Bool
    let onTap: () -> Void

    private var ember:        Color { EmberColors.ember }
    private let panelMuted  = EmberColors.raisedElement
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private let panelElevated = EmberColors.nestedRow
    private var background:   Color { EmberColors.studioBackground }

    var body: some View {
        Button { onTap() } label: { cardContent }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(task.title)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select")
            .animation(EmberAnimation.subtaskCheck, value: isSelected)
            .animation(EmberAnimation.subtaskCheck, value: isOverLimit)
    }

    private var cardContent: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(isSelected ? ember : panelMuted)
                .frame(width: 3)

            Text(task.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(textPrimary.opacity(isSelected ? 1 : 0.48))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 16)

            ZStack {
                Circle()
                    .fill(isSelected ? ember : panelMuted)
                    .frame(width: 28, height: 28)

                Image(systemName: isSelected ? "checkmark" : "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isSelected ? background : textSecondary)
            }
            .padding(.trailing, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panelElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .strokeBorder(isOverLimit ? EmberColors.risk.opacity(0.42) : ember.opacity(isSelected ? 0.28 : 0), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous))
    }
}
