import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';

/// Extracts the output Map from polling data for a specific action.
Map<String, dynamic>? getPollingOutput(
  CoreTransactionData? data,
  JNAPAction action,
) {
  return _getPollingSuccess(data, action)?.output;
}

/// Safely extracts a successful result for a specific action from polling data.
///
/// Returns null if the data is null, the action is not found, or the result
/// is not a JNAPSuccess (e.g., it's a JNAPError).
JNAPSuccess? _getPollingSuccess(
  CoreTransactionData? data,
  JNAPAction action,
) {
  if (data == null) return null;
  final result = data.data[action];
  return result is JNAPSuccess ? result : null;
}
