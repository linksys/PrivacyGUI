// Troubleshooting's Factory Reset, which writes without a Save bar.
//
// It is offered only to a local login, which a read-only build can also have -
// the flag is independent of how the user signed in. So a read-only build hides
// it even there.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';

import '../../../common/di.dart';
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

  Future<void> pump(WidgetTester tester, {required bool readOnly}) async {
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // The page reads the login type once, so it has to be settled before the
    // page builds - as it is in the app, where login precedes this page.
    final container = ProviderContainer(overrides: [
      readOnlyModeProvider.overrideWithValue(readOnly),
      troubleshootingProvider.overrideWith(() => _IdleTroubleshooting()),
      authProvider.overrideWith(() => _LocalAuth()),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      child: const TroubleshootingView(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a local login is offered Factory Reset', (tester) async {
    await pump(tester, readOnly: false);
    expect(find.text('Factory Reset'), findsOneWidget);
  });

  testWidgets('a read-only build hides it even for a local login',
      (tester) async {
    await pump(tester, readOnly: true);
    expect(find.text('Factory Reset'), findsNothing);
  });
}
