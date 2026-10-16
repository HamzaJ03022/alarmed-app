import { Router } from 'expo-router';

/**
 * Navigates back when possible, otherwise to the root (alarms) screen.
 * `router.canGoBack()` throws on web, so back is attempted inside try/catch
 * with a fallback route. Behavior on native is unchanged.
 */
export function goBackOrHome(router: Router): void {
  try {
    router.back();
  } catch {
    router.replace('/');
  }
}
