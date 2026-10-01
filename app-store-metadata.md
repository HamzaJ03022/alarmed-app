# Alarmed — App Store Listing Metadata (v1.0.0)

App: **Alarmed** · Bundle: `com.nyytech.alarmed` (Expo build, iOS)
Prepared from the codebase, 2026-10-01.

---

## App Information

| Field | Value |
|---|---|
| **Name** | Alarmed |
| **Subtitle** (≤30 chars) | Wake up with a challenge |
| **Primary Category** | Utilities |
| **Secondary Category** | Productivity |
| **Copyright** | NyyTech |
| **Content Rating** | 4+ (no objectionable content) |
| **Price** | Free (no IAP) |

## Keywords (≤100 chars, comma-separated)

```
alarm clock,heavy sleeper,wake up,morning,quiz,challenge,questions,snooze,routine,tracker
```
*(89/100 chars — do not add spaces after commas)*

## Promotional Text (≤170 chars, editable anytime without review)

```
Your alarm won't quit until you do. Answer questions or type your phrase to turn it off. Built for heavy sleepers who hit snooze 12 times.
```
*(137/170 chars)*

## Description

```
Most alarm clocks have one fatal flaw: a snooze button.

Alarmed removes it. Your alarm keeps ringing until you've actually woken up — by completing a wake-up challenge YOU designed.

CHOOSE YOUR CHALLENGE
• Questions — answer a preset number of quiz questions correctly before the alarm shuts off. Pick your difficulty and categories, with a 90-second timer on every question.
• Type a Phrase — write your own motivation ("i want to wake up so i can get to work on time and not be late") and you'll have to type it back exactly to dismiss the alarm.

BUILT FOR HEAVY SLEEPERS
• Crescendo mode gradually ramps the volume until you're up
• Adjustable volume, sound and vibration controls
• Time-sensitive notifications break through Focus modes and silenced phones
• One-time alarms auto-disable after ringing; repeating alarms fire every scheduled day

TRACK YOUR MORNINGS
• Wake-up history shows every alarm, completed or missed
• Daily streaks keep you honest — miss a morning and it resets
• Add your own motivational quotes and see one the moment you dismiss the alarm

PRIVATE BY DESIGN
• No account, no sign-up, no tracking
• Everything stays on your device: alarms, history, phrases, quotes

Stop negotiating with your snooze button. Set the challenge, and earn your morning.
```

## Privacy Nutrition Label (App Store Connect answers)

- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:** None
- **Collects data:** No — all data (alarms, history, quotes, phrases) is stored locally on device (UserDefaults / AsyncStorage)
- **Privacy policy URL:** ⚠️ REQUIRED — App Store Connect needs a public URL. The policy text already exists in-app at `/privacy-policy`; it needs to be hosted publicly (e.g., publish the web version of the app and use its URL).

## Required URLs (must be live before submission)

| Field | Status | Plan |
|---|---|---|
| Privacy Policy URL | ⚠️ Missing | Publish web build → use `https://<name>.rork.app/privacy-policy` |
| Support URL | ⚠️ Missing | Same site root works: `https://<name>.rork.app` |

## Age Rating Questionnaire

- Violence, gambling, mature content: **None**
- Unrestricted web access: **No**
- User-generated content: **No** (quotes/phrases are device-local only, never shared)
- Result: **4+**

## Screenshot Checklist (6.7" and 6.1" iPhone sets)

1. Home — alarm list with times + challenge badges
2. Create Alarm — segmented control showing Questions | Type a Phrase
3. Alarm Ringing — question card with timer
4. Phrase Challenge — typing screen
5. History — streak card + completed entries
6. Settings — sound/vibration/crescendo toggles

## App Review Notes (suggested paste)

```
Alarmed uses local notifications (time-sensitive) for alarms and mic/camera permissions are NOT requested. All data is stored on-device. To test: create an alarm 2 minutes ahead, background the app, and the notification fires; opening the app or tapping the notification starts the challenge screen.
```

## Release Notes (What's New, v1.0.0)

```
Initial release. Wake up with a challenge: answer questions or type your pre-set phrase to dismiss your alarm.
```
