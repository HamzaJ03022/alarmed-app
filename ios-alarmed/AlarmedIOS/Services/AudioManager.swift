import AudioToolbox
import AVFoundation

/// In-app alarm playback for the challenge screen. A real alarm always plays
/// the loud tone at full player volume — no fade-in, no in-app volume cap —
/// while `SystemVolumeLock` holds the device volume at maximum.
final class AudioManager: @unchecked Sendable {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private var vibrationTimer: Timer?

    private init() {}

    private func activateSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
    }

    /// Starts the looping alarm at full volume. Safe to call again (e.g. when
    /// returning to the foreground): it only restarts playback if stopped.
    func playAlarm(vibrate: Bool = true) {
        activateSession()
        if let player, player.isPlaying {
            if vibrate && vibrationTimer == nil { startVibration() }
            return
        }
        guard let url = AlarmSoundTester.toneURL
            ?? Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            playSystemAlarm()
            if vibrate { startVibration() }
            return
        }
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 1.0
            newPlayer.play()
            player = newPlayer
        } catch {
            print("Audio player error: \(error.localizedDescription)")
            playSystemAlarm()
        }
        if vibrate { startVibration() }
    }

    /// Repeating device vibration while the alarm rings in-app. Uses the
    /// system vibrate sound so it works regardless of ringer/silent state.
    func startVibration() {
        vibrationTimer?.invalidate()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }

    private func playSystemAlarm() {
        AudioServicesPlayAlertSound(1005)
    }

    func stop() {
        player?.stop()
        player = nil
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }
}
