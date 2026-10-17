import React, { useMemo, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Switch, Platform } from 'react-native';
import { useRouter } from 'expo-router';
import { Clock } from 'lucide-react-native';
import { formatTime12h, formatRepeatDays, getNextAlarmTime, formatRelativeTime } from '@/utils/time';
import { useAlarmStore } from '@/store/alarm-store';
import { colors } from '@/constants/colors';
import { Alarm } from '@/types/alarm';
import { scheduleAlarmNotification, cancelAlarmNotifications } from '@/utils/notifications';

interface AlarmItemProps {
  alarm: Alarm;
}

function AlarmItem({ alarm }: AlarmItemProps) {
  const router = useRouter();
  const toggleAlarm = useAlarmStore(state => state.toggleAlarm);

  const handleToggle = useCallback(() => {
    const wasActive = alarm.isActive;
    toggleAlarm(alarm.id);
    // Keep OS notifications in sync with the new state
    if (wasActive) {
      cancelAlarmNotifications(alarm.id);
    } else {
      scheduleAlarmNotification({ ...alarm, isActive: true }).catch(() => {});
    }
  }, [toggleAlarm, alarm]);

  const handleEdit = useCallback(() => {
    router.push(`/edit-alarm/${alarm.id}`);
  }, [router, alarm.id]);

  const nextAlarmTime = useMemo(() => {
    return alarm.isActive ? getNextAlarmTime(alarm.time, alarm.repeatDays) : null;
  }, [alarm.isActive, alarm.time, alarm.repeatDays]);

  const nextAlarmText = useMemo(() => {
    return nextAlarmTime ? formatRelativeTime(nextAlarmTime) : '';
  }, [nextAlarmTime]);

  // Clock-style split, e.g. 7:30 + AM
  const [timeMain, timeSuffix] = useMemo(() => {
    const formatted = formatTime12h(alarm.time);
    const idx = formatted.lastIndexOf(' ');
    return idx === -1 ? [formatted, ''] : [formatted.slice(0, idx), formatted.slice(idx + 1)];
  }, [alarm.time]);

  const scheduleLine = useMemo(() => {
    const challengeText = alarm.dismissalMode === 'phrase'
      ? 'Type a phrase'
      : `${alarm.questionCount} ${alarm.questionCount === 1 ? 'question' : 'questions'} • ${alarm.questionDifficulty.charAt(0).toUpperCase() + alarm.questionDifficulty.slice(1)}`;
    return `${formatRepeatDays(alarm.repeatDays)} • ${challengeText}`;
  }, [alarm.dismissalMode, alarm.questionCount, alarm.questionDifficulty, alarm.repeatDays]);

  return (
    <View style={[styles.container, !alarm.isActive && styles.containerInactive]}>
      <TouchableOpacity
        style={styles.contentContainer}
        onPress={handleEdit}
        activeOpacity={0.7}
      >
        <View style={styles.timeContainer}>
          <View style={styles.timeRow}>
            <Text style={[styles.time, !alarm.isActive && styles.inactiveText]}>
              {timeMain}
            </Text>
            <Text style={[styles.timeSuffix, !alarm.isActive && styles.inactiveSuffix]}>
              {timeSuffix}
            </Text>
          </View>
          <Text style={[styles.metaLine, !alarm.isActive && styles.inactiveText]}>
            {scheduleLine}
          </Text>
        </View>

        <View style={styles.detailsContainer}>
          {alarm.label ? (
            <Text style={[styles.label, !alarm.isActive && styles.inactiveText]} numberOfLines={1}>
              {alarm.label}
            </Text>
          ) : null}

          {alarm.isActive && nextAlarmText ? (
            <View style={styles.nextAlarmContainer}>
              <Clock size={14} color={colors.primary} style={styles.icon} />
              <Text style={styles.nextAlarm}>{nextAlarmText}</Text>
            </View>
          ) : null}
        </View>
      </TouchableOpacity>

      <Switch
        value={alarm.isActive}
        onValueChange={handleToggle}
        trackColor={{ false: colors.switchTrack, true: colors.primary }}
        thumbColor={Platform.OS === 'ios' ? undefined : colors.switchThumb}
        ios_backgroundColor={colors.switchTrack}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: colors.card,
    borderRadius: 20,
    padding: 20,
    marginBottom: 16,
    alignItems: 'center',
    shadowColor: colors.cardShadow,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.25,
    shadowRadius: 20,
    elevation: 8,
  },
  containerInactive: {
    opacity: 0.75,
    shadowOpacity: 0,
    elevation: 0,
  },
  contentContainer: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeContainer: {
    marginRight: 16,
  },
  timeRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    gap: 4,
  },
  time: {
    fontSize: 34,
    fontWeight: '300',
    color: colors.text,
    letterSpacing: -0.5,
  },
  timeSuffix: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.primary,
    paddingBottom: 5,
  },
  inactiveSuffix: {
    color: colors.inactive,
  },
  metaLine: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  detailsContainer: {
    flex: 1,
    justifyContent: 'center',
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 4,
  },
  nextAlarmContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  icon: {
    marginRight: 4,
  },
  nextAlarm: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.primary,
  },
  inactiveText: {
    color: colors.inactive,
  },
});

export default React.memo(AlarmItem);
