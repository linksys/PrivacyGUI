// Troubleshooting's Ping page, which follows the router's ping status.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/ping_status.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/troubleshooting/_troubleshooting.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// A router whose ping status cannot be read once, part way through.
class _PingWithOneFailedRead extends TroubleshootingNotifier {
  @override
  Future ping({required String host, required int? pingCount}) async {}

  @override
  Stream<PingStatus> getPingStatus() async* {
    yield const PingStatus(isRunning: true, pingLog: 'PING linksys.com');
    yield* Stream.error(const JNAPError(result: 'ErrorUnknown'));
    yield const PingStatus(
        isRunning: false, pingLog: 'PING linksys.com\n64 bytes\ndone');
  }
}

void main() {
  mockDependencyRegister();

  testWidgets('keeps showing the ping past a status it cannot read',
      (tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(overrides: [
      troubleshootingProvider.overrideWith(() => _PingWithOneFailedRead()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(testableSingleRoute(
      provider: container,
      locale: const Locale('en'),
      child: const TroubleshootingPingView(),
    ));
    await tester.pumpAndSettle();

    // The host field; the count dropdown has a text field of its own.
    await tester.enterText(find.byType(TextField).first, 'linksys.com');
    await tester.tap(find.text('Ping'));
    await tester.pumpAndSettle();

    expect(find.textContaining('done'), findsOneWidget);
  });
}
