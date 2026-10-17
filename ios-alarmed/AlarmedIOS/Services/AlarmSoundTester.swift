import AVFoundation
import Foundation

/// Plays the bundled alarm tone through the speaker so the sound can be
/// verified on the device independently of the alarm engine. One instance
/// owns one player; starting a new test stops the previous one.
final class AlarmSoundTester {
    private var player: AVAudioPlayer?

    /// The loudness-maximized classic tone used by the Settings test and as
    /// the global fallback.
    static let toneURL: URL? = Bundle.main.url(forResource: "alarm_loud", withExtension: "caf")

    /// Whether the alarm tone actually shipped in this build's resources.
    static let isToneBundled: Bool = toneURL != nil

    /// Plays the bundled loud tone. Returns a user-readable status line for
    /// the Settings card.
    func playTestSound() -> String {
        guard let url = Self.toneURL else {
            return "Test sound failed — alarm_loud.caf is not bundled in this build."
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = 0
            newPlayer.volume = 1.0
            newPlayer.play()
            player = newPlayer
            return "Playing the alarm tone now. The lock-screen alarm plays at your \"Ringtone & Alerts\" volume — set it to max using the tip above."
        } catch {
            return "Test sound failed — \(error.localizedDescription)"
        }
    }

    /// Plays a short preview of any catalog tone (sound picker). Falls back
    /// to a user-readable error when the tone is missing from the bundle.
    func playPreview(of tone: AlarmSound) -> String {
        guard let url = Bundle.main.url(forResource: tone.baseName, withExtension: "caf") else {
            return "Preview failed — \(tone.fileName) is not bundled in this build."
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = 1
            newPlayer.volume = 1.0
            newPlayer.play()
            player = newPlayer
            return "Previewing \(tone.name)."
        } catch {
            return "Preview failed — \(error.localizedDescription)"
        }
    }

    /// Stops playback and releases the audio session.
    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
