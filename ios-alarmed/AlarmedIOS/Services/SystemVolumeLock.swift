import AVFoundation
import MediaPlayer
import SwiftUI

/// Holds the device's media volume at maximum while the wake-up challenge is
/// on screen. Pressing the volume buttons is detected through the audio
/// session's `outputVolume` and immediately snapped back to max. The user's
/// previous volume is restored once the challenge is solved.
///
/// iOS only exposes volume control through `MPVolumeView`'s slider, so a
/// hidden `SystemVolumeLockHost` must be in the view hierarchy.
final class SystemVolumeLock {
    static let shared = SystemVolumeLock()

    private weak var volumeView: MPVolumeView?
    private var observer: VolumeChangeObserver?
    private var savedVolume: Float?
    private var recentSnaps: [Date] = []
    private(set) var isEngaged: Bool = false

    private init() {}

    func attach(_ view: MPVolumeView) {
        volumeView = view
        if isEngaged { setVolume(1.0) }
    }

    /// Pushes volume to max and starts snapping it back on every change.
    /// Skipped automatically if a previous challenge session ended in a crash
    /// while the lock was active, so the challenge itself always stays usable.
    func engage() {
        guard !CrashGuard.isVolumeLockDisabled else { return }
        CrashGuard.begin(.volumeLock)
        let session = AVAudioSession.sharedInstance()
        if !isEngaged {
            savedVolume = session.outputVolume
            recentSnaps = []
        }
        isEngaged = true
        setVolume(1.0)
        if observer == nil {
            // KVO for outputVolume is delivered on a background thread, so the
            // observer is nonisolated and hops to the main actor explicitly.
            let newObserver = VolumeChangeObserver {
                Task { @MainActor in
                    SystemVolumeLock.shared.snapBack()
                }
            }
            newObserver.start()
            observer = newObserver
        }
    }

    /// Stops enforcing and (optionally) restores the pre-alarm volume.
    func disengage(restoreVolume: Bool = true) {
        CrashGuard.end(.volumeLock)
        guard isEngaged else { return }
        isEngaged = false
        observer?.stop()
        observer = nil
        if restoreVolume, let saved = savedVolume {
            setVolume(saved)
        }
        savedVolume = nil
    }

    /// Called when the app leaves the foreground mid-challenge: the lock is
    /// paused (not restored) and re-engaged when the challenge resumes.
    func pause() {
        CrashGuard.end(.volumeLock)
        observer?.stop()
        observer = nil
    }

    private func snapBack() {
        guard isEngaged else { return }
        // If the system caps the volume below max (e.g. headphone safety
        // limits), stop fighting it instead of looping forever.
        let now = Date()
        recentSnaps = recentSnaps.filter { now.timeIntervalSince($0) < 3 } + [now]
        guard recentSnaps.count <= 12 else { return }
        setVolume(1.0)
    }

    /// MPVolumeView builds its slider lazily, so retry briefly until it exists.
    private func setVolume(_ value: Float, attempt: Int = 0) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(attempt == 0 ? 30 : 150))
            guard let slider = self.volumeView?.subviews.compactMap({ $0 as? UISlider }).first else {
                if attempt < 8 { self.setVolume(value, attempt: attempt + 1) }
                return
            }
            slider.setValue(value, animated: false)
            slider.sendActions(for: .valueChanged)
        }
    }
}

/// Thread-safe KVO observer for `AVAudioSession.outputVolume`. Deliberately
/// nonisolated: iOS calls `observeValue` on an arbitrary background thread,
/// and a main-actor-isolated callback would trip the runtime isolation check.
nonisolated final class VolumeChangeObserver: NSObject, @unchecked Sendable {
    private let onVolumeDropped: @Sendable () -> Void
    private var isObserving = false

    init(onVolumeDropped: @escaping @Sendable () -> Void) {
        self.onVolumeDropped = onVolumeDropped
        super.init()
    }

    func start() {
        guard !isObserving else { return }
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.new], context: nil)
        isObserving = true
    }

    func stop() {
        guard isObserving else { return }
        AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        isObserving = false
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "outputVolume",
              let value = (change?[.newKey] as? NSNumber)?.floatValue,
              value < 0.999 else { return }
        onVolumeDropped()
    }
}

/// Invisible MPVolumeView that gives `SystemVolumeLock` access to the device
/// volume. Place it once on the challenge screen.
struct SystemVolumeLockHost: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        view.alpha = 0.01
        view.isUserInteractionEnabled = false
        SystemVolumeLock.shared.attach(view)
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        SystemVolumeLock.shared.attach(uiView)
    }
}
