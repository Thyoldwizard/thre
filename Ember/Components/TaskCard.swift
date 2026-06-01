// TaskCard.swift
// Visual V2 — white card, paper-lift shadow, coral accent, dark title (2026-03-21)
import SwiftUI
import SwiftData

// MARK: - TaskCard

struct TaskCard: View {

    @Bindable var task: EmberTask

    /// Slot index (0, 1, 2) — retained for future use
    var slotIndex: Int = 0

    /// Navigation callback
    var onTap: (() -> Void)?

    // MARK: - Press & progress state
    @State private var isPressing:         Bool    = false
    @State private var completionProgress: CGFloat = 0
    @State private var scale:              CGFloat = 1.0

    // MARK: - Gesture internals
    @State private var pressTask:      Task<Void, Never>? = nil
    @State private var hapticTask:     Task<Void, Never>? = nil
    @State private var pressStartTime: Date?              = nil

    private let hapticService = HapticService()
    private let holdDuration: TimeInterval = 1.5

    // MARK: - Design tokens (V2 light)
    private let coral       = Color(hex: "E8562A")
    private let textPrimary = Color(hex: "1A1A1A")

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // White card surface
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(task.isCompleted ? Color(hex: "F2F0ED") : Color.white)

            // Progress bar (bottom edge, hold feedback)
            progressBar

            // Title — bottom-left, 16pt padding
            if !task.title.isEmpty {
                cardContent
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }

            // Subtask thread — right side, only when subtasks exist
            if !task.subtasks.isEmpty {
                subtaskThread
            }

        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130)
        .shadow(
            color: isPressing
                ? Color.black.opacity(0.14)
                : Color.black.opacity(0.08),
            radius: isPressing ? 18 : 12,
            x: 0,
            y: isPressing ? 8 : 4
        )
        .scaleEffect(scale)
        .gesture(holdGesture)
        .accessibilityLabel(task.title)
        .accessibilityValue(task.isCompleted ? "Completed" : "Not completed")
        .accessibilityHint("Press and hold to complete. Tap to see details.")
        .contextMenu {
            Button(role: .destructive) {
                if let context = task.modelContext {
                    context.delete(task)
                }
            } label: {
                Label("Delete Task", systemImage: "trash")
            }
        }
    }

    // MARK: - Card content (bottom-left, SF Pro Semibold 17pt)

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Carried-forward tag (only when relevant)
            if task.isCarriedForward && !task.isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 10, weight: .medium))
                    Text("Carried forward")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(coral.opacity(0.7))
            }

            // Task title — SF Pro Semibold 17pt, #1A1A1A (or dimmed when done)
            Text(task.title)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .foregroundStyle(
                    task.isCompleted
                        ? Color(hex: "1A1A1A").opacity(0.35)
                        : textPrimary
                )
                .strikethrough(task.isCompleted, color: Color(hex: "1A1A1A").opacity(0.35))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Subtask progress — coral accent, subtle
            if !task.subtasks.isEmpty {
                let done = task.subtasks.filter { $0.isCompleted }.count
                Text("\(done)/\(task.subtasks.count) subtasks")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(coral.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Subtask thread (right edge, vertical line + dots)

    private var subtaskThread: some View {
        GeometryReader { geo in
            let subtasks = task.subtasks.sorted { $0.displayOrder < $1.displayOrder }
            let count = subtasks.count
            let dotSize: CGFloat = 9
            let lineX: CGFloat = geo.size.width - 16 - dotSize / 2
            let topPad: CGFloat = 20
            let bottomPad: CGFloat = 20
            let usableHeight = geo.size.height - topPad - bottomPad
            let positions: [CGFloat] = count == 1
                ? [topPad + usableHeight / 2]
                : (0..<count).map { i in
                    topPad + usableHeight * CGFloat(i) / CGFloat(count - 1)
                }

            ZStack {
                if count > 1 {
                    Rectangle()
                        .fill(Color(hex: "1A1A1A").opacity(0.40))
                        .frame(width: 2, height: positions.last! - positions.first!)
                        .position(x: lineX, y: (positions.first! + positions.last!) / 2)
                }

                ForEach(0..<count, id: \.self) { i in
                    let completed = subtasks[i].isCompleted
                    Circle()
                        .fill(completed
                            ? Color(hex: "1A1A1A").opacity(0.90)
                            : Color.clear)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    Color(hex: "1A1A1A").opacity(completed ? 0 : 0.50),
                                    lineWidth: 2
                                )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .position(x: lineX, y: positions[i])
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
    }

    // MARK: - Progress bar (coral fill along bottom)

    private var progressBar: some View {
        VStack {
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.clear).frame(height: 3)
                    Rectangle()
                        .fill(coral)
                        .frame(width: geo.size.width * completionProgress, height: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                }
            }
            .frame(height: 3)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(completionProgress > 0 ? 1 : 0)
        .animation(.linear, value: completionProgress)
    }

    // MARK: - Long-press gesture

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressing, !task.isCompleted else { return }
                isPressing     = true
                pressStartTime = Date()

                withAnimation(EmberAnimation.cardPress) { scale = 0.97 }
                hapticService.playGentleContinuous(duration: holdDuration)

                hapticTask = Task { @MainActor in
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(0.6))
                        guard !Task.isCancelled else { break }
                        hapticService.playHeartbeat()
                    }
                }

                pressTask = Task { @MainActor in
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(0.016))
                        guard !Task.isCancelled else { break }
                        completionProgress += CGFloat(0.016 / holdDuration)
                        if completionProgress >= 1.0 {
                            triggerCompletion()
                            break
                        }
                    }
                }
            }
            .onEnded { _ in
                let duration = pressStartTime.map { Date().timeIntervalSince($0) } ?? 1
                if duration < 0.15 && completionProgress < 1.0 {
                    cancelPress()
                    onTap?()
                    return
                }
                guard completionProgress < 1.0 else { return }
                cancelPress()
            }
    }

    // MARK: - Completion trigger

    private func triggerCompletion() {
        hapticTask?.cancel(); hapticTask = nil
        isPressing = false

        withAnimation(EmberAnimation.cardRelease) { scale = 1.0 }

        AudioService.shared.play("singing-bowl")
        hapticService.playCompletionBurst()

        withAnimation(EmberAnimation.completionExhale) {
            task.isCompleted    = true
            task.completionDate = Date()
            completionProgress  = 0
        }
    }

    // MARK: - Cancel press

    private func cancelPress() {
        pressTask?.cancel();  pressTask  = nil
        hapticTask?.cancel(); hapticTask = nil

        withAnimation(EmberAnimation.completionExhale) {
            completionProgress = 0
            isPressing = false
            scale = 1.0
        }
    }
}
