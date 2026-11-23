import SwiftUI
import UIKit

/// Phrase matching tolerance: capital letters, surrounding spaces, doubled
/// spaces and curly/straight quote style never fail a phrase — but the
/// wording and punctuation must match in full; a partial phrase is never
/// accepted.
enum PhraseMatcher {
    /// Maps one character to its forgiving form (lowercase, straight quotes).
    private static func fold(_ c: Character) -> Character {
        switch c {
        case "\u{2019}", "\u{2018}", "\u{02BC}", "\u{2032}": return "'"
        case "\u{201C}", "\u{201D}", "\u{2033}": return "\""
        default:
            let lower = String(c).lowercased()
            return lower.count == 1 ? Character(lower) : c
        }
    }

    static func normalized(_ text: String) -> String {
        String(folded(text, keepTrailingSpace: false).map(\.char))
    }

    static func isMatch(_ input: String, target: String) -> Bool {
        let target = normalized(target)
        guard !target.isEmpty else { return false }
        return normalized(input) == target
    }

    /// Folded characters with whitespace runs collapsed to one space and
    /// leading whitespace dropped. Each keeps the index of the character in
    /// the original string it came from, so the guide can color the
    /// original phrase. `keepTrailingSpace` keeps one trailing space so a
    /// just-typed space still moves the caret.
    static func folded(_ text: String, keepTrailingSpace: Bool) -> [(char: Character, source: Int)] {
        var out: [(char: Character, source: Int)] = []
        var pendingSpace: Int?
        for (index, c) in text.enumerated() {
            if c.isWhitespace || c.isNewline {
                if !out.isEmpty && pendingSpace == nil { pendingSpace = index }
                continue
            }
            if let space = pendingSpace {
                out.append((" ", space))
                pendingSpace = nil
            }
            out.append((fold(c), index))
        }
        if keepTrailingSpace, let space = pendingSpace {
            out.append((" ", space))
        }
        return out
    }
}

/// Guided phrase typing: the full target phrase stays visible the whole time
/// in faint grey while the typed letters light it up. Anything typed after
/// the first mistake shows as red marks at that spot (one backspace per
/// mark fixes it), so a single slip never turns the whole phrase red. The
/// whole phrase matching turns it green and ends the alarm; there is no
/// Submit button to miss.
struct PhraseChallengeView: View {
    let phrase: String
    let onCorrect: () -> Void
    let onSnooze: () -> Void
    let snoozeCount: Int

    @State private var input: String = ""
    @State private var solved = false
    @State private var isFocused = false

    var body: some View {
        VStack(spacing: 0) {
            promptSection
            inputSection
        }
        // The button lives in the bottom safe-area inset so it always sits
        // ABOVE the keyboard instead of sliding behind it.
        .safeAreaInset(edge: .bottom) {
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

    private var progress: GuideProgress {
        GuideProgress(phrase: phrase, input: input)
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            guidedText
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 96, maxHeight: 200, alignment: .topLeading)
                .background(AppColors.inputBackground, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .contentShape(Rectangle())
                .onTapGesture { isFocused = true }

            Group {
                if solved {
                    Label("Phrase complete — well done", systemImage: "checkmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppColors.success)
                } else if progress.wrongCount > 0 {
                    Label(
                        progress.wrongCount == 1
                            ? "Tap delete once to fix the red mark."
                            : "Tap delete \(progress.wrongCount) times to fix the red marks.",
                        systemImage: "delete.left"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.error)
                } else {
                    Text("Capitals, extra spaces and apostrophe style don't matter.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .animation(.easeInOut(duration: 0.2), value: progress.wrongCount > 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .frame(maxHeight: .infinity)
    }

    private var borderColor: Color {
        if solved { return AppColors.success }
        if progress.wrongCount > 0 { return AppColors.error.opacity(0.7) }
        return AppColors.inputBorder
    }

    /// The faint target with typed letters drawn over it and a blinking blue
    /// caret. The invisible keyboard field underneath supplies the keyboard;
    /// the visible text is entirely ours, so the guide never disappears.
    private var guidedText: some View {
        ZStack(alignment: .topLeading) {
            PlainKeyboardField(text: $input, isFocused: $isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            guideText
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
                        .accessibilityValue(accessibilityProgress)
                }
                .scrollIndicators(.hidden)
                .onChange(of: input) { _, _ in
                    proxy.scrollTo("phraseGuide", anchor: .bottom)
                }
            }
        }
    }

    private var accessibilityProgress: String {
        if solved { return "Complete" }
        let p = progress
        if p.wrongCount > 0 { return "\(p.wrongCount) wrong characters to delete" }
        return "\(p.correctCount) of \(p.targetCount) characters typed"
    }

    private func guideAttributedString(caretOn: Bool) -> AttributedString {
        let p = progress
        let phraseChars = Array(phrase)
        var result = AttributedString()

        func appendCaret() {
            var caret = AttributedString("▍")
            caret.foregroundColor = AppColors.primary.opacity(caretOn ? 1 : 0.2)
            result += caret
        }

        // Original-phrase index where the caret (and any red marks) go.
        let splitSource = p.correctCount < p.target.count ? p.target[p.correctCount].source : phraseChars.count

        for (index, char) in phraseChars.enumerated() {
            if index == splitSource {
                appendWrong(p.wrongChars, to: &result)
                appendCaret()
            }
            var chunk = AttributedString(String(char))
            chunk.foregroundColor = index < splitSource
                ? AppColors.text
                : AppColors.inactive.opacity(0.55)
            result += chunk
        }
        if splitSource >= phraseChars.count {
            appendWrong(p.wrongChars, to: &result)
            appendCaret()
        }
        return result
    }

    /// Typed characters that don't fit the phrase, drawn in red at the spot
    /// they were typed. Spaces get a visible mark so they can be spotted.
    private func appendWrong(_ chars: [Character], to result: inout AttributedString) {
        for char in chars {
            var mark = AttributedString(char == " " ? "·" : String(char))
            mark.foregroundColor = AppColors.error
            mark.backgroundColor = AppColors.error.opacity(0.18)
            result += mark
        }
    }

    private func handleInput(_ newValue: String) {
        guard !solved else { return }
        if PhraseMatcher.isMatch(newValue, target: phrase) {
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
        .padding(.vertical, 8)
        .disabled(solved)
    }

    private func resetInput() {
        input = ""
        solved = false
        isFocused = true
        onSnooze()
    }
}

/// How far the typed text matches the phrase, in forgiving (folded) form.
private struct GuideProgress {
    let target: [(char: Character, source: Int)]
    /// Folded characters matching the phrase from the start.
    let correctCount: Int
    /// Typed characters after the first mismatch (or beyond the phrase end).
    let wrongChars: [Character]

    var targetCount: Int { target.count }
    var wrongCount: Int { wrongChars.count }

    init(phrase: String, input: String) {
        let target = PhraseMatcher.folded(phrase, keepTrailingSpace: false)
        let typed = PhraseMatcher.folded(input, keepTrailingSpace: true)
        var correct = 0
        while correct < typed.count, correct < target.count, typed[correct].char == target[correct].char {
            correct += 1
        }
        // Show what was really typed (not the folded form) for the red marks.
        let inputChars = Array(input)
        let wrong: [Character] = typed.dropFirst(correct).map { item in
            item.char == " " ? " " : inputChars[item.source]
        }
        self.target = target
        self.correctCount = correct
        self.wrongChars = wrong
    }
}

/// A single-line UIKit text field with every "helpful" keyboard rewrite
/// switched off — smart quotes and dashes, smart spacing, spell check,
/// autocorrect, predictions and the double-space full stop — so the text
/// that reaches the matcher is exactly what was typed. Return is ignored.
private struct PlainKeyboardField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.smartQuotesType = .no
        field.smartDashesType = .no
        field.smartInsertDeleteType = .no
        field.inlinePredictionType = .no
        field.keyboardType = .default
        field.returnKeyType = .default
        field.textContentType = nil
        field.textColor = .clear
        field.tintColor = .clear
        field.backgroundColor = .clear
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        if field.text != text { field.text = text }
        if isFocused && !field.isFirstResponder {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        } else if !isFocused && field.isFirstResponder {
            DispatchQueue.main.async { field.resignFirstResponder() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PlainKeyboardField

        init(_ parent: PlainKeyboardField) { self.parent = parent }

        @objc func editingChanged(_ field: UITextField) {
            let value = (field.text ?? "").replacingOccurrences(of: "\n", with: "")
            if parent.text != value { parent.text = value }
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {
            // Return / pasted newlines never enter the phrase.
            if string.contains(where: \.isNewline) {
                let cleaned = string.filter { !$0.isNewline }
                if !cleaned.isEmpty, let current = textField.text,
                   let swiftRange = Range(range, in: current) {
                    textField.text = current.replacingCharacters(in: swiftRange, with: cleaned)
                    editingChanged(textField)
                }
                return false
            }
            // The keyboard's double-space shortcut swaps the previous space
            // for ". " — keep the single space instead of a surprise full stop.
            if string == ". ", range.length == 1,
               let current = textField.text,
               let swiftRange = Range(range, in: current),
               current[swiftRange] == " " {
                return false
            }
            return true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool { false }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFocused { parent.isFocused = true }
        }

        /// Keeps the binding honest when the system hides the keyboard, so
        /// tapping the phrase box brings it straight back.
        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFocused { parent.isFocused = false }
        }
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
