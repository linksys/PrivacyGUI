import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/util/masking_utils.dart';

/// A [ProviderObserver] that records the latest state of watched providers
/// into the state log cache for diagnostics.
///
/// Only tracks state types that implement [DiagnosticLoggable] with
/// [DiagnosticLoggable.loggable] set to `true`.
/// Each provider keeps only its most recent state (overwrites on update).
///
/// States are NOT written to the main log stream — they are only captured
/// in [_stateLogCache] and included when the user downloads the diagnostic
/// report via [outputFullWebLog].
class StateLogObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Extract value from AsyncValue or use directly for sync providers
    Object? value;
    if (newValue is AsyncValue) {
      if (!newValue.hasValue) return;
      value = newValue.value;
    } else {
      value = newValue;
    }

    if (value == null) return;

    // Only capture types that implement DiagnosticLoggable with loggable=true
    if (value is! DiagnosticLoggable) return;
    if (!value.loggable) return;

    final typeName = value.diagnosticName;
    final jsonState = value.toString();

    // Apply masking before caching — diagnostic reports are user-downloadable
    final maskedState = MaskingUtils.maskSensitiveJsonValues(
        MaskingUtils.maskSerialNumber(MaskingUtils.maskMacAddress(jsonState)));

    // Update cache — will be included in diagnostic report on download
    updateStateLog(typeName, maskedState);
  }
}
