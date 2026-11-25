// loadRouterAiBundle in a default build (`enable_router_ai` off), and the
// non-web loader under it. The web loader is router_ai_loader_web_test.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader_stub.dart'
    as off_the_web;

void main() {
  test('a default build does not enable Router AI', () {
    expect(BuildConfig.enableRouterAi, isFalse);
  });

  test('a default build never loads the widget, and has none to disarm', () {
    expect(loadRouterAiBundle(), isFalse);
    expect(disarmRouterAiBundle, returnsNormally);
  });

  test('the providers AuthNotifier calls are the loader and its disarm', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routerAiLoaderProvider)(), isFalse);
    expect(container.read(routerAiDisarmProvider), returnsNormally);
  });

  test('off the web, there is no page to load the widget into', () {
    expect(off_the_web.injectRouterAiBundle(routerAiBundlePath), isFalse);
    expect(off_the_web.disarmInjectedRouterAiBundle, returnsNormally);
  });
}
