import Foundation

/// Catalog of the alarm tones shipped with the app. The id is persisted on
/// each `Alarm`; every tone is a bundled CAF file processed for maximum
/// loudness and kept under the 30-second AlarmKit sound limit.
struct AlarmSound: Identifiable, Equatable {
    let id: String
    let name: String
    /// Bundled resource file name, including the `.caf` extension.
    let fileName: String

    /// Whether the tone actually shipped in this build's resources.
    var isBundled: Bool {
        Bundle.main.url(forResource: baseName, withExtension: "caf") != nil
    }

    var baseName: String {
        (fileName as NSString).deletingPathExtension
    }
}

extension AlarmSound {
    static let wakePulse = AlarmSound(id: "wake_pulse", name: "Wake Pulse", fileName: "tone_wake_pulse.caf")
    static let risingSun = AlarmSound(id: "rising_sun", name: "Rising Sun", fileName: "tone_rising_sun.caf")
    static let loudClassic = AlarmSound(id: "loud_classic", name: "Loud Classic", fileName: "alarm_loud.caf")
    static let classicBells = AlarmSound(id: "classic_bells", name: "Classic Bells", fileName: "tone_classic_bells.caf")
    static let digitalChirp = AlarmSound(id: "digital_chirp", name: "Digital Chirp", fileName: "tone_digital_chirp.caf")
    static let siren = AlarmSound(id: "siren", name: "Siren", fileName: "tone_siren.caf")
    static let gentleMorning = AlarmSound(id: "gentle_morning", name: "Gentle Morning", fileName: "tone_gentle_morning.caf")

    static let all: [AlarmSound] = [
        wakePulse, risingSun, loudClassic, classicBells, digitalChirp, siren, gentleMorning
    ]

    /// The punchy default tone used by new alarms and by older alarms that
    /// predate the sound picker.
    static let defaultID = wakePulse.id

    /// Resolves a persisted id to a tone; unknown or legacy values fall back
    /// to the default so an alarm never ends up without a bundled sound.
    static func sound(forID id: String?) -> AlarmSound {
        all.first { $0.id == id } ?? wakePulse
    }
}
