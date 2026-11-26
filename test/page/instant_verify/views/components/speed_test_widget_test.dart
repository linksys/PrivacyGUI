// Instant Verify's speed test card: when it says the last test ran. Before a
// new test, the card shows the latest result the poll reports.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_verify/views/components/speed_test_widget.dart';

import '../../../../common/di.dart';
import '../../../../common/recording_polling.dart';
import '../../../../common/testable_widget.dart';

/// `GetHealthCheckResults` with one speed test, run at 12:30 UTC.
const _healthCheckResults = JNAPSuccess(result: 'OK', output: {
  'healthCheckResults': [
    {
      'resultID': 30736,
      'timestamp': '2026-01-05T12:30:00Z',
      'healthCheckModulesRequested': ['SpeedTest'],
      'speedTestResult': {
        'resultID': 30736,
        'exitCode': 'Success',
        'serverID': '3967',
        'latency': 1,
        'uploadBandwidth': 91267,
        'downloadBandwidth': 97412,
      },
    },
  ],
});

void main() {
  mockDependencyRegister();

  // The router's timestamps are ISO 8601, on a 24-hour clock. The card shows
  // the time in the browser's time zone, so the text is that instant, local.
  testWidgets(
      "shows the last test, run in the 12 o'clock hour, at the time "
      'it ran', (tester) async {
    tester.view.physicalSize = const Size(1440, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(testableWidget(
      overrides: [
        pollingProvider.overrideWith(() => RecordingPolling({
              JNAPAction.getHealthCheckResults: _healthCheckResults,
            })),
      ],
      locale: const Locale('en'),
      child: const SingleChildScrollView(child: SpeedTestWidget()),
    ));
    await tester.pump();

    final ranAt = DateTime.utc(2026, 1, 5, 12, 30).toLocal();
    final shown = tester
        .widget<Text>(find.descendant(
          of: find.byKey(const ValueKey('speedTestDateTime')),
          matching: find.byType(Text),
        ))
        .data;
    expect(shown,
        '${DateFormat.yMd('en').format(ranAt)} ${DateFormat.jms('en').format(ranAt)}');
  });
}
