import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';

import 'router_ai_loader_stub.dart'
    if (dart.library.html) 'router_ai_loader_web.dart' as impl;

/// Root-relative path of the widget bundle owned by the router's optional
/// `ai-msdm-web` package. Root-relative so it is independent of the Flutter
/// base href. The bundle is never copied into or compiled with PrivacyGUI.
const routerAiBundlePath = '/ai/linksys-ai.js';

/// Shows the Router AI widget when, and only when, the build enables Router AI
/// (`--dart-define=enable_router_ai=true`). A default build never references
/// the bundle, so a router without the package sees no request for it.
///
/// Call this only after the router login has succeeded AND the AI session is
/// authenticated. The widget must never appear on the login screen, so it is
/// not loaded at startup: before login the page has no widget, no chat bubble
/// and no manual-login card.
///
/// The first call adds the deferred loader. A later call (a fresh login in the
/// same tab after a logout) re-arms the already-loaded widget, which the
/// logout's `linksys-ai-session-ended` event had suppressed.
///
/// Returns true only if a script element was added by this call.
bool loadRouterAiBundle() {
  if (!BuildConfig.enableRouterAi) return false;
  return impl.injectRouterAiBundle(routerAiBundlePath);
}

/// Indirection so tests can observe when, and whether, AuthNotifier shows the
/// widget without a browser.
final routerAiLoaderProvider =
    Provider<bool Function()>((ref) => loadRouterAiBundle);
