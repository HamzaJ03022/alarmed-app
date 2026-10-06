import AudioToolbox
import AVFoundation

final class AudioManager: @unchecked Sendable {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private var volumeTimer: Timer?
    private var vibrationTimer: Timer?

    private init() {
        configureSession()
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func playAlarm(volume: Double, crescendo: Bool, vibrate: Bool = true) {
        guard let url = Bundle.main.url(forResource: "alarm", withExtension: "mp3") else {
            print("Alarm sound not found, playing system sound")
            playSystemAlarm()
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            if crescendo {
                player?.volume = 0.3
            } else {
                player?.volume = Float(volume)
            }
            player?.play()
            if crescendo { startCrescendo(targetVolume: volume) }
            if vibrate { startVibration() }
        } catch {
            print("Audio player error: \(error)")
            playSystemAlarm()
        }
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

    private func startCrescendo(targetVolume: Double) {
        volumeTimer?.invalidate()
        volumeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.player else {
                timer.invalidate(); return
            }
            let newVolume = min(player.volume + 0.05, Float(targetVolume))
            player.volume = newVolume
            if newVolume >= Float(targetVolume) {
                timer.invalidate()
                self.volumeTimer = nil
            }
        }
    }

    private func playSystemAlarm() {
        AudioServicesPlayAlertSound(1005)
    }

    func stop() {
        player?.stop()
        player = nil
        volumeTimer?.invalidate()
        volumeTimer = nil
        vibrationTimer?.invalidate()
        vibrationTimer = nil
    }

    var currentVolume: Float { player?.volume ?? 0 }
}
