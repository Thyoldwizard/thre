// SubtaskRow.swift
import SwiftUI

struct SubtaskRow: View {
    @Bindable var subtask: Subtask

    var body: some View {
        HStack(spacing: EmberSpacing.sm) {
            // MARK: - Checkbox
            Button {
                withAnimation(EmberAnimation.subtaskCheck) {
                    subtask.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: EmberCornerRadii.small, style: .continuous)
                        .fill(subtask.isCompleted ? EmberColors.accent : EmberColors.cardSurfaceHover)
                        .frame(width: 24, height: 24)

                    if !subtask.isCompleted {
                        RoundedRectangle(cornerRadius: EmberCornerRadii.small, style: .continuous)
                            .strokeBorder(EmberColors.glassStroke, lineWidth: 1)
                            .frame(width: 24, height: 24)
                    }

                    if subtask.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // MARK: - Title
            Text(subtask.title)
                .font(EmberTypography.body)
                .completedStyle(subtask.isCompleted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, EmberSpacing.sm)
        .padding(.horizontal, EmberSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.medium, style: .continuous)
                .fill(EmberColors.cardSurface.opacity(0.5))
        )
    }
}
