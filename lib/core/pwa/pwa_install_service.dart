import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart';

// --- JS Interop Definitions ---

extension type BeforeInstallPromptEvent._(JSObject _) implements Event {
  external JSPromise prompt();
  external JSPromise<UserChoice> get userChoice;
}

extension type UserChoice._(JSObject _) implements JSObject {
  external String get outcome;
  external String get platform;
}

// Extension to safely access window properties
extension WindowExtension on Window {
  external JSObject? get deferredBeforeInstallPromptEvent;
}

// --- Service Implementation ---

enum PwaMode { none, native, ios, mac }

class PwaInstallService extends Notifier<PwaMode> {
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
    // Check for early-captured event in window.deferredBeforeInstallPromptEvent
    final globalContext = window as JSObject;
    final earlyEvent =
        globalContext.getProperty('deferredBeforeInstallPromptEvent'.toJS);

    if (earlyEvent != null && !earlyEvent.isUndefined && !earlyEvent.isNull) {
      debugPrint(
          'PWA: Found early deferred event in window.deferredBeforeInstallPromptEvent');
      _handleBeforeInstallPrompt(earlyEvent as BeforeInstallPromptEvent);
    }

    // Listen for 'beforeinstallprompt'
    final onBeforeInstallPrompt = (Event event) {
      debugPrint('PWA: Event fired - beforeinstallprompt (Listener)');
      _handleBeforeInstallPrompt(event as BeforeInstallPromptEvent);
    }.toJS;

    window.addEventListener('beforeinstallprompt', onBeforeInstallPrompt);

    // Listen for 'appinstalled'
    final onAppInstalled = (Event event) {
      debugPrint('PWA: App was installed');
      _deferredPrompt = null;
      state = PwaMode.none;
    }.toJS;

    window.addEventListener('appinstalled', onAppInstalled);
  }

  void _handleBeforeInstallPrompt(BeforeInstallPromptEvent event) {
    event.preventDefault();
    _deferredPrompt = event;

    // Check persistence before showing
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
  }

  Future<void> promptInstall() async {
    if (_deferredPrompt == null) {
      debugPrint('PWA: No deferred prompt available');
      return;
    }

    // Show the install prompt
    await _deferredPrompt!.prompt().toDart;

    // Wait for the user to respond to the prompt
    final choice = await _deferredPrompt!.userChoice.toDart;

    debugPrint('PWA: User choice: ${choice.outcome}');

    // We've used the prompt, so we can't use it again.
    _deferredPrompt = null;
    state = PwaMode.none;
  }

  bool get isIOS {
    if (!kIsWeb) return false;
    final userAgent = window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  }

  bool get isMacSafari {
    if (!kIsWeb) return false;
    final userAgent = window.navigator.userAgent.toLowerCase();
    // Mac detection: 'macintosh' is in UA.
    // Safari detection: 'safari' is in UA, but 'chrome' is NOT (Chrome's UA contains 'Safari').
    final isMac = userAgent.contains('macintosh');
    final isSafari =
        userAgent.contains('safari') && !userAgent.contains('chrome');
    return isMac && isSafari;
  }

  bool get isStandalone {
    if (!kIsWeb) return false;
    return window.matchMedia('(display-mode: standalone)').matches;
  }
}

final pwaInstallServiceProvider =
    NotifierProvider<PwaInstallService, PwaMode>(() {
  return PwaInstallService();
});
