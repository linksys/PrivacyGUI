import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// "Do not power off the router" — true of an install however it was started.
///
/// Shared rather than copied for the reason the copy itself gives: it states how
/// long a flash takes and what not to do while it runs, and #1549 gave the user
/// two ways to start the same flash. One of the two pages quietly losing this
/// warning is the failure worth designing against.
class FirmwareUpdateWarningNote extends StatelessWidget {
  const FirmwareUpdateWarningNote({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: scheme.outline),
        AppGap.sm(),
        Expanded(
          child: AppText.bodySmall(
            loc(context).firmwareUpdateWarning,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }
}
