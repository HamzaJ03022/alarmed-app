import AVFoundation
import Foundation

/// Plays the bundled alarm tone through the speaker so the sound can be
/// verified on the device independently of the alarm engine. One instance
/// owns one player; starting a new test stops the previous one.
final class AlarmSoundTester {
    private var player: AVAudioPlayer?

    /// Whether the alarm tone actually shipped in this build's resources.
    static let isToneBundled: Bool = {
        Bundle.main.url(forResource: "alarm", withExtension: "caf") != nil
    }()

    /// Plays the bundled alarm.caf. Returns a user-readable status line for
    /// the Settings card.
    func playTestSound() -> String {
        guard Self.isToneBundled,
              let url = Bundle.main.url(forResource: "alarm", withExtension: "caf") else {
            return "Test sound failed — alarm.caf is not bundled in this build."
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = 2
            newPlayer.volume = 1.0
            newPlayer.play()
            player = newPlayer
            return "Playing the alarm tone now. If you hear nothing, check the ringer switch and volume."
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
