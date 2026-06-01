// ReflectionScreen.swift
// Dark studio reflection surface.
import SwiftUI
import SwiftData

struct ReflectionScreen: View {

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router

    // MARK: - Queries
    @Query private var todayReflections: [Reflection]

    // MARK: - State
    @State private var reflectionText = ""
    @State private var isSaved = false
    @State private var saveSymbolTrigger = false
    @FocusState private var isEditorFocused: Bool

    // MARK: - Studio tokens
    private var background: Color { EmberColors.studioBackground }
    private let panel = EmberColors.primaryPanel
    private let row = EmberColors.nestedRow
    private let raised = EmberColors.raisedElement
    private let textPrimary = EmberColors.textPrimary
    private let textSecondary = EmberColors.textSecondary
    private let textTertiary = EmberColors.textTertiary
    private let hairline = EmberColors.divider
    private var ember: Color { EmberColors.ember }
    private let prompts = ReflectionPrompts.shared

    init() {
        let today = DateService.shared.today
        let tomorrow = DateService.shared.calendar.date(byAdding: .day, value: 1, to: today)!
        var descriptor = FetchDescriptor<Reflection>(
            predicate: #Predicate<Reflection> { reflection in
                reflection.date >= today && reflection.date < tomorrow
            }
        )
        descriptor.fetchLimit = 1
        _todayReflections = Query(descriptor)
    }

    // MARK: - Computed
    private var existingReflection: Reflection? { todayReflections.first }
    private var hasExisting: Bool { existingReflection != nil }
    private var wordCount: Int { reflectionText.split { $0.isWhitespace }.count }

    private var canSave: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaved
    }

    private var saveLabel: String {
        if isSaved { return "Saved" }
        return hasExisting ? "Update" : "Save"
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                    promptPanel
                    editorPanel

                    if isSaved {
                        savedNotice
                    }
                }
                .padding(.horizontal, EmberSpacing.screenHorizontal)
                .padding(.top, 14)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(EmberAnimation.fadeIn, value: isSaved)
        .onAppear {
            if let existing = existingReflection {
                reflectionText = existing.text
            }
        }
    }

    // MARK: - Layout
    private var topBar: some View {
        HStack {
            Button {
                router.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(textPrimary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(raised))
                    .overlay(Circle().strokeBorder(hairline, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .accessibilityIdentifier("reflection.back")

            Spacer()

            Text("REFLECT")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(textSecondary)

            Spacer()

            Button {
                saveReflection()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: isSaved ? "checkmark" : "square.and.pencil")
                        .font(.system(size: 13, weight: .bold))
                        .completeBounce(saveSymbolTrigger)
                        .replaceCheck(isSaved)

                    Text(saveLabel.uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .tracking(0.8)
                }
                .foregroundStyle(canSave ? background : textSecondary)
                .frame(width: 96, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .fill(canSave ? ember : raised)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: EmberCornerRadii.button, style: .continuous)
                        .strokeBorder(canSave ? Color.clear : hairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
            .accessibilityLabel(saveLabel)
            .accessibilityIdentifier("reflection.topSave")
            .accessibilityValue(isSaved ? "saved" : "unsaved")
        }
    }

    private var promptPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CLOSE THE DAY")
                .emberSectionLabel()

            Text(prompts.prompt(for: DateService.shared.today))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(textPrimary)
                .lineLimit(4)
        }
        .padding(20)
        .background(studioPanel)
    }

    private var editorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                if reflectionText.isEmpty && !isEditorFocused {
                    Text("A few plain words are enough.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $reflectionText)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isEditorFocused)
                    .tint(ember)
                    .frame(minHeight: 230)
                    .accessibilityLabel("Reflection text")
                    .accessibilityIdentifier("reflection.text")
            }
            .padding(16)

            Rectangle()
                .fill(hairline)
                .frame(height: 1)

            HStack {
                Text(reflectionText.isEmpty ? "" : "\(wordCount) words")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(textSecondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(studioPanel)
    }

    private var savedNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(textSecondary)
                .replaceCheck(isSaved)
            Text("Reflection saved.")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(textSecondary)
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
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

    // MARK: - Save action
    private func saveReflection() {
        let trimmed = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existing = existingReflection {
            existing.text = trimmed
        } else {
            let reflection = Reflection(date: DateService.shared.today, text: trimmed)
            modelContext.insert(reflection)
        }

        do { try modelContext.save() }
        catch { EmberLogger.records.error("reflection save failed", error) }

        isSaved = true
        saveSymbolTrigger.toggle()
        isEditorFocused = false

        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(EmberAnimation.fadeOut) { isSaved = false }
        }
    }
}
