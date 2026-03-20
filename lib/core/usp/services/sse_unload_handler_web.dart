import 'dart:js_interop';
import 'dart:ui';

import 'package:web/web.dart' as web;

/// Registers browser `beforeunload` and `pagehide` listeners to trigger
/// SSE cleanup when the page is refreshed or closed.
///
/// - `beforeunload`: reliable on desktop browsers
/// - `pagehide`: reliable on mobile browsers (Safari/iOS) where
///   `beforeunload` may not fire
class SseUnloadHandler {
  VoidCallback? onUnload;
  JSFunction? _beforeUnloadJs;
  JSFunction? _pageHideJs;

  void register() {
    _beforeUnloadJs = ((web.Event event) {
      onUnload?.call();
    }).toJS;
    _pageHideJs = ((web.Event event) {
      onUnload?.call();
    }).toJS;
    web.window.addEventListener('beforeunload', _beforeUnloadJs!);
    web.window.addEventListener('pagehide', _pageHideJs!);
  }

  void unregister() {
    if (_beforeUnloadJs != null) {
      web.window.removeEventListener('beforeunload', _beforeUnloadJs!);
      _beforeUnloadJs = null;
    }
    if (_pageHideJs != null) {
      web.window.removeEventListener('pagehide', _pageHideJs!);
      _pageHideJs = null;
    }
  }
}
