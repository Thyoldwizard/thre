// StreakScreen.swift
// Redesigned to match HomeScreen light visual language:
// warm off-white bg, white panels, dark text, flame accent
import SwiftUI
import SwiftData

struct StreakScreen: View {

    // MARK: - Queries
    @Query(sort: \DailyRecord.date, order: .reverse) private var records: [DailyRecord]

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router

    // MARK: - State
    @State private var displayedMonth: Date = Date()

    // MARK: - Computed
    private var currentStreak:     Int { StreakService.shared.currentStreak(from: records) }
    private var longestStreak:     Int { StreakService.shared.longestStreak(from: records) }
    private var totalCompletedDays: Int { StreakService.shared.totalCompletedDays(from: records) }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var monthYearLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Background — warm off-white
            Color(hex: "EEEAE3").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Navigation row ────────────────────────────────
                HStack {
                    Button { router.goBack() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Today")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // ── Hero streak block ─────────────────────────────
                VStack(alignment: .leading, spacing: 4) {
                    Text("STREAK")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "9A9A9A"))
                        .tracking(3)

                    HStack(alignment: .top, spacing: 0) {
                        // Large streak number
                        VStack(alignment: .leading, spacing: -8) {
                            Text("\(currentStreak)")
                                .font(.system(size: 96, weight: .thin))
                                .foregroundStyle(Color(hex: "1A1A1A"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)

                            Text("DAYS")
                                .font(.system(size: 52, weight: .thin))
                                .foregroundStyle(Color(hex: "1A1A1A"))
                        }

                        // Vertical divider
                        Rectangle()
                            .fill(Color(hex: "1A1A1A").opacity(0.15))
                            .frame(width: 1, height: 100)
                            .padding(.leading, 20)
                            .padding(.top, 12)

                        // Right column — stats
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(longestStreak)")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                            }
                            Text("best streak")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                                .padding(.top, 2)

                            Spacer().frame(height: 12)

                            HStack(alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(totalCompletedDays)")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                            }
                            Text("perfect days")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                                .padding(.top, 2)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // ── White calendar container ──────────────────────
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)

                    VStack(alignment: .leading, spacing: 0) {

                        // Month navigation header
                        HStack {
                            Button { changeMonth(by: -1) } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "1A1A1A").opacity(0.06))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color(hex: "1A1A1A").opacity(0.60))
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Text(monthYearLabel)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color(hex: "1A1A1A"))

                            Spacer()

                            Button { changeMonth(by: 1) } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "1A1A1A").opacity(isCurrentMonth ? 0.03 : 0.06))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Color(hex: "1A1A1A").opacity(isCurrentMonth ? 0.20 : 0.60))
                                }
                            }
                            .disabled(isCurrentMonth)
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Weekday headers
                        HStack(spacing: 0) {
                            ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                                Text(day)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color(hex: "9A9A9A"))
                                    .tracking(1)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)

                        // Day grid
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                            spacing: 8
                        ) {
                            ForEach(Array(calendarDays.enumerated()), id: \.0) { _, maybeDate in
                                if let date = maybeDate {
                                    dayCell(for: date)
                                } else {
                                    Color.clear.frame(width: 40, height: 40)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 20)

                        // Empty state inside card
                        if records.isEmpty {
                            Text("Complete all 3 tasks to light up a day")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let record    = record(for: date)
        let isToday   = Calendar.current.isDateInToday(date)
        let dayNum    = Calendar.current.component(.day, from: date)
        let completed = record?.allThreeCompleted == true
        let partial   = record != nil && !completed
        let fraction  = partial ? CGFloat(record!.completedCount) / 3.0 : 0

        ZStack {
            // Base fill
            Circle()
                .fill(completed
                      ? Color(hex: "D4B86A").opacity(0.85)
                      : Color(hex: "1A1A1A").opacity(0.04))
                .frame(width: 40, height: 40)

            // Partial arc
            if partial {
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(Color(hex: "D4B86A").opacity(0.50), lineWidth: 2)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 34, height: 34)
            }

            // Today ring
            if isToday {
                Circle()
                    .strokeBorder(Color(hex: "1A1A1A").opacity(0.30), lineWidth: 1.5)
                    .frame(width: 40, height: 40)
            }

            // Day number
            VStack(spacing: 0) {
                Text("\(dayNum)")
                    .font(.system(size: 11, weight: completed ? .semibold : .regular))
                    .foregroundStyle(
                        completed
                            ? Color(hex: "1A1A1A").opacity(0.80)
                            : Color(hex: "1A1A1A").opacity(0.45)
                    )

                if completed {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(Color(hex: "E8562A").opacity(0.70))
                }
            }
        }
        .frame(width: 40, height: 40)
    }

    // MARK: - Helpers

    private var calendarDays: [Date?] {
        let calendar      = Calendar.current
        var comps         = calendar.dateComponents([.year, .month], from: displayedMonth)
        comps.day         = 1
        let firstOfMonth  = calendar.date(from: comps)!
        let range         = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let numDays       = range.count
        let firstWeekday  = calendar.component(.weekday, from: firstOfMonth) - 1

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in 0..<numDays {
            days.append(calendar.date(byAdding: .day, value: day, to: firstOfMonth))
        }

        let remainder = days.count % 7
        if remainder != 0 {
            days += Array(repeating: nil, count: 7 - remainder)
        }
        return days
    }

    private func record(for date: Date) -> DailyRecord? {
        records.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = Calendar.current.date(
            byAdding: .month, value: value, to: displayedMonth
        ) else { return }
        withAnimation(EmberAnimation.fadeIn) { displayedMonth = newMonth }
    }
}

// MARK: - Previews

#Preview("Empty") {
    NavigationStack {
        StreakScreen()
    }
    .environment(EmberRouter())
    .modelContainer(for: [EmberTask.self, DailyRecord.self, Reflection.self], inMemory: true)
}

#Preview("With Records") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    // Seed last 12 days, alternating complete/partial
    for i in 0..<12 {
        guard let d = cal.date(byAdding: .day, value: -i, to: cal.startOfDay(for: Date())) else { continue }
        let record = DailyRecord(date: d, taskCount: 3, completedCount: i % 3 == 0 ? 3 : (i % 3))
        ctx.insert(record)
    }

    return NavigationStack {
        StreakScreen()
    }
    .environment(EmberRouter())
    .modelContainer(container)
}
