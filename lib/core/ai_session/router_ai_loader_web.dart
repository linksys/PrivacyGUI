import 'dart:html' as html;
import 'dart:js_util' as js_util;

const _splashHook = 'removeSplashFromWeb';
const _sessionEndedEvent = 'linksys-ai-session-ended';

/// The widget's "GUI is ready" hook, held privately once the bundle has run.
///
/// The widget learns that the GUI is ready (and clears the suppression a
/// logout sets) by wrapping `window.removeSplashFromWeb` when it loads. The GUI
/// also calls that function on every route redirect (FlutterNativeSplash.remove
/// on web), so left in place the wrapper would re-arm the widget on the login
/// screen right after a logout and show its manual-login card there. Once the
/// bundle has run, the GUI therefore puts its own splash remover back and keeps
/// the widget's wrapper here, calling it only after an authenticated AI session.
Object? _widgetReadyHook;

/// True from an authenticated AI session until the next logout. The bundle
/// downloads asynchronously, so a logout can land before it has run; the load
/// callback must not then re-arm the widget on the login screen.
bool _armed = false;

/// Appends one deferred `<script src="...">` for the Router AI bundle to the
/// document head, or re-arms the widget when the bundle is already loaded. Any
/// existing reference to the same file name - including query-string or
/// fragment variants - counts as already loaded, so a page can never end up
/// with two loaders. The widget initialises itself whether it arrives before or
/// after the document finishes parsing.
///
/// Returns true only if a script element was added by this call.
bool injectRouterAiBundle(String src) {
  _armed = true;
  final fileName = Uri.parse(src).pathSegments.last;
  final alreadyLoaded = html.document
      .querySelectorAll('script[src]')
      .whereType<html.ScriptElement>()
      .any((script) {
    final segments = Uri.tryParse(script.src)?.pathSegments ?? const [];
    return segments.isNotEmpty && segments.last == fileName;
  });
  if (alreadyLoaded) {
    // Before the bundle has run there is no hook yet; the load callback below
    // signals instead, as long as no logout disarms it first.
    _signalWidgetReady();
    return false;
  }

  final splashRemover = _getGlobal(_splashHook);
  final script = html.ScriptElement()
    ..src = src
    ..defer = true;
  script.onLoad.first.then((_) {
    final installed = _getGlobal(_splashHook);
    if (installed != null && !identical(installed, splashRemover)) {
      _widgetReadyHook = installed;
      _setGlobal(_splashHook, splashRemover);
    }
    if (_armed) {
      _signalWidgetReady();
    } else {
      // A logout landed while the bundle was downloading. Its session-ended
      // event fired before the widget was listening, so repeat it now: the
      // widget then stays suppressed (no card, no login bridge) until the next
      // authenticated session re-arms it.
      _dispatchSessionEnded();
    }
  });
  html.document.head!.append(script);
  return true;
}

/// Called on logout: a bundle still downloading must not re-arm the widget.
void disarmInjectedRouterAiBundle() {
  _armed = false;
}

void _signalWidgetReady() {
  final hook = _widgetReadyHook;
  if (hook == null || !_armed) return;
  try {
    js_util.callMethod<void>(hook, 'call', [html.window]);
  } catch (_) {
    // The widget is optional; a failing hook must never affect the GUI.
  }
}

void _dispatchSessionEnded() {
  try {
    html.window.dispatchEvent(html.CustomEvent(_sessionEndedEvent));
  } catch (_) {
    // The widget is optional; never let it affect the GUI.
  }
}

Object? _getGlobal(String name) {
  try {
    return js_util.hasProperty(html.window, name)
        ? js_util.getProperty<Object?>(html.window, name)
        : null;
  } catch (_) {
    return null;
  }
}

void _setGlobal(String name, Object? value) {
  try {
    js_util.setProperty(html.window, name, value);
  } catch (_) {
    // Leave the page as it is rather than break the GUI.
  }
}

/// Test-only: forget the held hook and armed state between browser tests.
void resetRouterAiLoaderForTest() {
  _widgetReadyHook = null;
  _armed = false;
}
