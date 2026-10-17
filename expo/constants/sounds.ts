export interface AlarmSoundOption {
  id: string;
  name: string;
  // Static require() handle for the bundled audio file
  audio: number;
}

/**
 * Catalog of alarm tones, kept in sync with the iOS app's `AlarmSound`
 * (same ids). The default here matches the iOS default so alarms ring with
 * the same sound on both platforms.
 */
export const ALARM_SOUNDS: AlarmSoundOption[] = [
  { id: 'wake_pulse', name: 'Wake Pulse', audio: require('@/assets/sounds/tone_wake_pulse.mp3') },
  { id: 'rising_sun', name: 'Rising Sun', audio: require('@/assets/sounds/tone_rising_sun.mp3') },
  { id: 'loud_classic', name: 'Loud Classic', audio: require('@/assets/alarm.mp3') },
  { id: 'classic_bells', name: 'Classic Bells', audio: require('@/assets/sounds/tone_classic_bells.mp3') },
  { id: 'digital_chirp', name: 'Digital Chirp', audio: require('@/assets/sounds/tone_digital_chirp.mp3') },
  { id: 'siren', name: 'Siren', audio: require('@/assets/sounds/tone_siren.mp3') },
  { id: 'gentle_morning', name: 'Gentle Morning', audio: require('@/assets/sounds/tone_gentle_morning.mp3') },
];

export const DEFAULT_ALARM_SOUND_ID = 'wake_pulse';

/** Resolves a persisted sound id; unknown values fall back to the default. */
export function alarmSoundForId(id: string | undefined | null): AlarmSoundOption {
  return ALARM_SOUNDS.find(s => s.id === id) ?? ALARM_SOUNDS[0];
}
