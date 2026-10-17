import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Platform,
  Switch,
} from 'react-native';
import { useRouter } from 'expo-router';
import { goBackOrHome } from '@/utils/navigation';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import DateTimePicker, { DateTimePickerEvent } from '@react-native-community/datetimepicker';
import { useAlarmStore } from '@/store/alarm-store';
import { colors } from '@/constants/colors';
import { formatTimeFromDate, formatTime12h, formatRepeatDays } from '@/utils/time';
import { scheduleAlarmNotification } from '@/utils/notifications';
import { RepeatDay, QuestionDifficulty, QuestionCategory, DismissalMode } from '@/types/alarm';
import SoundPicker from '@/components/SoundPicker';
import { DEFAULT_ALARM_SOUND_ID } from '@/constants/sounds';

const WEEKDAY_KEYS: RepeatDay[] = ['mon', 'tue', 'wed', 'thu', 'fri'];
const ALL_DAYS: RepeatDay[] = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

export default function CreateAlarmScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const addAlarm = useAlarmStore(state => state.addAlarm);
  // Start from the defaults the user picked during onboarding
  const defaultMode = useAlarmStore(state => state.defaultChallengeMode);
  const onboardingPhrase = useAlarmStore(state => state.onboardingPhrase);

  const [date, setDate] = useState(new Date());
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [label, setLabel] = useState('');
  const [repeatDays, setRepeatDays] = useState<RepeatDay[]>([]);
  const [repeatEnabled, setRepeatEnabled] = useState(false);
  const [questionCount, setQuestionCount] = useState(3);
  const [questionDifficulty, setQuestionDifficulty] = useState<QuestionDifficulty>('medium');
  const [questionCategories, setQuestionCategories] = useState<QuestionCategory[]>(['math', 'general', 'puzzle']);
  const [vibrate, setVibrate] = useState(true);
  const [dismissalMode, setDismissalMode] = useState<DismissalMode>(defaultMode);
  const [dismissPhrase, setDismissPhrase] = useState(onboardingPhrase);
  const [sound, setSound] = useState(DEFAULT_ALARM_SOUND_ID);

  const handleDayToggle = useCallback((day: RepeatDay) => {
    if (repeatDays.includes(day)) {
      setRepeatDays(repeatDays.filter(d => d !== day));
    } else {
      setRepeatDays([...repeatDays, day]);
    }
  }, [repeatDays]);

  const handleCategoryToggle = (category: QuestionCategory) => {
    if (questionCategories.includes(category)) {
      // Don't allow removing the last category
      if (questionCategories.length > 1) {
        setQuestionCategories(questionCategories.filter(c => c !== category));
      }
    } else {
      setQuestionCategories([...questionCategories, category]);
    }
  };

  const handleTimeChange = (event: DateTimePickerEvent, selectedDate?: Date) => {
    if (Platform.OS === 'android') {
      setShowTimePicker(false);
    }

    if (selectedDate) {
      setDate(selectedDate);
    }
  };

  const handleRepeatToggle = (enabled: boolean) => {
    setRepeatEnabled(enabled);
    if (enabled && repeatDays.length === 0) {
      setRepeatDays([...WEEKDAY_KEYS]);
    } else if (!enabled) {
      setRepeatDays([]);
    }
  };

  const repeatSummary = !repeatEnabled || repeatDays.length === 0
    ? 'One-time alarm'
    : `Repeats ${formatRepeatDays(repeatDays).toLowerCase()}`;

  const handleSave = () => {
    const time = formatTimeFromDate(date);

    const alarmId = addAlarm({
      time,
      label: label.trim(),
      isActive: true,
      repeatDays,
      questionCount,
      questionDifficulty,
      questionCategories,
      sound,
      vibrate,
      dismissalMode,
      dismissPhrase: dismissalMode === 'phrase' ? dismissPhrase : '',
    });

    // Schedule OS notification for the alarm
    scheduleAlarmNotification({
      id: alarmId,
      time,
      label: label.trim(),
      isActive: true,
      repeatDays,
      questionCount,
      questionDifficulty,
      questionCategories,
      sound,
      vibrate,
      dismissalMode,
      dismissPhrase: dismissalMode === 'phrase' ? dismissPhrase : '',
    });

    router.replace({
      pathname: '/',
      params: { toast: `Alarm saved • rings at ${formatTime12h(time)}` },
    });
  };

  const handleCancel = () => {
    goBackOrHome(router);
  };

  const phraseIsValid = dismissalMode === 'questions' || dismissPhrase.length >= 10;

  return (
    <View style={styles.root}>
      <ScrollView
        style={styles.container}
        contentContainerStyle={[styles.content, { paddingBottom: 140 + insets.bottom }]}
        keyboardShouldPersistTaps="handled"
      >
        {/* Time is the primary action: large live preview, no card chrome */}
        <View style={styles.heroTime}>
          <Text style={styles.heroTimeText}>{formatTime12h(formatTimeFromDate(date))}</Text>
          {Platform.OS === 'android' ? (
            <TouchableOpacity
              style={styles.androidTimeButton}
              onPress={() => setShowTimePicker(true)}
              activeOpacity={0.7}
            >
              <Text style={styles.androidTimeButtonText}>Tap to change the time</Text>
            </TouchableOpacity>
          ) : (
            <Text style={styles.heroHint}>Drag the wheel to set your alarm time</Text>
          )}
        </View>

        {Platform.OS === 'ios' && (
          <DateTimePicker
            value={date}
            mode="time"
            is24Hour={false}
            display="spinner"
            onChange={handleTimeChange}
            style={styles.timePicker}
            textColor={colors.text}
          />
        )}

        {Platform.OS === 'android' && showTimePicker && (
          <DateTimePicker
            value={date}
            mode="time"
            is24Hour={false}
            display="default"
            onChange={handleTimeChange}
          />
        )}

        {Platform.OS === 'web' && (
          <View style={styles.webTimePickerContainer}>
            <DateTimePicker
              value={date}
              mode="time"
              is24Hour={false}
              display="default"
              onChange={handleTimeChange}
              style={styles.timePicker}
            />
          </View>
        )}

        <View style={styles.formSection}>
          <Text style={styles.sectionTitle}>Details</Text>

          <TextInput
            style={styles.textInput}
            value={label}
            onChangeText={setLabel}
            placeholder="Alarm label (optional)"
            placeholderTextColor={colors.textSecondary}
          />

          <View style={styles.divider} />

          <View style={styles.repeatHeader}>
            <View style={styles.repeatLabelContainer}>
              <Text style={styles.repeatLabel}>Repeat</Text>
              <Text style={styles.repeatSummary}>{repeatSummary}</Text>
            </View>
            <Switch
              value={repeatEnabled}
              onValueChange={handleRepeatToggle}
              trackColor={{ false: colors.switchTrack, true: colors.primary }}
              thumbColor={Platform.OS === 'ios' ? undefined : colors.switchThumb}
              ios_backgroundColor={colors.switchTrack}
            />
          </View>

          {repeatEnabled && (
            <>
              <View style={styles.quickChipsRow}>
                <TouchableOpacity
                  style={[
                    styles.quickChip,
                    repeatDays.length === 5 && WEEKDAY_KEYS.every(d => repeatDays.includes(d)) && styles.quickChipActive,
                  ]}
                  onPress={() => setRepeatDays([...WEEKDAY_KEYS])}
                  activeOpacity={0.7}
                >
                  <Text
                    style={[
                      styles.quickChipText,
                      repeatDays.length === 5 && WEEKDAY_KEYS.every(d => repeatDays.includes(d)) && styles.quickChipTextActive,
                    ]}
                  >
                    Weekdays
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[
                    styles.quickChip,
                    repeatDays.length === 7 && styles.quickChipActive,
                  ]}
                  onPress={() => setRepeatDays([...ALL_DAYS])}
                  activeOpacity={0.7}
                >
                  <Text
                    style={[
                      styles.quickChipText,
                      repeatDays.length === 7 && styles.quickChipTextActive,
                    ]}
                  >
                    Every day
                  </Text>
                </TouchableOpacity>
              </View>

              <View style={styles.daysRow}>
                {ALL_DAYS.map((day, index) => {
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return (
                    <TouchableOpacity
                      key={day}
                      style={[
                        styles.dayButton,
                        repeatDays.includes(day) && styles.dayButtonActive,
                      ]}
                      onPress={() => handleDayToggle(day)}
                      activeOpacity={0.7}
                    >
                      <Text
                        style={[
                          styles.dayText,
                          repeatDays.includes(day) && styles.dayTextActive,
                        ]}
                      >
                        {labels[index]}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </>
          )}

          <View style={styles.divider} />

          <Text style={styles.settingRowLabel}>Sound</Text>
          <SoundPicker value={sound} onChange={setSound} />

          <View style={styles.divider} />

          <View style={styles.settingRow}>
            <Text style={styles.settingRowLabel}>Vibrate</Text>
            <Switch
              value={vibrate}
              onValueChange={setVibrate}
              trackColor={{ false: colors.switchTrack, true: colors.primary }}
              thumbColor={Platform.OS === 'ios' ? undefined : colors.switchThumb}
              ios_backgroundColor={colors.switchTrack}
            />
          </View>
        </View>

        <View style={styles.formSection}>
          <Text style={styles.sectionTitle}>Wake-Up Challenge</Text>

          <View style={styles.inputContainer}>
            <Text style={styles.inputLabel}>How do you want to turn the alarm off?</Text>
            <View style={styles.segmentedControl}>
              {(['questions', 'phrase'] as DismissalMode[]).map((mode) => (
                <TouchableOpacity
                  key={mode}
                  style={[
                    styles.segmentButton,
                    dismissalMode === mode && styles.segmentButtonActive,
                  ]}
                  onPress={() => setDismissalMode(mode)}
                >
                  <Text
                    style={[
                      styles.segmentButtonText,
                      dismissalMode === mode && styles.segmentButtonTextActive,
                    ]}
                  >
                    {mode === 'questions' ? 'Questions' : 'Type a Phrase'}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            <Text style={styles.modeDescription}>
              {dismissalMode === 'questions'
                ? 'Answer quick math and trivia questions to turn the alarm off.'
                : 'Type your own phrase exactly to turn the alarm off.'}
            </Text>
          </View>

          {dismissalMode === 'questions' ? (
            <>
              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>How many questions</Text>
                <View style={styles.counterContainer}>
                  <TouchableOpacity
                    style={styles.counterButton}
                    onPress={() => setQuestionCount(Math.max(1, questionCount - 1))}
                    disabled={questionCount <= 1}
                  >
                    <Text style={styles.counterButtonText}>-</Text>
                  </TouchableOpacity>

                  <Text style={styles.counterValue}>{questionCount}</Text>

                  <TouchableOpacity
                    style={styles.counterButton}
                    onPress={() => setQuestionCount(Math.min(5, questionCount + 1))}
                    disabled={questionCount >= 5}
                  >
                    <Text style={styles.counterButtonText}>+</Text>
                  </TouchableOpacity>
                </View>
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>How hard</Text>
                <View style={styles.segmentedControl}>
                  {(['easy', 'medium', 'hard'] as QuestionDifficulty[]).map((difficulty) => (
                    <TouchableOpacity
                      key={difficulty}
                      style={[
                        styles.segmentButton,
                        questionDifficulty === difficulty && styles.segmentButtonActive,
                      ]}
                      onPress={() => setQuestionDifficulty(difficulty)}
                    >
                      <Text
                        style={[
                          styles.segmentButtonText,
                          questionDifficulty === difficulty && styles.segmentButtonTextActive,
                        ]}
                      >
                        {difficulty.charAt(0).toUpperCase() + difficulty.slice(1)}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>

              <View style={styles.inputContainer}>
                <Text style={styles.inputLabel}>Question topics</Text>
                <View style={styles.categoriesContainer}>
                  {(['math', 'general', 'puzzle'] as QuestionCategory[]).map((category) => (
                    <TouchableOpacity
                      key={category}
                      style={[
                        styles.categoryButton,
                        questionCategories.includes(category) && styles.categoryButtonActive,
                        questionCategories.length === 1 && questionCategories.includes(category) && styles.categoryButtonDisabled,
                      ]}
                      onPress={() => handleCategoryToggle(category)}
                      disabled={questionCategories.length === 1 && questionCategories.includes(category)}
                    >
                      <Text
                        style={[
                          styles.categoryButtonText,
                          questionCategories.includes(category) && styles.categoryButtonTextActive,
                        ]}
                      >
                        {category.charAt(0).toUpperCase() + category.slice(1)}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>
            </>
          ) : (
            <View style={styles.inputContainer}>
              <Text style={styles.inputLabel}>Dismissal Phrase</Text>
              <TextInput
                style={styles.phraseInput}
                value={dismissPhrase}
                onChangeText={setDismissPhrase}
                placeholder="e.g. I want to wake up so I can get to work on time and not be late"
                placeholderTextColor={colors.textSecondary}
                multiline
                maxLength={100}
                autoCapitalize="sentences"
                autoCorrect={false}
              />
              <Text style={styles.charCounter}>{dismissPhrase.length}/100</Text>
              {dismissPhrase.length > 0 && dismissPhrase.length < 10 && (
                <Text style={styles.validationText}>Phrase must be at least 10 characters</Text>
              )}
              <Text style={styles.helperText}>
                You'll need to type this phrase exactly (case-sensitive) to dismiss the alarm.
              </Text>
            </View>
          )}
        </View>
      </ScrollView>

      {/* Persistent save bar, above the home indicator, never covering content */}
      <View style={[styles.bottomBar, { paddingBottom: 16 + insets.bottom }]}>
        <TouchableOpacity style={[styles.button, styles.cancelButton]} onPress={handleCancel}>
          <Text style={styles.cancelButtonText}>Cancel</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.button,
            styles.saveButton,
            !phraseIsValid && styles.disabledButton,
          ]}
          onPress={handleSave}
          disabled={!phraseIsValid}
        >
          <Text style={styles.saveButtonText}>Save Alarm</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.background,
  },
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 20,
  },
  heroTime: {
    alignItems: 'center',
    marginTop: 8,
    marginBottom: 8,
  },
  heroTimeText: {
    fontSize: 56,
    fontWeight: '300',
    color: colors.text,
    letterSpacing: -1,
  },
  heroHint: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 8,
    fontWeight: '500',
  },
  androidTimeButton: {
    marginTop: 8,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 16,
    backgroundColor: colors.inputBackground,
  },
  androidTimeButtonText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.primary,
  },
  timePicker: {
    width: Platform.OS === 'ios' ? '100%' : undefined,
    height: Platform.OS === 'ios' ? 160 : undefined,
  },
  webTimePickerContainer: {
    width: '100%',
    alignItems: 'center',
    marginTop: 8,
  },
  formSection: {
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 20,
    marginBottom: 20,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.textSecondary,
    textTransform: 'uppercase' as const,
    letterSpacing: 0.8,
    marginBottom: 18,
  },
  divider: {
    height: 1,
    backgroundColor: colors.divider,
    marginVertical: 16,
  },
  textInput: {
    backgroundColor: colors.inputBackground,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: colors.text,
    borderWidth: 0,
  },
  repeatHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  repeatLabelContainer: {
    flex: 1,
    marginRight: 12,
  },
  repeatLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
  repeatSummary: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  quickChipsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 14,
  },
  quickChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 16,
    backgroundColor: 'rgba(76, 125, 254, 0.12)',
  },
  quickChipActive: {
    backgroundColor: 'rgba(76, 125, 254, 0.35)',
  },
  quickChipText: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.primary,
  },
  quickChipTextActive: {
    color: colors.text,
  },
  daysRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 14,
  },
  dayButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.inputBackground,
    justifyContent: 'center',
    alignItems: 'center',
  },
  dayButtonActive: {
    backgroundColor: colors.primary,
  },
  dayText: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  dayTextActive: {
    color: colors.text,
    fontWeight: '700',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  settingRowLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
  inputContainer: {
    marginBottom: 20,
  },
  inputLabel: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 12,
  },
  modeDescription: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 10,
    lineHeight: 18,
  },
  counterContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  counterButton: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.inputBackground,
    justifyContent: 'center',
    alignItems: 'center',
  },
  counterButtonText: {
    fontSize: 20,
    fontWeight: '600',
    color: colors.text,
  },
  counterValue: {
    fontSize: 32,
    fontWeight: '700',
    color: colors.text,
    marginHorizontal: 40,
    minWidth: 60,
    textAlign: 'center' as const,
  },
  segmentedControl: {
    flexDirection: 'row',
    gap: 12,
  },
  segmentButton: {
    flex: 1,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 12,
    backgroundColor: colors.inputBackground,
  },
  segmentButtonActive: {
    backgroundColor: colors.primary,
  },
  segmentButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  segmentButtonTextActive: {
    color: colors.text,
    fontWeight: '700',
  },
  categoriesContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  categoryButton: {
    paddingVertical: 12,
    paddingHorizontal: 24,
    borderRadius: 20,
    backgroundColor: colors.inputBackground,
  },
  categoryButtonActive: {
    backgroundColor: colors.primary,
  },
  categoryButtonDisabled: {
    opacity: 0.5,
  },
  categoryButtonText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  categoryButtonTextActive: {
    color: colors.text,
    fontWeight: '700',
  },
  phraseInput: {
    backgroundColor: colors.inputBackground,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: colors.text,
    minHeight: 80,
    textAlignVertical: 'top' as const,
    borderWidth: 1,
    borderColor: colors.inputBorder,
  },
  charCounter: {
    fontSize: 12,
    color: colors.textSecondary,
    textAlign: 'right' as const,
    marginTop: 4,
  },
  validationText: {
    fontSize: 12,
    color: colors.error,
    marginTop: 4,
  },
  helperText: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 8,
    lineHeight: 18,
  },
  bottomBar: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 20,
    paddingTop: 12,
    backgroundColor: colors.background,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  button: {
    flex: 1,
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center',
  },
  cancelButton: {
    backgroundColor: colors.inputBackground,
  },
  saveButton: {
    backgroundColor: colors.primary,
  },
  disabledButton: {
    opacity: 0.5,
  },
  cancelButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
  saveButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
});
