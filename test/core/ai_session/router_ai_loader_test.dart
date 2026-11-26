// loadRouterAiBundle in a default build (`enable_router_ai` off). The non-web
// loader under it is router_ai_loader_stub_test.dart, the web loader
// router_ai_loader_web_test.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/ai_session/router_ai_loader.dart';

void main() {
  test('a default build does not enable Router AI', () {
    expect(BuildConfig.enableRouterAi, isFalse);
  });

  test('in a default build, loading says it added no script, and disarming '
      'returns', () {
    expect(loadRouterAiBundle(), isFalse);
    expect(disarmRouterAiBundle, returnsNormally);
  });

  test('the providers AuthNotifier calls are the loader and its disarm', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routerAiLoaderProvider), same(loadRouterAiBundle));
    expect(container.read(routerAiDisarmProvider), same(disarmRouterAiBundle));
  });
}
