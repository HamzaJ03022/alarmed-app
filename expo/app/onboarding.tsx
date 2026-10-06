import React, { useCallback, useRef, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Dimensions,
  NativeSyntheticEvent,
  NativeScrollEvent,
} from 'react-native';
import { AlarmClock, BellRing, PenLine, type LucideIcon } from 'lucide-react-native';
import * as Notifications from 'expo-notifications';
import { useAlarmStore } from '@/store/alarm-store';
import { colors } from '@/constants/colors';
import { DismissalMode } from '@/types/alarm';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

interface Slide {
  icon: LucideIcon;
  title: string;
  body: string;
}

const SLIDES: Slide[] = [
  {
    icon: AlarmClock,
    title: 'Earn your wake-up',
    body: 'Your alarm keeps ringing until you finish the challenge you set. There is no snooze escape hatch.',
  },
  {
    icon: PenLine,
    title: 'Choose your challenge',
    body: 'Answer a preset number of questions with a 90-second timer each — or type your saved phrase exactly to dismiss.',
  },
  {
    icon: BellRing,
    title: 'Alarms that break through',
    body: 'Time-sensitive notifications ring even when the app is closed. Notifications are what make background alarms fire.',
  },
];

export default function Onboarding() {
  const completeOnboarding = useAlarmStore((state) => state.completeOnboarding);

  const [step, setStep] = useState<'cards' | 'setup'>('cards');
  const [activeCard, setActiveCard] = useState(0);
  const [mode, setMode] = useState<DismissalMode>('questions');
  const [phrase, setPhrase] = useState('');
  const [permissionDenied, setPermissionDenied] = useState(false);
  const [isRequesting, setIsRequesting] = useState(false);

  const scrollRef = useRef<ScrollView>(null);

  const handleSkip = useCallback(() => {
    completeOnboarding('questions', '');
  }, [completeOnboarding]);

  const handleCardsNext = useCallback(() => {
    if (activeCard < SLIDES.length - 1) {
      scrollRef.current?.scrollTo({ x: (activeCard + 1) * SCREEN_WIDTH, animated: true });
    } else {
      setStep('setup');
    }
  }, [activeCard]);

  const finishOnboarding = useCallback(() => {
    completeOnboarding(mode, phrase);
  }, [completeOnboarding, mode, phrase]);

  const handleEnableAlarms = useCallback(async () => {
    if (permissionDenied) {
      finishOnboarding();
      return;
    }
    setIsRequesting(true);
    try {
      const { status } = await Notifications.requestPermissionsAsync();
      if (status === 'granted') {
        finishOnboarding();
      } else {
        setPermissionDenied(true);
      }
    } catch (e) {
      console.warn('Notification permission request failed:', e);
      setPermissionDenied(true);
    } finally {
      setIsRequesting(false);
    }
  }, [finishOnboarding, permissionDenied]);

  const handleScroll = useCallback((event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const index = Math.round(event.nativeEvent.contentOffset.x / SCREEN_WIDTH);
    setActiveCard(Math.max(0, Math.min(SLIDES.length - 1, index)));
  }, []);

  const primaryLabel =
    step === 'cards'
      ? activeCard < SLIDES.length - 1
        ? 'Continue'
        : 'Make it yours'
      : permissionDenied
        ? 'Get Started'
        : 'Enable Alarms';

  const phraseInvalid = mode === 'phrase' && phrase.length < 10;

  return (
    <View style={styles.container}>
      <View style={styles.topBar}>
        <Text style={styles.brand}>Alarmed</Text>
        <TouchableOpacity onPress={handleSkip} hitSlop={12} disabled={isRequesting}>
          <Text style={styles.skipText}>Skip</Text>
        </TouchableOpacity>
      </View>

      {step === 'cards' ? (
        <>
          <ScrollView
            ref={scrollRef}
            horizontal
            pagingEnabled
            showsHorizontalScrollIndicator={false}
            onMomentumScrollEnd={handleScroll}
            style={styles.slidesScroll}
          >
            {SLIDES.map((slide, index) => (
              <View key={slide.title} style={styles.slide}>
                <View style={styles.artwork}>
                  <slide.icon size={44} color={colors.primary} />
                </View>
                <Text style={styles.slideTitle}>{slide.title}</Text>
                <Text style={styles.slideBody}>{slide.body}</Text>
                {index === SLIDES.length - 1 && (
                  <Text style={styles.slideFootnote}>You can enable notifications on the next step.</Text>
                )}
              </View>
            ))}
          </ScrollView>

          <View style={styles.dotsRow}>
            {SLIDES.map((slide, index) => (
              <View
                key={slide.title}
                style={[styles.dot, activeCard === index && styles.dotActive]}
              />
            ))}
          </View>

          <TouchableOpacity style={styles.primaryButton} onPress={handleCardsNext} activeOpacity={0.8}>
            <Text style={styles.primaryButtonText}>{primaryLabel}</Text>
          </TouchableOpacity>
        </>
      ) : (
        <ScrollView style={styles.setupScroll} contentContainerStyle={styles.setupContent} keyboardShouldPersistTaps="handled">
          <Text style={styles.setupTitle}>Make it yours</Text>
          <Text style={styles.setupSubtitle}>Pick how you want to dismiss your alarms by default. You can change it on every alarm.</Text>

          <TouchableOpacity
            style={[styles.modeCard, mode === 'questions' && styles.modeCardActive]}
            onPress={() => setMode('questions')}
            activeOpacity={0.8}
          >
            <View style={styles.modeIconWrap}>
              <AlarmClock size={26} color={mode === 'questions' ? colors.text : colors.textSecondary} />
            </View>
            <View style={styles.modeTextWrap}>
              <Text style={styles.modeTitle}>Questions</Text>
              <Text style={styles.modeBody}>Answer a preset number of questions correctly before the alarm stops.</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.modeCard, mode === 'phrase' && styles.modeCardActive]}
            onPress={() => setMode('phrase')}
            activeOpacity={0.8}
          >
            <View style={styles.modeIconWrap}>
              <PenLine size={26} color={mode === 'phrase' ? colors.text : colors.textSecondary} />
            </View>
            <View style={styles.modeTextWrap}>
              <Text style={styles.modeTitle}>Type a Phrase</Text>
              <Text style={styles.modeBody}>Write your own motivation — you'll have to type it exactly to dismiss.</Text>
            </View>
          </TouchableOpacity>

          {mode === 'phrase' && (
            <View style={styles.phraseWrap}>
              <TextInput
                style={styles.phraseInput}
                value={phrase}
                onChangeText={setPhrase}
                placeholder="e.g. I want to wake up so I can get to work on time and not be late"
                placeholderTextColor={colors.textSecondary}
                multiline
                maxLength={100}
                autoCapitalize="sentences"
                autoCorrect={false}
              />
              <Text style={styles.charCounter}>{phrase.length}/100</Text>
              {phrase.length > 0 && phrase.length < 10 && (
                <Text style={styles.validationText}>Phrase must be at least 10 characters</Text>
              )}
              <Text style={styles.helperText}>
                You'll need to type this exactly (case-sensitive) to dismiss the alarm.
              </Text>
            </View>
          )}

          {permissionDenied && (
            <Text style={styles.deniedText}>
              No worries — alarms still ring while the app is open. You can enable notifications anytime in your device settings.
            </Text>
          )}

          <TouchableOpacity
            style={[styles.primaryButton, phraseInvalid && styles.disabledButton]}
            onPress={handleEnableAlarms}
            disabled={phraseInvalid || isRequesting}
            activeOpacity={0.8}
          >
            <Text style={styles.primaryButtonText}>{isRequesting ? 'Asking…' : primaryLabel}</Text>
          </TouchableOpacity>
        </ScrollView>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    paddingTop: 12,
    paddingBottom: 12,
  },
  topBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 12,
  },
  brand: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  skipText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  slidesScroll: {
    flex: 1,
  },
  slide: {
    width: SCREEN_WIDTH,
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
  },
  artwork: {
    width: 110,
    height: 110,
    borderRadius: 55,
    backgroundColor: 'rgba(76, 125, 254, 0.15)',
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 32,
  },
  slideTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.text,
    textAlign: 'center',
    marginBottom: 16,
  },
  slideBody: {
    fontSize: 16,
    color: colors.textSecondary,
    textAlign: 'center',
    lineHeight: 24,
  },
  slideFootnote: {
    fontSize: 13,
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: 20,
  },
  dotsRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
    marginBottom: 24,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: colors.inactive,
  },
  dotActive: {
    backgroundColor: colors.primary,
    width: 20,
  },
  primaryButton: {
    backgroundColor: colors.primary,
    borderRadius: 16,
    paddingVertical: 16,
    marginHorizontal: 20,
    marginBottom: 16,
    alignItems: 'center',
  },
  primaryButtonText: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  setupScroll: {
    flex: 1,
  },
  setupContent: {
    padding: 20,
    paddingBottom: 24,
  },
  setupTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 8,
  },
  setupSubtitle: {
    fontSize: 15,
    color: colors.textSecondary,
    lineHeight: 22,
    marginBottom: 24,
  },
  modeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 20,
    marginBottom: 14,
    borderWidth: 2,
    borderColor: 'transparent',
  },
  modeCardActive: {
    borderColor: colors.primary,
  },
  modeIconWrap: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.inputBackground,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  modeTextWrap: {
    flex: 1,
  },
  modeTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 4,
  },
  modeBody: {
    fontSize: 13,
    color: colors.textSecondary,
    lineHeight: 18,
  },
  phraseWrap: {
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 20,
    marginBottom: 14,
  },
  phraseInput: {
    backgroundColor: colors.inputBackground,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: colors.text,
    minHeight: 90,
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
  deniedText: {
    fontSize: 14,
    color: colors.warning,
    lineHeight: 20,
    marginBottom: 14,
  },
  disabledButton: {
    opacity: 0.5,
  },
});
