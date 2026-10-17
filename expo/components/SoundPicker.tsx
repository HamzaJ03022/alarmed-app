import React, { useEffect, useRef, useState } from 'react';
import { StyleSheet, Text, TouchableOpacity, View } from 'react-native';
import { Audio } from 'expo-av';
import { Asset } from 'expo-asset';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '@/constants/colors';
import { ALARM_SOUNDS, DEFAULT_ALARM_SOUND_ID } from '@/constants/sounds';

interface SoundPickerProps {
  value: string;
  onChange: (id: string) => void;
}

/**
 * List of alarm tones with tap-to-preview: the speaker button plays the tone,
 * tapping the row selects it. A checkmark marks the current selection.
 */
export default function SoundPicker({ value, onChange }: SoundPickerProps) {
  const [previewingId, setPreviewingId] = useState<string | null>(null);
  const soundRef = useRef<Audio.Sound | null>(null);

  // Stop playback and release the player when leaving the screen.
  useEffect(() => {
    return () => {
      soundRef.current?.unloadAsync().catch(() => {});
      soundRef.current = null;
    };
  }, []);

  const togglePreview = async (id: string, audio: number) => {
    try {
      if (previewingId === id) {
        await soundRef.current?.stopAsync().catch(() => {});
        setPreviewingId(null);
        return;
      }
      await soundRef.current?.unloadAsync().catch(() => {});
      soundRef.current = null;
      // Bundled require() handles resolve through the Asset pipeline first
      const asset = Asset.fromModule(audio);
      await asset.downloadAsync();
      const { sound } = await Audio.Sound.createAsync(
        { uri: asset.localUri || asset.uri },
        { isLooping: true, shouldPlay: true }
      );
      soundRef.current = sound;
      setPreviewingId(id);
    } catch {
      setPreviewingId(null);
    }
  };

  return (
    <View style={styles.container}>
      {ALARM_SOUNDS.map(option => {
        const isSelected = option.id === value;
        const isPreviewing = option.id === previewingId;
        return (
          <View key={option.id} style={[styles.row, isSelected && styles.rowSelected]}>
            <TouchableOpacity
              style={styles.previewButton}
              onPress={() => togglePreview(option.id, option.audio)}
              accessibilityLabel={isPreviewing ? `Stop preview of ${option.name}` : `Preview ${option.name}`}
              hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
            >
              <Ionicons
                name={isPreviewing ? 'stop' : 'volume-high'}
                size={22}
                color={colors.primary}
              />
            </TouchableOpacity>
            <TouchableOpacity
              style={styles.nameArea}
              onPress={() => onChange(option.id)}
              activeOpacity={0.7}
            >
              <Text style={[styles.name, isSelected && styles.nameSelected]}>{option.name}</Text>
              {option.id === DEFAULT_ALARM_SOUND_ID && <Text style={styles.badge}>Default</Text>}
            </TouchableOpacity>
            {isSelected && (
              <Ionicons name="checkmark" size={22} color={colors.primary} />
            )}
          </View>
        );
      })}
      <Text style={styles.hint}>
        Tap the speaker to hear a tone, tap its name to choose it for this alarm.
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    gap: 8,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.inputBackground,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'transparent',
    paddingVertical: 10,
    paddingHorizontal: 12,
    gap: 12,
  },
  rowSelected: {
    borderColor: colors.primary,
  },
  previewButton: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.card,
  },
  nameArea: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  name: {
    fontSize: 15,
    fontWeight: '600' as const,
    color: colors.textSecondary,
  },
  nameSelected: {
    color: colors.text,
  },
  badge: {
    fontSize: 11,
    color: colors.textSecondary,
    backgroundColor: colors.card,
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 8,
    overflow: 'hidden' as const,
  },
  hint: {
    fontSize: 12,
    color: colors.textSecondary,
    lineHeight: 18,
    marginTop: 4,
  },
});
