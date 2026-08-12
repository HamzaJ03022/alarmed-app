import * as Notifications from 'expo-notifications';
import { Alarm } from '@/types/alarm';

const DAY_MAP: Record<string, number> = {
  'sun': 1, 'mon': 2, 'tue': 3, 'wed': 4,
  'thu': 5, 'fri': 6, 'sat': 7,
};

/**
 * Schedules OS-level notifications for an alarm.
 * For one-time alarms, schedules a single notification at the next occurrence.
 * For repeating alarms, schedules a weekly repeating notification per selected day.
 * Returns the notification identifiers created.
 */
export async function scheduleAlarmNotification(alarm: Alarm): Promise<string[]> {
  await cancelAlarmNotifications(alarm.id);

  const [hours, minutes] = alarm.time.split(':').map(Number);
  if (isNaN(hours) || isNaN(minutes)) return [];

  const ids: string[] = [];
  const body = alarm.dismissalMode === 'phrase'
    ? 'Wake up! Type your phrase to dismiss.'
    : 'Wake up! Answer questions to dismiss.';

  const content: Notifications.NotificationContentInput = {
    title: alarm.label || 'Alarm',
    body,
    sound: true,
    data: { alarmId: alarm.id },
    interruptionLevel: 'timeSensitive',
  };

  if (alarm.repeatDays.length === 0) {
    // One-time alarm — fire at next occurrence of this time
    const triggerDate = new Date();
    triggerDate.setHours(hours, minutes, 0, 0);
    if (triggerDate <= new Date()) {
      triggerDate.setDate(triggerDate.getDate() + 1);
    }
    const id = await Notifications.scheduleNotificationAsync({
      content,
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.CALENDAR,
        hour: triggerDate.getHours(),
        minute: triggerDate.getMinutes(),
        day: triggerDate.getDate(),
        month: triggerDate.getMonth() + 1,
        year: triggerDate.getFullYear(),
      } as Notifications.CalendarTriggerInput,
    });
    ids.push(id);
  } else {
    // Repeating alarm — one weekly notification per selected day
    for (const day of alarm.repeatDays) {
      const weekday = DAY_MAP[day];
      if (!weekday) continue;
      const id = await Notifications.scheduleNotificationAsync({
        content,
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.CALENDAR,
          weekday,
          hour: hours,
          minute: minutes,
          repeats: true,
        } as Notifications.CalendarTriggerInput,
      });
      ids.push(id);
    }
  }

  return ids;
}

/**
 * Cancels all scheduled notifications for a given alarm ID.
 * Finds notifications by checking the alarmId field in content.data.
 */
export async function cancelAlarmNotifications(alarmId: string): Promise<void> {
  const notifications = await Notifications.getAllScheduledNotificationsAsync();
  for (const notif of notifications) {
    if (notif.content.data?.alarmId === alarmId) {
      await Notifications.cancelScheduledNotificationAsync(notif.identifier);
    }
  }
}

/**
 * Re-schedules notifications for all active alarms.
 * Call on app launch to ensure notifications are in sync after app updates or reinstalls.
 */
export async function rescheduleAllAlarms(alarms: Alarm[]): Promise<void> {
  for (const alarm of alarms) {
    if (alarm.isActive) {
      await scheduleAlarmNotification(alarm);
    } else {
      await cancelAlarmNotifications(alarm.id);
    }
  }
}
