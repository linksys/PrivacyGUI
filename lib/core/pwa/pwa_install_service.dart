import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pwa_logic.dart';

// Re-export types needed by the service interface if they are used publically,
// but since they are conditional, we might need to abstract them or rely on dynamic if exposed.
// However, PwaInstallService internalizes the event, so we just need to import pwa_logic which exports the stub/web classes.

enum PwaMode { none, native, ios, mac }

class PwaInstallService extends Notifier<PwaMode> {
  // Use dynamic or the exported type. Since pwa_logic exports the type (Stub or Web), it is safe.
  BeforeInstallPromptEvent? _deferredPrompt;
  static const _kDismissedKey = 'pwa_prompt_dismissed_timestamp';

  @override
  PwaMode build() {
    // Only run on Web
    if (kIsWeb) {
      _initListeners();
      _checkPlatformAndPersistence();
    }
    return PwaMode.none; // Default
  }

  Future<void> _checkPlatformAndPersistence() async {
    // If installed (standalone), never show
    if (isStandalone) {
      state = PwaMode.none;
      return;
    }

    final dismissed = await isDismissedRecently();
    if (dismissed) {
      state = PwaMode.none;
      return;
    }

    // Platform checks for non-native-prompt platforms (iOS/Mac)
    if (isIOS) {
      state = PwaMode.ios;
    } else if (isMacSafari) {
      state = PwaMode.mac;
    }
    // Android/Desktop Chrome will be handled by 'beforeinstallprompt' event
  }

  // Method to be called by UI to ignore the prompt for X days
  Future<void> dismiss() async {
    state = PwaMode.none; // Hide immediately
    _deferredPrompt = null; // Discard prompt for this session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kDismissedKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('PWA: Error saving dismissal state: $e');
    }
  }

  // Check if we are within the "cooldown" period (e.g. 30 days)
  Future<bool> isDismissedRecently() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_kDismissedKey);
    if (timestamp == null) return false;

    final dismissedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(dismissedAt);

    // 30 Days cooldown
    return difference.inDays < 30;
  }

  void _initListeners() {
    if (!kIsWeb) return;

    // Use the Logic Loader (conditionally imported class)
    PwaLogic().initListeners(
      onBeforeInstallPrompt: (event) {
        _deferredPrompt = event;
        // Check persistence
        isDismissedRecently().then((recentlyDismissed) {
          debugPrint('PWA: recentlyDismissed=$recentlyDismissed');
          if (!recentlyDismissed) {
            state = PwaMode.native;
            debugPrint(
                'PWA: State set to NATIVE. Captured beforeinstallprompt event');
          } else {
            debugPrint('PWA: Prompt suppressed due to recent dismissal');
          }
        });
      },
      onAppInstalled: () {
        _deferredPrompt = null;
        state = PwaMode.none;
      },
    );
  }

  Future<void> promptInstall() async {
    if (_deferredPrompt == null) {
      debugPrint('PWA: No deferred prompt available');
      return;
    }

    // Show the install prompt
    await PwaLogic().prompt(_deferredPrompt!);

    // We've used the prompt, so we can't use it again.
    _deferredPrompt = null;
    state = PwaMode.none;
  }

  bool get isIOS {
    if (!kIsWeb) return false;
    return PwaLogic().isIOS;
  }

  bool get isMacSafari {
    if (!kIsWeb) return false;
    return PwaLogic().isMacSafari;
  }

  bool get isStandalone {
    if (!kIsWeb) return false;
    return PwaLogic().isStandalone;
  }
}

final pwaInstallServiceProvider =
    NotifierProvider<PwaInstallService, PwaMode>(() {
  return PwaInstallService();
});
