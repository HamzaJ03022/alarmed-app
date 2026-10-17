import React, { useEffect, useRef, useCallback, useMemo, useState } from 'react';
import { View, Text, StyleSheet, FlatList, TouchableOpacity, AppState, AppStateStatus } from 'react-native';
import { useRouter, useLocalSearchParams } from 'expo-router';
import { Plus, AlertTriangle, CheckCircle2 } from 'lucide-react-native';
import { useAlarmStore } from '@/store/alarm-store';
import AlarmItem from '@/components/AlarmItem';
import EmptyState from '@/components/EmptyState';
import { colors } from '@/constants/colors';
import { shouldRingToday } from '@/utils/time';
import { cancelAlarmNotifications } from '@/utils/notifications';

export default function AlarmsScreen() {
  const router = useRouter();
  const alarms = useAlarmStore(state => state.alarms);
  const setActiveAlarm = useAlarmStore(state => state.setActiveAlarm);
  const updateAlarm = useAlarmStore(state => state.updateAlarm);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const lastTriggeredRef = useRef<Set<string>>(new Set());
  const params = useLocalSearchParams<{ toast?: string }>();
  const [toast, setToast] = useState('');

  // Success toast handed over from Create/Edit Alarm via route params
  useEffect(() => {
    if (params.toast) {
      setToast(params.toast);
      router.setParams({ toast: undefined });
    }
  }, [params.toast, router]);

  useEffect(() => {
    if (!toast) return;
    const t = setTimeout(() => setToast(''), 2500);
    return () => clearTimeout(t);
  }, [toast]);

  const activeAlarms = useMemo(() => {
    return alarms.filter(alarm => alarm.isActive);
  }, [alarms]);

  const checkAlarms = useCallback(() => {
    const now = new Date();
    const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
    const todayKey = now.toDateString();

    for (const alarm of activeAlarms) {
      const alarmTime = alarm.time;
      const triggerKey = `${alarm.id}-${todayKey}-${alarmTime}`;

      if (
        alarmTime === currentTime &&
        shouldRingToday(alarm.repeatDays) &&
        !lastTriggeredRef.current.has(triggerKey)
      ) {
        lastTriggeredRef.current.add(triggerKey);
        setActiveAlarm(alarm.id);
        // Auto-disable one-time alarms after ringing
        if (alarm.repeatDays.length === 0) {
          updateAlarm(alarm.id, { isActive: false });
          cancelAlarmNotifications(alarm.id);
        }
        router.push('/alarm-ringing');
        break;
      }
    }
  }, [activeAlarms, setActiveAlarm, router, updateAlarm]);

  useEffect(() => {
    checkAlarms();

    intervalRef.current = setInterval(() => {
      checkAlarms();
    }, 1000);

    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
      }
    };
  }, [checkAlarms]);

  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextAppState: AppStateStatus) => {
      if (nextAppState === 'active') {
        checkAlarms();
      }
    });

    return () => {
      subscription.remove();
    };
  }, [checkAlarms]);

  const handleCreateAlarm = useCallback(() => {
    router.push('/create-alarm');
  }, [router]);

  if (alarms.length === 0) {
    return (
      <EmptyState
        title="No Alarms Set"
        description="Create your first alarm to start waking up on time and building better habits."
        actionText="Create Alarm"
        onAction={handleCreateAlarm}
      />
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.warningBanner}>
        <AlertTriangle size={18} color={colors.warning} />
        <Text style={styles.warningText}>
          Alarms ring even when the app is closed — keep notifications enabled
        </Text>
      </View>

      <FlatList
        data={alarms}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <AlarmItem alarm={item} />}
        contentContainerStyle={styles.listContent}
        removeClippedSubviews={true}
        maxToRenderPerBatch={10}
        windowSize={10}
      />

      {toast !== '' && (
        <View style={styles.toast} pointerEvents="none">
          <CheckCircle2 size={18} color={colors.success} />
          <Text style={styles.toastText}>{toast}</Text>
        </View>
      )}

      <TouchableOpacity
        style={styles.fab}
        onPress={handleCreateAlarm}
        activeOpacity={0.8}
      >
        <Plus size={24} color={colors.text} />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  warningBanner: {
    backgroundColor: colors.warningBackground,
    paddingVertical: 12,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    borderBottomWidth: 1,
    borderBottomColor: colors.warning,
  },
  warningText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.warning,
    flex: 1,
  },
  toast: {
    position: 'absolute',
    bottom: 110,
    alignSelf: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: colors.card,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: colors.success,
    paddingHorizontal: 18,
    paddingVertical: 12,
    shadowColor: colors.cardShadow,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.4,
    shadowRadius: 16,
    elevation: 10,
  },
  toastText: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.text,
  },
  listContent: {
    padding: 16,
    paddingBottom: 100,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 64,
    height: 64,
    borderRadius: 32,
    backgroundColor: colors.primary,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.4,
    shadowRadius: 16,
    elevation: 10,
  },
});
