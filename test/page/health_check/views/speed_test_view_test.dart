// The Speed Test page: when it says the last test ran.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/health_check_provider_mocks.dart';
import '../../../test_data/health_check_state_data.dart';

void main() {
  mockDependencyRegister();

  late MockHealthCheckProvider healthCheck;

  setUp(() => healthCheck = MockHealthCheckProvider());

  // The router's timestamps are ISO 8601, on a 24-hour clock. The page shows
  // the time in the browser's time zone, so the text is that instant, local.
  testWidgets("shows a test run in the 12 o'clock hour at the time it ran",
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(healthCheck.build()).thenReturn(HealthCheckState.fromJson(
        healthCheckStateSuccessGood.replaceAll(
            '2024-06-24T09:20:09Z', '2026-01-05T12:30:00Z')));

    await tester.pumpWidget(testableSingleRoute(
      overrides: [healthCheckProvider.overrideWith(() => healthCheck)],
      locale: const Locale('en'),
      child: const SpeedTestView(),
    ));
    await tester.pump(const Duration(seconds: 2));

    final ranAt = DateTime.utc(2026, 1, 5, 12, 30).toLocal();
    final shown = [
      for (final text in tester.widgetList<Text>(find.byType(Text)))
        if (text.data?.startsWith('As of ') ?? false) text.data,
    ];
    expect(shown, [
      'As of ${DateFormat.jm('en').format(ranAt)} '
          '${DateFormat.yMMMd('en').format(ranAt)}',
    ]);
  });
}
