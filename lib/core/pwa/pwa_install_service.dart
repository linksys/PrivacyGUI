import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/core/utils/device_features.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';

import 'pwa_logic.dart';

enum PwaMode { none, native, ios, mac }

// ... (imports)

class PwaInstallService extends Notifier<PwaMode> {
  // Reuse logic instance
  final _pwaLogic = PwaLogic();
  bool _isListenersInitialized = false;

  BeforeInstallPromptEvent? _deferredPrompt;
  static const _kDismissedKey = 'pwa_prompt_dismissed_timestamp';

  @override
  PwaMode build() {
    // Watch session state to trigger rebuilds when device info changes.
    // This ensures we respond to model number changes (e.g., device switching).
    final modelNumber = ref.watch(sessionProvider).modelNumber;

    // Only run on Web
    if (kIsWeb) {
      if (!_isListenersInitialized) {
        _initListeners();
        _isListenersInitialized = true;
      }

      // Trigger check on build (initial load or subsequent builds)
      _checkPlatformAndPersistence(modelNumber);
    }
    return PwaMode.none; // Default
  }

  Future<void> _checkPlatformAndPersistence(String modelNumber) async {
    try {
      // 1. Feature Flag Check (Centralized in device_features.dart)
      // Use the passed model number instead of reading from ref
      if (!isFeatureSupported(DeviceFeature.pwa, modelNumber)) {
        state = PwaMode.none;
        return;
      }

      // ... (rest same, remove local ref.read)

      // 2. Standalone Check
      if (isStandalone) {
        state = PwaMode.none;
        return;
      }

      // 3. Persistence/Dismissal Check
      final dismissed = await isDismissedRecently();
      if (dismissed) {
        state = PwaMode.none;
        return;
      }

      // 4. Platform checks for non-native-prompt platforms (iOS/Mac)
      if (isIOS) {
        state = PwaMode.ios;
      } else if (isMacSafari) {
        state = PwaMode.mac;
      }
      // Android/Desktop Chrome will be handled by 'beforeinstallprompt' event
    } catch (e, stack) {
      debugPrint('PWA: Error validating platform/persistence: $e\n$stack');
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_kDismissedKey);
      if (timestamp == null) return false;

      final dismissedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final difference = DateTime.now().difference(dismissedAt);

      // 30 Days cooldown
      return difference.inDays < 30;
    } catch (e) {
      debugPrint('PWA: Error checking dismissal state: $e');
      return false; // Fail safe: Assume not dismissed so user can see it if eligible
    }
  }

  void _initListeners() {
    if (!kIsWeb) return;

    // Listen to session state changes to handle device switching or delayed load
    ref.listen(sessionProvider, (prev, next) {
      if (prev?.modelNumber == next.modelNumber) return;
      _checkPlatformAndPersistence(next.modelNumber);
    });

    try {
      // Use the shared Logic Loader
      _pwaLogic.initListeners(
        onBeforeInstallPrompt: (event) {
          _deferredPrompt = event;
          // Check persistence
          isDismissedRecently().then((recentlyDismissed) {
            // ...
            // Re-check using current model number
            final modelNumber = ref.read(sessionProvider).modelNumber;
            if (!isFeatureSupported(DeviceFeature.pwa, modelNumber)) {
              // ...
              return;
            }
            // ...
          });
        },
        onAppInstalled: () {
          _deferredPrompt = null;
          state = PwaMode.none;
        },
      );
    } catch (e) {
      debugPrint('PWA: Error initializing listeners: $e');
    }
  }

  Future<void> promptInstall() async {
    if (_deferredPrompt == null) {
      debugPrint('PWA: No deferred prompt available');
      return;
    }

    // Show the install prompt
    await _pwaLogic.prompt(_deferredPrompt!);

    // We've used the prompt, so we can't use it again.
    _deferredPrompt = null;
    state = PwaMode.none;
  }

  bool get isIOS {
    if (!kIsWeb) return false;
    return _pwaLogic.isIOS;
  }

  bool get isMacSafari {
    if (!kIsWeb) return false;
    return _pwaLogic.isMacSafari;
  }

  bool get isStandalone {
    if (!kIsWeb) return false;
    return _pwaLogic.isStandalone;
  }
}

final pwaInstallServiceProvider =
    NotifierProvider<PwaInstallService, PwaMode>(() {
  return PwaInstallService();
});
