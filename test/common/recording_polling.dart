import 'dart:async';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Polling as a provider under test meets it: [data] is its last poll, and it
/// counts what it is told to do instead of doing it.
///
/// It never polls, so no timer outlives a test and no poll reaches the router.
/// The real start-up, forced poll and hold are polling_provider's to test;
/// wifi_save_side_effect_test runs them for real beside a save.
class RecordingPolling extends PollingNotifier {
  RecordingPolling([this.data = const {}]);

  final Map<JNAPAction, JNAPResult> data;
  int stopped = 0;
  int started = 0;
  int forced = 0;

  @override
  FutureOr<CoreTransactionData> build() =>
      CoreTransactionData(lastUpdate: 1, isReady: true, data: data);

  @override
  stopPolling() {
    stopped++;
  }

  @override
  startPolling() {
    started++;
  }

  @override
  Future forcePolling() async {
    forced++;
  }
}
