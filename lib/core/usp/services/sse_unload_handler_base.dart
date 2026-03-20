import 'dart:ui';

/// No-op stub for non-Web platforms (Dart VM / tests).
///
/// Selected by conditional export when `dart.library.js_interop` is unavailable.
class SseUnloadHandler {
  VoidCallback? onUnload;

  void register() {}

  void unregister() {}
}
