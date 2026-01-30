import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart';

// --- JS Interop Definitions (Only seen by this file) ---

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

class PwaLogic {
  void initListeners({
    required Function(BeforeInstallPromptEvent) onBeforeInstallPrompt,
    required VoidCallback onAppInstalled,
  }) {
    // Check for early-captured event in window.deferredBeforeInstallPromptEvent
    final globalContext = window as JSObject;
    final earlyEvent =
        globalContext.getProperty('deferredBeforeInstallPromptEvent'.toJS);

    if (earlyEvent != null && !earlyEvent.isUndefined && !earlyEvent.isNull) {
      debugPrint(
          'PWA: Found early deferred event in window.deferredBeforeInstallPromptEvent');
      onBeforeInstallPrompt(earlyEvent as BeforeInstallPromptEvent);
    }

    // Listen for 'beforeinstallprompt'
    final onBeforeInstallPromptJS = (Event event) {
      debugPrint('PWA: Event fired - beforeinstallprompt (Listener)');
      onBeforeInstallPrompt(event as BeforeInstallPromptEvent);
    }.toJS;

    window.addEventListener('beforeinstallprompt', onBeforeInstallPromptJS);

    // Listen for 'appinstalled'
    final onAppInstalledJS = (Event event) {
      debugPrint('PWA: App was installed');
      onAppInstalled();
    }.toJS;

    window.addEventListener('appinstalled', onAppInstalledJS);
  }

  Future<void> prompt(BeforeInstallPromptEvent event) async {
    // Show the install prompt
    await event.prompt().toDart;

    // Wait for the user to respond to the prompt
    final choice = await event.userChoice.toDart;
    debugPrint('PWA: User choice: ${choice.outcome}');
  }

  bool get isIOS {
    final userAgent = window.navigator.userAgent.toLowerCase();
    return userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
  }

  bool get isMacSafari {
    final userAgent = window.navigator.userAgent.toLowerCase();
    // Mac detection: 'macintosh' is in UA.
    // Safari detection: 'safari' is in UA, but 'chrome' is NOT (Chrome's UA contains 'Safari').
    final isMac = userAgent.contains('macintosh');
    final isSafari =
        userAgent.contains('safari') && !userAgent.contains('chrome');
    return isMac && isSafari;
  }

  bool get isStandalone {
    return window.matchMedia('(display-mode: standalone)').matches;
  }
}
