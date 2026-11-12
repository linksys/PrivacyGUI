import 'package:privacy_gui/constants/build_config.dart';

import 'router_ai_loader_stub.dart'
    if (dart.library.html) 'router_ai_loader_web.dart' as impl;

/// Root-relative path of the widget bundle owned by the router's optional
/// `ai-msdm-web` package. Root-relative so it is independent of the Flutter
/// base href. The bundle is never copied into or compiled with PrivacyGUI.
const routerAiBundlePath = '/ai/linksys-ai.js';

/// Adds the deferred Router AI loader to the page when, and only when, the
/// build enables Router AI (`--dart-define=enable_router_ai=true`). A default
/// build never references the bundle, so a router without the package sees no
/// request for it.
///
/// Returns true only if a script element was added by this call.
bool loadRouterAiBundle() {
  if (!BuildConfig.enableRouterAi) return false;
  return impl.injectRouterAiBundle(routerAiBundlePath);
}
