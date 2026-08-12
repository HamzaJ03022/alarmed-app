import React from 'react';
import { ScrollView, Text, StyleSheet } from 'react-native';
import { colors } from '@/constants/colors';

export default function PrivacyPolicyScreen() {
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.title}>Privacy Policy</Text>
      <Text style={styles.updated}>Last updated: August 12, 2026</Text>

      <Text style={styles.heading}>Overview</Text>
      <Text style={styles.body}>
        Alarmed is an alarm clock application that helps you wake up by requiring you to
        answer questions or type a phrase to dismiss alarms. We respect your privacy and
        are committed to protecting it.
      </Text>

      <Text style={styles.heading}>Data We Collect</Text>
      <Text style={styles.body}>
        Alarmed does not collect, store, or transmit any personal data. All app data —
        including alarms, settings, history, and quotes — is stored locally on your device.
        No data is ever sent to any server.
      </Text>

      <Text style={styles.heading}>Permissions</Text>
      <Text style={styles.body}>
        Alarmed requests the following permissions to provide its core functionality:
      </Text>
      <Text style={styles.bullet}>
        • Notifications: To schedule and deliver alarm notifications at your specified times.
      </Text>
      <Text style={styles.bullet}>
        • Audio: To play alarm sounds when an alarm is triggered.
      </Text>
      <Text style={styles.bullet}>
        • Vibration: To vibrate your device when an alarm rings.
      </Text>

      <Text style={styles.heading}>Third-Party Services</Text>
      <Text style={styles.body}>
        Alarmed does not use any third-party analytics, advertising, or tracking services.
        The app does not contain any SDKs that collect or transmit user data.
      </Text>

      <Text style={styles.heading}>Children&apos;s Privacy</Text>
      <Text style={styles.body}>
        Alarmed is suitable for users of all ages and does not collect any personal
        information from anyone, including children.
      </Text>

      <Text style={styles.heading}>Changes to This Policy</Text>
      <Text style={styles.body}>
        We may update this privacy policy from time to time. Any changes will be posted
        within the app and on this page.
      </Text>

      <Text style={styles.heading}>Contact Us</Text>
      <Text style={styles.body}>
        If you have any questions about this privacy policy, please contact us at
        support@nyytech.com.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 24,
    paddingBottom: 60,
  },
  title: {
    fontSize: 28,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 8,
  },
  updated: {
    fontSize: 14,
    color: colors.textSecondary,
    marginBottom: 24,
  },
  heading: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.text,
    marginTop: 24,
    marginBottom: 8,
  },
  body: {
    fontSize: 15,
    color: colors.textSecondary,
    lineHeight: 22,
    marginBottom: 8,
  },
  bullet: {
    fontSize: 15,
    color: colors.textSecondary,
    lineHeight: 22,
    marginLeft: 8,
    marginBottom: 4,
  },
});
