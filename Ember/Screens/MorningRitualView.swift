// MorningRitualView.swift
// First-run onboarding plus the daily opening surface.
import SwiftUI
import SwiftData

struct MorningRitualView: View {

    // MARK: - Environment
    @Environment(EmberRouter.self) private var router

    // MARK: - Queries
    @Query private var todayTasks: [EmberTask]

    // MARK: - State
    @State private var currentPage: OnboardingPage
    @State private var nameDraft = EmberPreferences.displayName
    @AppStorage(EmberPreferenceKey.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false
    @FocusState private var isNameFocused: Bool

    // MARK: - Studio tokens
    private var background: Color { EmberColors.studioBackground }
    private var panel: Color { EmberColors.primaryPanel }
    private var panelElevated: Color { EmberColors.nestedRow }
    private var panelMuted: Color { EmberColors.raisedElement }
    private var textPrimary: Color { EmberColors.textPrimary }
    private var textSecondary: Color { EmberColors.textSecondary }
    private var textTertiary: Color { EmberColors.textTertiary }
    private var ember: Color { EmberColors.ember }
    private var onboardingHeadlineFont: Font { .system(size: 32, weight: .bold, design: .default) }
    private var onboardingFieldFont: Font { .system(size: 19, weight: .semibold, design: .default) }
    private var dailyHeadlineFont: Font { .system(size: 30, weight: .bold, design: .default) }

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _currentPage = State(initialValue: Self.initialOnboardingPage)
        _todayTasks = Query(
            filter: #Predicate<EmberTask> { $0.dayDate >= today && $0.dayDate < tomorrow },
            sort: \EmberTask.displayOrder
        )
    }

    private static var initialOnboardingPage: OnboardingPage {
        switch ProcessInfo.processInfo.environment["EMBER_UI_TESTING_ONBOARDING_PAGE"] {
        case "choose": return .choose
        case "rhythm": return .rhythm
        case "account": return .account
        case "daily": return .daily
        default: return .promise
        }
    }

    private var openSlots: Int {
        max(0, 3 - todayTasks.count)
    }

    private var progressLabel: String {
        "\(todayTasks.count)/3 chosen"
    }

    private var progressFraction: CGFloat {
        CGFloat(todayTasks.count) / 3
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date()).uppercased()
    }

    private var activePages: [OnboardingPage] {
        hasCompletedOnboarding ? [.daily] : OnboardingPage.firstRunPages
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            if !hasCompletedOnboarding {
                EmberOnboardingHeatBackdrop()
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                pageProgress
                    .padding(.horizontal, EmberSpacing.screenHorizontal)
                    .padding(.top, 24)

                TabView(selection: $currentPage) {
                    ForEach(activePages) { page in
                        pageContent(for: page)
                            .tag(page)
                            .padding(.horizontal, EmberSpacing.screenHorizontal)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(EmberAnimation.smooth, value: currentPage)

                bottomControls
                    .padding(.horizontal, EmberSpacing.screenHorizontal)
                    .padding(.bottom, 24)
            }
        }
        .interactiveDismissDisabled()
        .onAppear {
            if hasCompletedOnboarding {
                currentPage = .daily
            }
        }
        .onChange(of: hasCompletedOnboarding) { _, completed in
            if completed {
                currentPage = .daily
            }
        }
    }

    @ViewBuilder
    private func pageContent(for page: OnboardingPage) -> some View {
        switch page {
        case .promise:
            promisePage
        case .choose:
            choosePage
        case .rhythm:
            rhythmPage
        case .account:
            accountPage
        case .daily:
            dailyPage
        }
    }

    private var pageProgress: some View {
        HStack(spacing: EmberSpacing.sm) {
            ForEach(activePages) { page in
                Capsule()
                    .fill(page.rawValue <= currentPage.rawValue ? ember : EmberColors.divider)
                    .frame(height: 4)
                    .animation(EmberAnimation.snappy, value: currentPage)
            }
        }
        .opacity(activePages.count > 1 ? 1 : 0)
        .accessibilityHidden(true)
    }

    private var promisePage: some View {
        VStack(alignment: .leading, spacing: EmberSpacing.lg) {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: EmberSpacing.md) {
                Text("THRE")
                    .emberSectionLabel()

                Text("Choose the three that matter.")
                    .font(onboardingHeadlineFont)
                    .foregroundStyle(textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
                    .lineSpacing(2)

                Text("A quiet studio for deciding what deserves today.")
                    .font(EmberTypography.body)
                    .foregroundStyle(textSecondary)
            }

            OrbitPreview(chosenCount: 0, accent: ember)
                .frame(height: 270)
                .frame(maxWidth: .infinity)

            Spacer(minLength: 24)
        }
    }

    private var choosePage: some View {
        VStack(alignment: .leading, spacing: EmberSpacing.lg) {
            Spacer(minLength: 18)

            Text("THREE SLOTS")
                .emberSectionLabel()

            Text("Give each focus a place.")
                .font(onboardingHeadlineFont)
                .foregroundStyle(textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
                .lineSpacing(2)

            VStack(spacing: EmberSpacing.sm) {
                onboardingSlot("01", title: "Choose the launch slice", subtitle: "the one that moves the day", isActive: true)
                onboardingSlot("02", title: "Give it a time block", subtitle: "optional, never noisy", isActive: false)
                onboardingSlot("03", title: "Leave room for life", subtitle: "three is the constraint", isActive: false)
            }

            Spacer(minLength: 24)
        }
    }

    private var rhythmPage: some View {
        VStack(alignment: .leading, spacing: EmberSpacing.lg) {
            Spacer(minLength: 18)

            Text("RHYTHM")
                .emberSectionLabel()

            Text("See the proof that you showed up.")
                .font(onboardingHeadlineFont)
                .foregroundStyle(textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.72)
                .lineSpacing(2)

            StreakProofPreview(accent: ember)
                .padding(.top, EmberSpacing.sm)

            InsightPreview()

            Spacer(minLength: 24)
        }
    }

    private var accountPage: some View {
        VStack(alignment: .leading, spacing: EmberSpacing.lg) {
            Spacer(minLength: 18)

            Text("MAKE IT YOURS")
                .emberSectionLabel()

            Text("What should thre call you?")
                .font(onboardingHeadlineFont)
                .foregroundStyle(textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.72)
                .lineSpacing(2)

            TextField("", text: $nameDraft)
                .focused($isNameFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(onboardingFieldFont)
                .foregroundStyle(textPrimary)
                .padding(EmberSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .fill(EmberColors.recessedSurface.opacity(0.82))
                        .overlay(
                            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                                .strokeBorder(isNameFocused ? ember.opacity(0.8) : EmberColors.divider, lineWidth: 1)
                        )
                )
                .overlay(alignment: .leading) {
                    if nameDraft.isEmpty {
                        Text("Name")
                            .font(onboardingFieldFont)
                            .foregroundStyle(textSecondary.opacity(0.72))
                            .padding(EmberSpacing.md)
                            .allowsHitTesting(false)
                    }
                }
                .submitLabel(.done)
                .onSubmit { isNameFocused = false }

            VStack(spacing: EmberSpacing.sm) {
                signInButton(title: "Continue with Apple", systemImage: "apple.logo")
                signInButton(title: "Continue with Google", systemImage: nil)
                Button("Use thre without an account") {
                    finishOnboarding()
                }
                .font(EmberTypography.captionMedium)
                .foregroundStyle(textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, EmberSpacing.sm)
            }
            .padding(.top, EmberSpacing.sm)

            Spacer(minLength: 24)
        }
    }

    private var dailyPage: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer(minLength: 48)
            headerPanel
            focusRailPanel
            Spacer(minLength: 24)
        }
    }

    private var headerPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(dateLabel)
                .emberSectionLabel()

            Text(dailyGreeting)
                .font(dailyHeadlineFont)
                .foregroundStyle(textPrimary)
                .lineLimit(3)
                .minimumScaleFactor(0.72)
                .lineSpacing(2)

            Text("Shape the day before the day shapes you.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(textSecondary)

            progressRail
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(studioPanel)
    }

    private var dailyGreeting: String {
        let savedName = EmberPreferences.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !savedName.isEmpty else { return "Choose the three that matter." }
        return "\(savedName), choose the three that matter."
    }

    private var progressRail: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(EmberColors.raisedElement)

                    Capsule()
                        .fill(ember)
                        .frame(width: proxy.size.width * progressFraction)
                }
            }
            .frame(height: 8)

            HStack {
                Text(progressLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(textSecondary)
                    .contentTransition(.numericText())

                Spacer()

                Text("\(openSlots) open")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(textSecondary)
                    .contentTransition(.numericText())
            }
        }
    }

    private var focusRailPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THREE FOR TODAY")
                .emberSectionLabel()

            VStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    if let task = todayTasks[safe: index] {
                        taskLine(task, index: index)
                    } else {
                        emptyLine(index: index)
                    }
                }
            }
        }
        .padding(16)
        .background(studioPanel)
    }

    private var bottomControls: some View {
        HStack(spacing: EmberSpacing.md) {
            if currentPage != activePages.first {
                Button {
                    moveBackward()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(textPrimary)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(panelMuted))
                        .overlay(Circle().strokeBorder(EmberColors.divider, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }

            Button {
                advance()
            } label: {
                Text(primaryButtonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                            .fill(ember)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(primaryButtonTitle)
        }
        .animation(EmberAnimation.snappy, value: currentPage)
    }

    private var primaryButtonTitle: String {
        if hasCompletedOnboarding { return "Begin Today" }
        switch currentPage {
        case .account: return "Enter thre"
        default: return "Next"
        }
    }

    private func advance() {
        if hasCompletedOnboarding {
            closeForToday()
            return
        }

        guard let nextPage = nextPage else {
            finishOnboarding()
            return
        }

        isNameFocused = false
        withAnimation(EmberAnimation.snappy) {
            currentPage = nextPage
        }
    }

    private func moveBackward() {
        guard let previousPage = previousPage else { return }
        isNameFocused = false
        withAnimation(EmberAnimation.snappy) {
            currentPage = previousPage
        }
    }

    private var nextPage: OnboardingPage? {
        guard let index = activePages.firstIndex(of: currentPage),
              activePages.indices.contains(index + 1)
        else { return nil }
        return activePages[index + 1]
    }

    private var previousPage: OnboardingPage? {
        guard let index = activePages.firstIndex(of: currentPage),
              activePages.indices.contains(index - 1)
        else { return nil }
        return activePages[index - 1]
    }

    private func signInButton(title: String, systemImage: String?) -> some View {
        Button {
            finishOnboarding()
        } label: {
            HStack(spacing: EmberSpacing.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                } else {
                    Text("G")
                        .font(.system(size: 18, weight: .bold))
                }

                Text(title)
                    .font(EmberTypography.bodyMedium)
            }
            .foregroundStyle(EmberColors.textOnLight)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                    .fill(EmberColors.lightPanel)
            )
        }
        .buttonStyle(.plain)
    }

    private func finishOnboarding() {
        let trimmedName = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        EmberPreferences.displayName = trimmedName
        EmberPreferences.hasCompletedOnboarding = true
        closeForToday()
    }

    private func closeForToday() {
        EmberPreferences.markMorningRitualShownToday()
        router.showMorningRitual = false
    }

    private func onboardingSlot(_ number: String, title: String, subtitle: String, isActive: Bool) -> some View {
        HStack(spacing: EmberSpacing.md) {
            Text(number)
                .font(.system(size: 32, weight: .light).monospacedDigit())
                .foregroundStyle(isActive ? ember : textTertiary)
                .frame(width: 48, alignment: .leading)

            VStack(alignment: .leading, spacing: EmberSpacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundStyle(textPrimary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(EmberTypography.caption)
                    .foregroundStyle(textSecondary)
            }

            Spacer(minLength: EmberSpacing.sm)
        }
        .padding(EmberSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panelElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(isActive ? ember.opacity(0.32) : EmberColors.divider, lineWidth: 1)
                )
        )
    }

    private func taskLine(_ task: EmberTask, index: Int) -> some View {
        HStack(spacing: 12) {
            slotNumber(index)

            Text(task.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(task.isCompleted ? textSecondary : textPrimary)
                .strikethrough(task.isCompleted, color: textSecondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(task.isCompleted ? ember : textSecondary)
                .replaceCheck(task.isCompleted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panelElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(index == 0 ? ember.opacity(0.28) : EmberColors.divider, lineWidth: 1)
                )
        )
    }

    private func emptyLine(index: Int) -> some View {
        HStack(spacing: 12) {
            slotNumber(index)

            Text("Open slot")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(textSecondary)

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(panelMuted.opacity(0.64))
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(EmberColors.divider, lineWidth: 1)
                )
        )
    }

    private func slotNumber(_ index: Int) -> some View {
        Text(String(format: "%02d", index + 1))
            .font(.system(size: 26, weight: .thin))
            .monospacedDigit()
            .foregroundStyle(slotColor(index).opacity(0.72))
            .frame(width: 38, alignment: .leading)
    }

    private func slotColor(_ index: Int) -> Color {
        switch index {
        case 0: return ember
        default: return EmberColors.textTertiary
        }
    }

    private var studioPanel: some View {
        RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
            .fill(panel)
            .overlay(
                RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                    .strokeBorder(EmberColors.divider, lineWidth: 1)
            )
    }
}

private enum OnboardingPage: Int, CaseIterable, Identifiable {
    case promise
    case choose
    case rhythm
    case account
    case daily

    var id: Int { rawValue }

    static let firstRunPages: [OnboardingPage] = [.promise, .choose, .rhythm, .account]
}

private struct OrbitPreview: View {
    let chosenCount: Int
    let accent: Color

    var body: some View {
        TimelineView(.animation) { context in
            let phase = context.date.timeIntervalSinceReferenceDate * 0.55

            ZStack {
                ForEach(0..<72, id: \.self) { index in
                    let wave = (sin(phase * 2.2 + Double(index) * 0.32) + 1) / 2
                    let isActive = index < 24
                    Capsule(style: .continuous)
                        .fill(isActive ? accent : EmberColors.raisedElement)
                        .frame(width: index % 6 == 0 ? 2.6 : 1.6, height: CGFloat(index % 6 == 0 ? 18 : 11) + CGFloat(wave) * 4)
                        .opacity(isActive ? 0.7 + wave * 0.24 : 0.25)
                        .offset(y: -104)
                        .rotationEffect(.degrees(Double(index) * 5 + phase * 28))
                }

                Circle()
                    .stroke(EmberColors.divider, lineWidth: 1)
                    .frame(width: 152, height: 152)

                VStack(spacing: EmberSpacing.xs) {
                    Text("\(chosenCount)/3")
                        .font(EmberTypography.orbitHero)
                        .foregroundStyle(EmberColors.textPrimary)

                    Text("CHOSEN")
                        .emberSectionLabel()
                }
            }
        }
    }
}

private struct StreakProofPreview: View {
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: EmberSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: EmberSpacing.sm) {
                Text("7")
                    .font(.system(size: 82, weight: .thin, design: .default).monospacedDigit())
                    .foregroundStyle(EmberColors.textPrimary)

                Text("day rhythm")
                    .font(EmberTypography.bodyMedium)
                    .foregroundStyle(EmberColors.textSecondary)
            }

            HStack(spacing: EmberSpacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    Circle()
                        .fill(index < 5 ? accent : EmberColors.raisedElement)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if index == 5 {
                                Circle()
                                    .trim(from: 0, to: 0.5)
                                    .stroke(accent, lineWidth: 5)
                                    .rotationEffect(.degrees(-90))
                            }
                        }
                }
            }
        }
        .padding(EmberSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                .fill(EmberColors.primaryPanel)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.card, style: .continuous)
                        .strokeBorder(EmberColors.divider, lineWidth: 1)
                )
        )
    }
}

private struct InsightPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: EmberSpacing.sm) {
            Text("INSIGHT")
                .emberSectionLabel()

            Text("Small, consistent days become visible. thre keeps the proof quiet and close.")
                .font(.system(size: 15, weight: .regular, design: .default))
                .foregroundStyle(EmberColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(EmberSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                .fill(EmberColors.nestedRow)
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.row, style: .continuous)
                        .strokeBorder(EmberColors.divider, lineWidth: 1)
                )
        )
    }
}

private struct EmberOnboardingHeatBackdrop: View {
    @AppStorage(EmberPreferenceKey.reducedMotionEnabled) private var reducedMotionEnabled = false

    var body: some View {
        TimelineView(.animation) { context in
            let time = reducedMotionEnabled ? 0 : context.date.timeIntervalSinceReferenceDate
            ZStack {
                EmberColors.studioBackground.ignoresSafeArea()

                RadialGradient(
                    colors: [
                        EmberColors.emberBright.opacity(0.48),
                        EmberColors.ember.opacity(0.16),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.48 + cos(time * 0.12) * 0.24,
                        y: 0.28 + sin(time * 0.10) * 0.18
                    ),
                    startRadius: 16,
                    endRadius: 380
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        EmberColors.ember.opacity(0.28),
                        EmberColors.emberGlow,
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.22 + sin(time * 0.08) * 0.18,
                        y: 0.78 + cos(time * 0.09) * 0.14
                    ),
                    startRadius: 24,
                    endRadius: 340
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [
                        EmberColors.emberBright.opacity(0.18),
                        .clear
                    ],
                    center: UnitPoint(
                        x: 0.82 + sin(time * 0.07) * 0.12,
                        y: 0.58 + cos(time * 0.06) * 0.16
                    ),
                    startRadius: 18,
                    endRadius: 260
                )
                .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        EmberColors.studioBackground.opacity(0.78),
                        EmberColors.studioBackground.opacity(0.24),
                        EmberColors.studioBackground.opacity(0.84)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
        }
        .allowsHitTesting(false)
    }
}
