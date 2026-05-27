// ReflectionScreen.swift
// Redesigned to match HomeScreen light visual language:
// warm off-white bg, large thin heading, white card editor
import SwiftUI
import SwiftData

struct ReflectionScreen: View {

    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(EmberRouter.self) private var router

    // MARK: - Queries
    @Query private var todayReflections: [Reflection]

    // MARK: - State
    @State private var reflectionText:   String = ""
    @State private var isSaved:          Bool   = false
    @FocusState private var isEditorFocused: Bool

    init() {
        let today    = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        _todayReflections = Query(
            filter: #Predicate<Reflection> { r in
                r.date >= today && r.date < tomorrow
            }
        )
    }

    // MARK: - Computed
    private var existingReflection: Reflection? { todayReflections.first }
    private var hasExisting: Bool               { existingReflection != nil }
    private var canSave: Bool {
        !reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaved
    }
    private var saveLabel: String {
        if isSaved { return "Saved" }
        return hasExisting ? "Update" : "Save"
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Background — warm off-white
            Color(hex: "EEEAE3").ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Back nav ──────────────────────────────────
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
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    // ── Heading block — mirrors HomeScreen date block ──
                    VStack(alignment: .leading, spacing: 4) {
                        Text("REFLECT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color(hex: "9A9A9A"))
                            .tracking(3)

                        Text("How did\ntoday feel?")
                            .font(.system(size: 46, weight: .thin))
                            .foregroundStyle(Color(hex: "1A1A1A"))
                            .lineSpacing(2)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // ── White card — text editor ──────────────────
                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 0) {

                            // Editor
                            ZStack(alignment: .topLeading) {
                                if reflectionText.isEmpty && !isEditorFocused {
                                    Text("Write a few words about your day...")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundStyle(Color(hex: "9A9A9A"))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 22)
                                        .allowsHitTesting(false)
                                }

                                TextEditor(text: $reflectionText)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(Color(hex: "1A1A1A"))
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .focused($isEditorFocused)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                                    .frame(minHeight: 200)
                            }

                            // Divider
                            Rectangle()
                                .fill(Color(hex: "1A1A1A").opacity(0.06))
                                .frame(height: 1)
                                .padding(.horizontal, 20)

                            // Save button row inside card
                            HStack {
                                // Character count hint
                                let wordCount = reflectionText
                                    .split { $0.isWhitespace }
                                    .count
                                Text(reflectionText.isEmpty ? "" : "\(wordCount) words")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(hex: "9A9A9A"))

                                Spacer()

                                // Save pill button
                                Button {
                                    saveReflection()
                                } label: {
                                    HStack(spacing: 6) {
                                        if isSaved {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .semibold))
                                        }
                                        Text(saveLabel)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundStyle(canSave ? Color.white : Color.white.opacity(0.50))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(canSave
                                                  ? Color(hex: "1A1A1A")
                                                  : Color(hex: "1A1A1A").opacity(0.25))
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(!canSave)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .animation(EmberAnimation.fadeIn, value: isSaved)

                    // ── Saved confirmation ────────────────────────
                    if isSaved {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "96B89A"))
                            Text("Reflection saved.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color(hex: "9A9A9A"))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .transition(.opacity)
                    }

                    Spacer().frame(height: 48)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .animation(EmberAnimation.fadeIn, value: isSaved)
        .onAppear {
            if let existing = existingReflection {
                reflectionText = existing.text
            }
        }
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

        isSaved = true
        isEditorFocused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(EmberAnimation.fadeOut) { isSaved = false }
        }
    }
}

// MARK: - Previews

#Preview("Empty") {
    NavigationStack {
        ReflectionScreen()
    }
    .environment(EmberRouter())
    .modelContainer(for: [EmberTask.self, DailyRecord.self, Reflection.self], inMemory: true)
}

#Preview("With Existing") {
    let config    = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: EmberTask.self, DailyRecord.self, Reflection.self,
        configurations: config
    )
    let ctx   = container.mainContext
    let today = Calendar.current.startOfDay(for: Date())
    let r     = Reflection(date: today, text: "Today felt focused and productive. I got the big three done early and had energy left for the afternoon.")
    ctx.insert(r)

    return NavigationStack {
        ReflectionScreen()
    }
    .environment(EmberRouter())
    .modelContainer(container)
}
