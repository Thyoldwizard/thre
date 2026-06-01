// EmptyTaskSlot.swift
// V2: dashed border card, "Add a task" text, coral + only on first empty slot.
import SwiftUI

struct EmptyTaskSlot: View {

    /// True for the first unfilled slot — shows coral + icon instead of gray
    var isFirstEmptySlot: Bool = false
    var onTap: () -> Void

    private let coral      = Color(hex: "E8562A")
    private let dashedBorder = Color(hex: "C4C0BA").opacity(0.40)
    private let textTertiary = Color(hex: "C4C0BA")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isFirstEmptySlot ? coral : textTertiary)

                Text("Add a task")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundStyle(textTertiary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 88)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        dashedBorder,
                        style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add a task")
        .accessibilityHint("Tap to create a new task")
    }
}
