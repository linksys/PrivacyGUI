import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';

/// Tracks which card is currently being mutated (for loading overlay).
/// Values: null (idle), 'wifi', 'time', 'portForwarding', 'portTriggering', etc.
final uspMutationLoadingProvider = StateProvider<String?>((ref) => null);

/// Executes a USP mutation with loading state management and error handling.
///
/// Sets [uspMutationLoadingProvider] to [loadingKey] before the mutation,
/// resets it to null afterward, and shows a snackbar on success/failure.
///
/// On failure the caught error is localized via [localizeServiceError] (the
/// same central mapper used by feature views) — so callers do NOT need to
/// localize themselves; just pass the mutation. Note [successMessage] is shown
/// as-is, so callers should pass an already-localized string.
Future<void> performUspMutation(
  BuildContext context,
  WidgetRef ref, {
  required String loadingKey,
  required Future<void> Function() mutation,
  String? successMessage,
}) async {
  ref.read(uspMutationLoadingProvider.notifier).state = loadingKey;
  try {
    await mutation();
    if (successMessage != null && context.mounted) {
      showSuccessSnackBar(context, successMessage);
    }
  } catch (e) {
    if (context.mounted) {
      showFailedSnackBar(context, localizeServiceError(context, e));
    }
  } finally {
    ref.read(uspMutationLoadingProvider.notifier).state = null;
  }
}
