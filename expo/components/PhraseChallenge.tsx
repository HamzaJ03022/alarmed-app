import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Platform,
} from 'react-native';
import { colors } from '@/constants/colors';

interface PhraseChallengeProps {
  phrase: string;
  onCorrect: () => void;
  onSnooze: () => void;
  snoozeCount: number;
}

function PhraseChallenge({
  phrase,
  onCorrect,
  onSnooze,
  snoozeCount,
}: PhraseChallengeProps) {
  const [input, setInput] = useState('');
  const [hasSubmitted, setHasSubmitted] = useState(false);
  const [isCorrect, setIsCorrect] = useState(false);

  const handleSubmit = useCallback(() => {
    if (input.length === 0) return;
    const correct = input === phrase;
    setIsCorrect(correct);
    setHasSubmitted(true);
    if (correct) {
      onCorrect();
    }
  }, [input, phrase, onCorrect]);

  const handleTryAgain = useCallback(() => {
    setInput('');
    setHasSubmitted(false);
    setIsCorrect(false);
  }, []);

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.prompt}>Type your phrase to dismiss</Text>
      </View>

      <View style={styles.inputContainer}>
        <TextInput
          style={[
            styles.input,
            hasSubmitted && !isCorrect && styles.incorrectInput,
          ]}
          value={input}
          onChangeText={(text) => {
            setInput(text);
            if (hasSubmitted) {
              setHasSubmitted(false);
              setIsCorrect(false);
            }
          }}
          placeholder="Type your phrase here..."
          placeholderTextColor={colors.textSecondary}
          multiline
          autoCapitalize="sentences"
          autoCorrect={false}
          editable={!hasSubmitted || !isCorrect}
          autoFocus
        />

        {hasSubmitted && !isCorrect && (
          <View style={styles.errorContainer}>
            <Text style={styles.errorText}>
              Incorrect — try again
            </Text>
            <TouchableOpacity
              style={styles.tryAgainButton}
              onPress={handleTryAgain}
            >
              <Text style={styles.tryAgainText}>Try Again</Text>
            </TouchableOpacity>
          </View>
        )}

        {!hasSubmitted && (
          <TouchableOpacity
            style={[
              styles.submitButton,
              input.length === 0 && styles.submitButtonDisabled,
            ]}
            onPress={handleSubmit}
            disabled={input.length === 0}
            activeOpacity={0.7}
          >
            <Text style={styles.submitButtonText}>Submit</Text>
          </TouchableOpacity>
        )}
      </View>

      <TouchableOpacity
        style={styles.snoozeButton}
        onPress={onSnooze}
        activeOpacity={0.7}
      >
        <Text style={styles.snoozeButtonText}>
          Start Over ({snoozeCount})
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    marginBottom: 24,
  },
  prompt: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text,
    textAlign: 'center',
  },
  inputContainer: {
    marginBottom: 16,
  },
  input: {
    backgroundColor: colors.inputBackground,
    borderRadius: 16,
    padding: 16,
    fontSize: 16,
    color: colors.text,
    minHeight: 80,
    textAlignVertical: 'top' as const,
    borderWidth: 1,
    borderColor: colors.inputBorder,
  },
  incorrectInput: {
    borderColor: colors.error,
    backgroundColor: `${colors.error}15`,
  },
  errorContainer: {
    alignItems: 'center',
    marginTop: 16,
  },
  errorText: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.error,
    marginBottom: 12,
  },
  tryAgainButton: {
    backgroundColor: colors.inputBackground,
    borderRadius: 16,
    paddingVertical: 16,
    paddingHorizontal: 32,
    borderWidth: 1,
    borderColor: colors.inputBorder,
  },
  tryAgainText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
  submitButton: {
    backgroundColor: colors.primary,
    borderRadius: 16,
    paddingVertical: 18,
    alignItems: 'center',
    marginTop: 16,
    shadowColor: colors.primary,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 6,
  },
  submitButtonDisabled: {
    opacity: 0.5,
  },
  submitButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
  snoozeButton: {
    backgroundColor: colors.error,
    paddingVertical: 18,
    borderRadius: 16,
    alignItems: 'center',
    marginBottom: 32,
    shadowColor: colors.error,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 6,
  },
  snoozeButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.text,
  },
});

export default React.memo(PhraseChallenge);
