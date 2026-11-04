import SwiftUI

/// Phrase matching tolerance: capital letters, surrounding spaces, doubled
/// spaces and curly/straight apostrophes never fail a phrase — but the
/// wording itself must match in full; a partial phrase is never accepted.
enum PhraseMatcher {
    static func normalized(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{2018}", with: "'")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .lowercased()
    }

    static func isMatch(_ input: String, target: String) -> Bool {
        let target = normalized(target)
        guard !target.isEmpty else { return false }
        return normalized(input) == target
    }

    /// Per-character comparison for the live coloring (whitespace of any kind
    /// and curly apostrophes compare equal).
    static func areEquivalent(_ a: Character, _ b: Character) -> Bool {
        normalized(String(a)) == normalized(String(b)) && !normalized(String(a)).isEmpty
            || (a.isWhitespace && b.isWhitespace)
    }
}

/// Guided phrase typing: the full target phrase stays visible the whole time
/// in faint grey while the typed letters appear over it — bright when right,
/// soft red when wrong. The whole phrase matching turns it green and ends the
/// alarm; there is no Submit button to miss.
struct PhraseChallengeView: View {
    let phrase: String
    let onCorrect: () -> Void
    let onSnooze: () -> Void
    let snoozeCount: Int

    @State private var input: String = ""
    @State private var solved = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            promptSection
            inputSection
            snoozeButton
        }
        .onAppear { isFocused = true }
    }

    private var promptSection: some View {
        VStack(spacing: 8) {
            Text("Type your phrase to dismiss")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Guided typing

    private var inputSection: some View {
        VStack(spacing: 16) {
            guidedText
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 96, maxHeight: 200, alignment: .topLeading)
                .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(solved ? AppColors.success : AppColors.inputBorder, lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }

            Group {
                if solved {
                    Label("Phrase complete — well done", systemImage: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.success)
                } else {
                    Text("Capitals, extra spaces and apostrophe style don't matter.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxHeight: .infinity)
    }

    /// The faint target with typed letters drawn over it and a blinking blue
    /// caret. The invisible TextField on top supplies the keyboard; the
    /// visible text is entirely ours, so the guide never disappears.
    private var guidedText: some View {
        ZStack(alignment: .topLeading) {
            guideText
            TextField("Phrase", text: $input, axis: .vertical)
                .font(.title2.weight(.medium).monospaced())
                .lineSpacing(6)
                .foregroundColor(.clear)
                .tint(.clear)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
        .onChange(of: input) { _, newValue in
            handleInput(newValue)
        }
    }

    private var guideText: some View {
        TimelineView(.periodic(from: .now, by: 0.55)) { context in
            let caretOn = Int(context.date.timeIntervalSinceReferenceDate / 0.55) % 2 == 0
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    Text(guideAttributedString(caretOn: caretOn))
                        .font(.title2.weight(.medium).monospaced())
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .id("phraseGuide")
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Target phrase: \(phrase)")
                        .accessibilityValue(solved ? "Complete" : "\(input.count) of \(phrase.count) characters typed")
                }
                .scrollIndicators(.hidden)
                .onChange(of: input) { _, _ in
                    proxy.scrollTo("phraseGuide", anchor: .bottom)
                }
            }
        }
    }

    private func guideAttributedString(caretOn: Bool) -> AttributedString {
        let targetChars = Array(phrase)
        let inputChars = Array(input)
        let typedCount = min(inputChars.count, targetChars.count)

        var result = AttributedString()
        func appendCaret() {
            var caret = AttributedString("▍")
            caret.foregroundColor = AppColors.primary.opacity(caretOn ? 1 : 0.2)
            result += caret
        }

        for (index, targetChar) in targetChars.enumerated() {
            if index == typedCount { appendCaret() }
            var chunk = AttributedString(String(targetChar))
            if index < typedCount {
                chunk.foregroundColor = PhraseMatcher.areEquivalent(inputChars[index], targetChar)
                    ? AppColors.text
                    : AppColors.error.opacity(0.9)
            } else {
                chunk.foregroundColor = AppColors.inactive.opacity(0.55)
            }
            result += chunk
        }
        if typedCount >= targetChars.count && !targetChars.isEmpty { appendCaret() }
        if targetChars.isEmpty {
            var caret = AttributedString("▍")
            caret.foregroundColor = AppColors.primary.opacity(caretOn ? 1 : 0.2)
            result += caret
        }
        return result
    }

    private func handleInput(_ newValue: String) {
        guard !solved else { return }
        // Never let the input run past the target.
        var value = newValue
        if value.count > phrase.count {
            value = String(value.prefix(phrase.count))
            input = value
        }
        if PhraseMatcher.isMatch(value, target: phrase) {
            solved = true
            isFocused = false
            HapticManager.successNotification()
            onCorrect()
        }
    }

    // MARK: - Start Over

    private var snoozeButton: some View {
        Button(action: resetInput) {
            Text("Start Over (\(snoozeCount))")
                .font(.body.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppColors.error, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppColors.error.opacity(0.3), radius: 12, y: 6)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 32)
        .disabled(solved)
    }

    private func resetInput() {
        input = ""
        solved = false
        isFocused = true
        onSnooze()
    }
}

#Preview {
    PhraseChallengeView(
        phrase: "I'm getting up to make today count",
        onCorrect: {},
        onSnooze: {},
        snoozeCount: 0
    )
    .preferredColorScheme(.dark)
}
