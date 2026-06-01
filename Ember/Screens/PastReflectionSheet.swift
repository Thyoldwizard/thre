import SwiftUI

struct PastReflectionSheet: View {
    let reflection: Reflection

    private var background: Color { EmberColors.studioBackground }
    private let panel = Color(hex: "181818")
    private let panelElevated = Color(hex: "1F1F1F")
    private let textPrimary = Color(hex: "F7F3EA")
    private let textSecondary = Color(hex: "8B8B86")
    private var ember: Color { EmberColors.ember }

    private var wordCount: Int {
        reflection.text.split { $0.isWhitespace }.count
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: reflection.date).uppercased()
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerPanel
                    textPanel
                }
                .padding(18)
                .padding(.bottom, 18)
            }
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REFLECTION")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(textSecondary)

            Text(dateLabel)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(textPrimary)
                .lineLimit(2)

            HStack(spacing: 8) {
                Capsule()
                    .fill(panelElevated)
                    .overlay(
                        Text("\(wordCount) words")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(textSecondary)
                            .padding(.horizontal, 12)
                    )
                    .frame(height: 30)

                Capsule()
                    .fill(panelElevated)
                    .overlay(
                        Circle()
                            .fill(ember)
                            .frame(width: 7, height: 7)
                    )
                    .frame(width: 34, height: 30)
            }
        }
        .padding(18)
        .background(studioPanel)
    }

    private var textPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(reflection.text)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(5)
                .foregroundStyle(textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(studioPanel)
    }

    private var studioPanel: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
