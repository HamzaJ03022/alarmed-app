import AVFoundation
import Foundation

/// Plays the bundled alarm tone through the speaker so the sound can be
/// verified on the device independently of the alarm engine. One instance
/// owns one player; starting a new test stops the previous one.
final class AlarmSoundTester {
    private var player: AVAudioPlayer?

    /// The loudness-maximized tone used by the lock-screen alarm, the
    /// in-app challenge and the notification fallback.
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

    /// Stops playback and releases the audio session.
    func stop() {
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
