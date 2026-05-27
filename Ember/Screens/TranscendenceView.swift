// TranscendenceView.swift
// Victory screen — solid coral, bold number, clean typography.
import SwiftUI
import SwiftData

struct TranscendenceView: View {

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    // MARK: - Animation state
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 24

    // MARK: - Body

    var body: some View {
        ZStack {
            // Solid coral background
            Color(hex: "E8562A").ignoresSafeArea()

            // Center content
            VStack(spacing: 0) {
                Spacer()

                // Large "3"
                Text("3")
                    .font(.system(size: 120, weight: .thin))
                    .foregroundStyle(.white)

                // "tasks done today"
                Text("tasks done today")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .padding(.top, 4)

                // Gap
                Spacer().frame(height: 40)

                // Main message
                Text("All three. Done.")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .opacity(textOpacity)
            .offset(y: textOffset)

            // "Tap anywhere to continue" — bottom safe area
            VStack {
                Spacer()
                Text("Tap anywhere to continue")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.40))
                    .padding(.bottom, 32)
            }
            .opacity(textOpacity)

            // Full-screen tap target
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { dismissView() }
        }
        .ignoresSafeArea()
        .onAppear {
            createOrUpdateDailyRecord()
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                textOpacity = 1
                textOffset  = 0
            }
        }
    }

    // MARK: - Dismiss

    private func dismissView() {
        withAnimation(.easeIn(duration: 0.25)) {
            textOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            router.showTranscendence = false
        }
    }

    // MARK: - DailyRecord upsert

    private func createOrUpdateDailyRecord() {
        let today    = DateService.shared.today
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<DailyRecord>(
            predicate: #Predicate<DailyRecord> { record in
                record.date >= today && record.date < tomorrow
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor)
            if let record = existing.first {
                record.taskCount         = 3
                record.completedCount    = 3
                record.allThreeCompleted = true
            } else {
                let record = DailyRecord(date: today, taskCount: 3, completedCount: 3)
                modelContext.insert(record)
            }
        } catch {
            print("DailyRecord upsert failed: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    TranscendenceView()
        .environment(EmberRouter())
        .modelContainer(for: [EmberTask.self, DailyRecord.self, Reflection.self], inMemory: true)
}
