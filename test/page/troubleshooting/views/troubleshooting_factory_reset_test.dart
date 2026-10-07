// Troubleshooting's Factory Reset, which writes without a Save bar.
//
// It is offered only to a local login. This pins that a local login with full
// access is offered it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

class _IdleTroubleshooting extends TroubleshootingNotifier {
  @override
  Future fetch({bool force = false}) async {}
}

class _LocalAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      AuthState.empty().copyWith(loginType: LoginType.local);
}

void main() {
  mockDependencyRegister();

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // The page reads the login type once, so it has to be settled before the
    // page builds - as it is in the app, where login precedes this page.
    final container = ProviderContainer(overrides: [
      troubleshootingProvider.overrideWith(() => _IdleTroubleshooting()),
      authProvider.overrideWith(() => _LocalAuth()),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      locale: const Locale('en'),
      child: const TroubleshootingView(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a local login is offered Factory Reset', (tester) async {
    await pumpPage(tester);

    expect(find.text('Factory Reset'), findsOneWidget);
  });
}
