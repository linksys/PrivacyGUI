import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';

/// Executes a USP mutation with loading state management and error handling.
///
/// Sets [uspMutationLoadingProvider] to [loadingKey] before the mutation,
/// resets it to null afterward, and shows snackbar on success/failure.
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
      showFailedSnackBar(context, 'Error: $e');
    }
  } finally {
    ref.read(uspMutationLoadingProvider.notifier).state = null;
  }
}
