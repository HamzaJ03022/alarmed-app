import SwiftUI

// MARK: - Tokens

/// 4/8-point spacing scale.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

/// One radius per shape family.
enum Radius {
    static let card: CGFloat = 20
    static let control: CGFloat = 14
    static let tile: CGFloat = 8
}

/// Type scale. Everything maps to a Dynamic Type style so it scales.
enum AppFont {
    static let sectionLabel = Font.footnote.weight(.semibold)
    static let rowTitle = Font.body
    static let rowTitleEmphasis = Font.body.weight(.semibold)
    static let rowDetail = Font.subheadline
    static let caption = Font.footnote
    static let tag = Font.caption.weight(.semibold)
    static let button = Font.body.weight(.semibold)

    /// Light rounded numerals for clock times.
    static func clock(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .rounded)
    }
}

// MARK: - Layout primitives

/// Small-caps label that introduces a group.
struct SectionHeader: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(AppFont.sectionLabel)
                .textCase(.uppercase)
                .tracking(0.7)
                .foregroundStyle(AppColors.textSecondary)
            if let detail {
                Text(detail)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColors.inactive)
            }
        }
        .padding(.horizontal, Spacing.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Charcoal grouped surface. Rows inside are separated by `RowDivider`.
struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

/// Hairline between rows, inset to align with row text.
struct RowDivider: View {
    var leadingInset: CGFloat = Spacing.md

    var body: some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 1)
            .padding(.leading, leadingInset)
    }
}

/// Rounded-square icon used at the start of settings rows.
struct IconTile: View {
    let systemName: String
    var tint: Color = AppColors.primary

    var body: some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: 30, height: 30)
            .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: Radius.tile, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Rows

/// Shared row anatomy: optional icon, title + subtitle, trailing accessory.
struct RowContent<Trailing: View>: View {
    var icon: String? = nil
    var iconTint: Color = AppColors.primary
    let title: String
    var subtitle: String? = nil
    var titleColor: Color = AppColors.text
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon {
                IconTile(systemName: icon, tint: iconTint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.rowTitle)
                    .foregroundStyle(titleColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.rowDetail)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }
}

/// Opens another screen — always ends in a chevron.
struct NavigationRow: View {
    var icon: String? = nil
    var iconTint: Color = AppColors.primary
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RowContent(icon: icon, iconTint: iconTint, title: title, subtitle: subtitle) {
                HStack(spacing: Spacing.xs) {
                    if let value {
                        Text(value)
                            .font(AppFont.rowDetail)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    Chevron()
                }
            }
        }
        .buttonStyle(RowButtonStyle())
    }
}

/// Performs an action in place (no chevron) — trailing glyph shows the action.
struct ActionRow: View {
    var icon: String? = nil
    var iconTint: Color = AppColors.primary
    let title: String
    var subtitle: String? = nil
    var role: ButtonRole? = nil
    var trailingSystemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            RowContent(
                icon: icon,
                iconTint: role == .destructive ? AppColors.error : iconTint,
                title: title,
                subtitle: subtitle,
                titleColor: role == .destructive ? AppColors.error : AppColors.text
            ) {
                if let trailingSystemImage {
                    Image(systemName: trailingSystemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(role == .destructive ? AppColors.error : AppColors.primary)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(RowButtonStyle())
    }
}

/// A row whose only affordance is its switch.
struct ToggleRow: View {
    var icon: String? = nil
    var iconTint: Color = AppColors.primary
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool

    var body: some View {
        RowContent(icon: icon, iconTint: iconTint, title: title, subtitle: subtitle) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.primary)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Read-only information row.
struct InfoRow: View {
    var icon: String? = nil
    var iconTint: Color = AppColors.primary
    let title: String
    var subtitle: String? = nil

    var body: some View {
        RowContent(icon: icon, iconTint: iconTint, title: title, subtitle: subtitle) { EmptyView() }
            .accessibilityElement(children: .combine)
    }
}

struct Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(AppColors.inactive)
            .accessibilityHidden(true)
    }
}

// MARK: - Button styles

/// Row highlight on press.
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? AppColors.surfacePressed : Color.clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Soft scale-down press feedback for cards and tiles.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Full-width filled accent button.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button)
            .foregroundStyle(isEnabled ? AppColors.text : AppColors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, Spacing.md)
            .background(
                isEnabled ? AppColors.primary : AppColors.surfaceElevated,
                in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

/// Quiet tinted button for secondary actions.
struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = AppColors.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.button)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, Spacing.md)
            .background(tint.opacity(configuration.isPressed ? 0.24 : 0.14),
                        in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Controls

/// Status capsule with a leading dot.
struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(AppFont.tag)
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
    }
}

/// Selectable pill.
struct ChipButton: View {
    let title: String
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(isSelected ? AppColors.text : AppColors.textSecondary)
            .padding(.horizontal, 14)
            .frame(minHeight: 36)
            .background(isSelected ? AppColors.primary : AppColors.surfaceElevated, in: Capsule())
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.95))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLocked ? "At least one topic must stay selected" : "")
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// Custom segmented control with a sliding accent thumb.
struct SegmentedPicker: View {
    let options: [(id: String, label: String)]
    @Binding var selection: String
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.id) { option in
                let isSelected = option.id == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option.id
                    }
                } label: {
                    Text(option.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? AppColors.text : AppColors.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(AppColors.primary)
                                    .matchedGeometryEffect(id: "thumb", in: thumb)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(AppColors.surfaceElevated, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Minus / value / plus stepper.
struct QuantityStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var unitLabel: (Int) -> String = { "\($0)" }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            stepButton("minus", enabled: value > range.lowerBound) {
                value = max(range.lowerBound, value - 1)
            }
            .accessibilityLabel("Fewer")

            Text("\(value)")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(AppColors.text)
                .frame(minWidth: 32)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.snappy, value: value)

            stepButton("plus", enabled: value < range.upperBound) {
                value = min(range.upperBound, value + 1)
            }
            .accessibilityLabel("More")
        }
        .sensoryFeedback(.selection, trigger: value)
        .accessibilityElement(children: .contain)
        .accessibilityValue(unitLabel(value))
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.bold))
                .foregroundStyle(enabled ? AppColors.text : AppColors.inactive)
                .frame(width: 44, height: 44)
                .background(AppColors.surfaceElevated, in: Circle())
        }
        .buttonStyle(PressableStyle(scale: 0.9))
        .disabled(!enabled)
    }
}

/// Seven tappable day circles, Monday first. Empty selection = one-time.
struct DaySelector: View {
    @Binding var selection: [String]

    static let days: [(key: String, short: String, name: String)] = [
        ("mon", "M", "Monday"), ("tue", "T", "Tuesday"), ("wed", "W", "Wednesday"),
        ("thu", "T", "Thursday"), ("fri", "F", "Friday"), ("sat", "S", "Saturday"),
        ("sun", "S", "Sunday")
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Self.days, id: \.key) { day in
                let isOn = selection.contains(day.key)
                Button {
                    if isOn {
                        selection.removeAll { $0 == day.key }
                    } else {
                        selection.append(day.key)
                    }
                } label: {
                    Text(day.short)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOn ? AppColors.text : AppColors.textSecondary)
                        .frame(maxWidth: 44, minHeight: 44)
                        .aspectRatio(1, contentMode: .fit)
                        .background(isOn ? AppColors.primary : AppColors.surfaceElevated, in: Circle())
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel(day.name)
                .accessibilityValue(isOn ? "Repeats" : "Off")
                .accessibilityAddTraits(isOn ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

/// Big tappable choice tile with icon, title, description and check.
struct SelectionTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(isSelected ? AppColors.text : AppColors.primary)
                        .frame(width: 40, height: 40)
                        .background(
                            isSelected ? AppColors.primary : AppColors.primarySoft,
                            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                        )
                    Spacer(minLength: 0)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? AppColors.primary : AppColors.inactive)
                        .contentTransition(.symbolEffect(.replace))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColors.text)
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? AppColors.primary : Color.clear, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Feedback

/// Success toast capsule.
struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
            Text(message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.text)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(AppColors.surfaceElevated, in: Capsule())
        .overlay(Capsule().strokeBorder(AppColors.border, lineWidth: 1))
        .padding(.horizontal, Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Inline red validation message.
struct InlineErrorText: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.circle.fill")
            .font(AppFont.caption.weight(.medium))
            .foregroundStyle(AppColors.error)
    }
}

/// Amber warning strip for problems that must not be hidden.
struct WarningStrip: View {
    let message: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppColors.warning)
                Text(message)
                    .font(AppFont.rowDetail.weight(.medium))
                    .foregroundStyle(AppColors.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                if action != nil { Chevron() }
            }
            .padding(Spacing.md)
            .background(AppColors.warningBackground, in: RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
        }
        .buttonStyle(PressableStyle(scale: 0.98))
        .disabled(action == nil)
    }
}

// MARK: - Time helpers

enum ClockParts {
    /// "07:30" → ("7:30", "AM")
    static func split(_ time: String) -> (main: String, suffix: String) {
        let formatted = TimeFormatter.formatTime12h(time)
        let parts = formatted.split(separator: " ", omittingEmptySubsequences: false)
        return (parts.first.map(String.init) ?? formatted, parts.count > 1 ? String(parts[1]) : "")
    }

    /// Compact countdown: "7h 20m", "45m", "<1m", "2d 3h".
    static func countdown(to date: Date, from now: Date = Date()) -> String {
        let totalMinutes = max(0, Int(ceil(date.timeIntervalSince(now) / 60)))
        if totalMinutes < 1 { return "<1m" }
        let days = totalMinutes / 1440
        let hours = (totalMinutes % 1440) / 60
        let minutes = totalMinutes % 60
        if days > 0 { return hours > 0 ? "\(days)d \(hours)h" : "\(days)d" }
        if hours > 0 { return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h" }
        return "\(minutes)m"
    }

    /// Spoken countdown for VoiceOver.
    static func spokenCountdown(to date: Date, from now: Date = Date()) -> String {
        let totalMinutes = max(0, Int(ceil(date.timeIntervalSince(now) / 60)))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) \(hours == 1 ? "hour" : "hours")") }
        if minutes > 0 || hours == 0 { parts.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")") }
        return parts.joined(separator: " ")
    }

    /// "Today", "Tomorrow" or weekday name.
    static func dayDescription(for date: Date, now: Date = Date()) -> String {
        let cal = Calendar.current
        if cal.isDate(date, inSameDayAs: now) { return "Today" }
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: now), cal.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return date.formatted(.dateTime.weekday(.wide))
    }
}
