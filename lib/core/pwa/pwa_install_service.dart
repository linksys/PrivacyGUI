import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pwa_logic.dart';

enum PwaMode { none, native, ios, mac }

class PwaInstallService extends Notifier<PwaMode> {
  /// [logic] and [isWeb] default to the browser's [PwaLogic] and [kIsWeb].
  /// Tests pass their own, so that the service runs on the Dart VM.
  PwaInstallService({PwaLogic? logic, bool? isWeb})
      : _pwaLogic = logic ?? PwaLogic(),
        _isWeb = isWeb ?? kIsWeb;

  final PwaLogic _pwaLogic;
  final bool _isWeb;
  bool _isListenersInitialized = false;

  BeforeInstallPromptEvent? _deferredPrompt;
  static const _kDismissedKey = 'pwa_prompt_dismissed_timestamp';

  @override
  PwaMode build() {
    // Only run on Web
    if (_isWeb) {
      if (!_isListenersInitialized) {
        _initListeners();
        _isListenersInitialized = true;
      }

      // Trigger check on build (initial load or subsequent builds)
      _checkPlatformAndPersistence();
    }
    return PwaMode.none; // Default
  }

  Future<void> _checkPlatformAndPersistence() async {
    try {
      // 1. Standalone Check
      if (isStandalone) {
        state = PwaMode.none;
        return;
      }

      // 2. Persistence/Dismissal Check
      final dismissed = await isDismissedRecently();
      if (dismissed) {
        state = PwaMode.none;
        return;
      }

      // 3. Platform checks for non-native-prompt platforms (iOS/Mac)
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
    if (!_isWeb) return;

    try {
      // Use the shared Logic Loader
      _pwaLogic.initListeners(
        onBeforeInstallPrompt: _onBeforeInstallPrompt,
        onAppInstalled: () {
          _deferredPrompt = null;
          state = PwaMode.none;
        },
      );
    } catch (e) {
      debugPrint('PWA: Error initializing listeners: $e');
    }
  }

  // The browser offers its install prompt: live, or the event that
  // web/early-bootstrap.js captured before the app started, which
  // initListeners replays. Every model offers it.
  Future<void> _onBeforeInstallPrompt(BeforeInstallPromptEvent event) async {
    _deferredPrompt = event;
    if (isStandalone) return;
    if (await isDismissedRecently()) {
      debugPrint('PWA: Install prompt kept hidden: dismissed recently');
      return;
    }
    state = PwaMode.native;
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
    if (!_isWeb) return false;
    return _pwaLogic.isIOS;
  }

  bool get isMacSafari {
    if (!_isWeb) return false;
    return _pwaLogic.isMacSafari;
  }

  bool get isStandalone {
    if (!_isWeb) return false;
    return _pwaLogic.isStandalone;
  }
}

final pwaInstallServiceProvider =
    NotifierProvider<PwaInstallService, PwaMode>(() {
  return PwaInstallService();
});
