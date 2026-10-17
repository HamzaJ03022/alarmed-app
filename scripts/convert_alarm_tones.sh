#!/usr/bin/env bash
# Converts the AI-generated alarm tone MP3s into the loud, loopable CAF files
# used by the iOS app (AlarmKit caps custom sounds at 30 seconds), and copies
# web-friendly MP3s into the Expo app's assets.
#
# The loudness chain matches the one used for the original alarm_loud.caf:
# high-pass 250 Hz, presence EQ at 3 kHz, compression with makeup gain, +5 dB
# volume, and a limiter at 0.97 to prevent clipping.
#
# Usage: bash scripts/convert_alarm_tones.sh
set -euo pipefail

IOS_RES="ios-alarmed/AlarmedIOS/Resources"
IOS_OUT="ios-alarmed/AlarmedIOS"
EXPO_OUT="expo/assets/sounds"

# generated file -> target tone name
declare -A TONES=(
  [aggressive_alarm_pulse]=tone_wake_pulse
  [morning_alarm_synth]=tone_rising_sun
  [alarm_clock_ringing]=tone_classic_bells
  [digital_alarm_beep]=tone_digital_chirp
  [emergency_siren_wail]=tone_siren
  [morning_chime_alarm]=tone_gentle_morning
)

mkdir -p "$EXPO_OUT"

for src in "${!TONES[@]}"; do
  name="${TONES[$src]}"
  input="$IOS_RES/$src.mp3"
  caf="$IOS_OUT/$name.caf"
  web="$EXPO_OUT/$name.mp3"
  [ -f "$input" ] || { echo "MISSING: $input"; exit 1; }

  ffmpeg -y -loglevel error -i "$input" -t 29 \
    -af "highpass=f=250,equalizer=f=3000:t=q:w=1:g=5,acompressor=threshold=-24dB:ratio=10:makeup=12,volume=5dB,alimiter=limit=0.97" \
    -c:a pcm_s16be "$caf"

  ffmpeg -y -loglevel error -i "$input" -t 29 -b:a 128k "$web"
  echo "OK: $caf + $web"
done

echo
echo "Durations and loudness (for verification, all must be < 30s):"
for name in "${TONES[@]}"; do
  caf="$IOS_OUT/$name.caf"
  printf '%s: ' "$name"
  ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$caf"
  ffmpeg -i "$caf" -af "volumedetect" -f null /dev/null 2>&1 | grep mean_volume
done
