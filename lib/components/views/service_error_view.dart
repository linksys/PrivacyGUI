import 'package:flutter/material.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared fetch-failure empty state.
///
/// Replaces the per-feature private `_buildError` methods. Shows a localized
/// title, the localized [ServiceError] detail (via [localizeServiceError]),
/// and a retry button.
class ServiceErrorView extends StatelessWidget {
  /// The error to display. When null, only the generic title is shown.
  final ServiceError? error;

  /// Called when the user taps retry (e.g. re-fetch with forceRemote).
  final VoidCallback onRetry;

  const ServiceErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message =
        error != null ? localizeServiceError(context, error!) : null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium(loc(context).failedToLoadSettings),
          if (message != null) ...[
            AppGap.sm(),
            AppText.bodyMedium(message),
          ],
          AppGap.md(),
          AppButton(
            label: loc(context).retry,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
