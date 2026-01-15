import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_helpers.dart';

/// Provides the router's local time as milliseconds since epoch.
///
/// Extracts the current time from polling data for getLocalTime action.
/// Falls back to the current system time if unable to retrieve router time.
final routerTimeProvider = Provider<int>((ref) {
  final pollingData = ref.watch(pollingProvider).value;

  final timeOutput = getPollingOutput(pollingData, JNAPAction.getLocalTime);
  if (timeOutput != null) {
    final timeString = timeOutput['currentTime'] as String?;
    if (timeString != null) {
      final parsedTime =
          DateFormat("yyyy-MM-ddThh:mm:ssZ").tryParse(timeString);
      if (parsedTime != null) {
        return parsedTime.millisecondsSinceEpoch;
      }
    }
  }

  return DateTime.now().millisecondsSinceEpoch;
});
