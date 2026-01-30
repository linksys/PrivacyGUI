import 'dart:async';
import 'package:flutter/foundation.dart';

// Stub class for Classes not available in VM (mock logic)
class BeforeInstallPromptEvent {}

class PwaLogic {
  void initListeners({
    required Function(BeforeInstallPromptEvent) onBeforeInstallPrompt,
    required VoidCallback onAppInstalled,
  }) {
    // No-op for Stub
  }

  Future<void> prompt(BeforeInstallPromptEvent event) async {
    // No-op for Stub
  }

  bool get isIOS => false;
  bool get isMacSafari => false;
  bool get isStandalone => false;
}
