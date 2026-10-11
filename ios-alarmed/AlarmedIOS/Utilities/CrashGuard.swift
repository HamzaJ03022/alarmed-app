import Foundation

/// Lightweight crash breadcrumbs. Risky stages write a marker before they run
/// and clear it when they finish; a marker still present at the next launch
/// means the app died during that stage. This turns a crash loop into a
/// self-healing one (the volume lock disables itself) and shows exactly
/// where the crash happened on the Settings diagnostics card.
enum CrashGuard {
    enum Stage: String {
        case launch = "app launch"
        case volumeLock = "challenge screen (volume lock)"
        case challenge = "challenge screen"
    }

    private static let stageKey = "alarmed_crash_stage"
    private static let lastExitKey = "alarmed_last_unexpected_exit"
    private static let volumeLockDisabledKey = "alarmed_volume_lock_disabled"
    private static var defaults: UserDefaults { .standard }

    /// Call once, first thing at launch, before any stage begins.
    static func inspectPreviousSession() {
        guard let raw = defaults.string(forKey: stageKey) else { return }
        defaults.removeObject(forKey: stageKey)
        defaults.set(raw, forKey: lastExitKey)
        if raw == Stage.volumeLock.rawValue {
            defaults.set(true, forKey: volumeLockDisabledKey)
        }
    }

    static func begin(_ stage: Stage) {
        defaults.set(stage.rawValue, forKey: stageKey)
    }

    /// Clears the marker only if it still belongs to `stage`.
    static func end(_ stage: Stage) {
        guard defaults.string(forKey: stageKey) == stage.rawValue else { return }
        defaults.removeObject(forKey: stageKey)
    }

    static var isVolumeLockDisabled: Bool {
        defaults.bool(forKey: volumeLockDisabledKey)
    }

    /// Lines for the Settings diagnostics card.
    static var diagnosticLines: [String] {
        var lines: [String] = []
        if let stage = defaults.string(forKey: lastExitKey) {
            lines.append("Last unexpected exit: during \(stage)")
        } else {
            lines.append("Last unexpected exit: none recorded")
        }
        if isVolumeLockDisabled {
            lines.append("Volume lock: paused automatically after a crash (alarm still plays at full volume)")
        }
        return lines
    }
}
