import AVFoundation
import MediaPlayer
import SwiftUI

/// Holds the device's media volume at maximum while the wake-up challenge is
/// on screen. Pressing the volume buttons is detected through the audio
/// session's `outputVolume` and immediately snapped back to max. The user's
/// previous volume is restored once the challenge is solved.
///
/// iOS only exposes volume control through `MPVolumeView`'s slider, so a
/// hidden `SystemVolumeLockHost` must be in the view hierarchy (it also keeps
/// the system volume HUD from flashing on every snap-back).
final class SystemVolumeLock {
    static let shared = SystemVolumeLock()

    private weak var volumeView: MPVolumeView?
    private var observation: NSKeyValueObservation?
    private var savedVolume: Float?
    private(set) var isEngaged: Bool = false

    private init() {}

    func attach(_ view: MPVolumeView) {
        volumeView = view
        if isEngaged { setVolume(1.0) }
    }

    /// Pushes volume to max and starts snapping it back on every change.
    func engage() {
        let session = AVAudioSession.sharedInstance()
        if !isEngaged {
            savedVolume = session.outputVolume
        }
        isEngaged = true
        setVolume(1.0)
        observation?.invalidate()
        observation = session.observe(\.outputVolume, options: [.new]) { _, change in
            guard let value = change.newValue, value < 0.999 else { return }
            Task { @MainActor in
                SystemVolumeLock.shared.snapBack()
            }
        }
    }

    /// Stops enforcing and (optionally) restores the pre-alarm volume.
    func disengage(restoreVolume: Bool = true) {
        guard isEngaged else { return }
        isEngaged = false
        observation?.invalidate()
        observation = nil
        if restoreVolume, let saved = savedVolume {
            setVolume(saved)
        }
        savedVolume = nil
    }

    private func snapBack() {
        guard isEngaged else { return }
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
