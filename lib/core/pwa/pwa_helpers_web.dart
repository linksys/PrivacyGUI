import 'package:web/web.dart';
import 'dart:js_interop';

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
