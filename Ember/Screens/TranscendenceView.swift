// TranscendenceView.swift
// Studio victory screen for completing the daily three.
import SwiftUI
import SwiftData

struct TranscendenceView: View {

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    // MARK: - Animation state
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 22
    @State private var orbitPhase: Double = 0
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false

    // MARK: - Studio tokens
    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private var ember: Color { EmberColors.ember }

    // MARK: - Body
    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                ZStack {
                    ForEach(0..<72, id: \.self) { index in
                        let angle = (Double(index) / 72) * 2 * Double.pi - Double.pi / 2
                        let radius: CGFloat = 118
                        let wave = (sin(orbitPhase + Double(index) * 0.22) + 1) / 2
                        Circle()
                            .fill(ember)
                            .frame(width: 5 + CGFloat(wave * 2), height: 5 + CGFloat(wave * 2))
                            .opacity(0.52 + wave * 0.44)
                            .position(
                                x: 150 + CGFloat(cos(angle)) * radius,
                                y: 150 + CGFloat(sin(angle)) * radius
                            )
                    }
                    .rotationEffect(.degrees(orbitPhase * 3.5))

                    Circle()
                        .stroke(EmberColors.divider, lineWidth: 1)
                        .frame(width: 178, height: 178)
                        .scaleEffect(1 + CGFloat(sin(orbitPhase) * 0.02))

                    VStack(spacing: 2) {
                        Text("3")
                            .font(.system(size: 116, weight: .thin))
                            .foregroundStyle(textPrimary)
                        Text("COMPLETE")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(ember)
                    }
                }
                .frame(width: 300, height: 300)

                VStack(spacing: 8) {
                    Text("All three. Done.")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .multilineTextAlignment(.center)

                    Text("You showed up today.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(textSecondary)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        dismissView()
                    } label: {
                        Text("Return to Today")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                                    .fill(ember)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("transcendence.return")

                    Button {
                        dismissAndReflect()
                    } label: {
                        Text("Reflect")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                                    .fill(panel)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                                            .strokeBorder(EmberColors.divider, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("transcendence.reflect")
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .onAppear {
            createOrUpdateDailyRecord()
            if !reducedMotionEnabled {
                withAnimation(.linear(duration: 7.5).repeatForever(autoreverses: false)) {
                    orbitPhase = 2 * Double.pi
                }
            }
            withAnimation(.easeOut(duration: reducedMotionEnabled ? 0.18 : 0.5).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }

    // MARK: - Dismiss
    private func dismissView() {
        withAnimation(.easeIn(duration: 0.22)) {
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            router.showTranscendence = false
        }
    }

    private func dismissAndReflect() {
        withAnimation(.easeIn(duration: 0.22)) {
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            router.showTranscendence = false
            router.navigate(to: .reflection)
        }
    }

    // MARK: - DailyRecord upsert
    private func createOrUpdateDailyRecord() {
        DailyRecordService.upsertRecord(in: modelContext)
    }
}
