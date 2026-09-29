import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_type_label.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A prominent banner at the top of the Internet Settings page.
///
/// Displays current connection type, WAN IP address, status indicator,
/// and an edit icon button for entering/exiting edit mode.
///
/// The toggle is rendered only when [onEditToggle] is non-null. A `null` is how a
/// read-only surface (Remote Assistance, #1626) says there is no edit mode to
/// enter — an [AppIconButton] with a `null` `onTap` would still be drawn, as a
/// disabled pencil that invites a tap and explains nothing.
class UspConnectionStatusBanner extends StatelessWidget {
  final InternetSettingsFeatureState state;
  final bool isEditing;
  final VoidCallback? onEditToggle;

  const UspConnectionStatusBanner({
    super.key,
    required this.state,
    required this.isEditing,
    this.onEditToggle,
  });

  @override
  Widget build(BuildContext context) {
    final connectionType = state.connectionType;
    final wanIp = state.readOnlyInfo.staticIpAddress;
    final isConnected = wanIp.isNotEmpty;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Status indicator
            UspStatusDot(isActive: isConnected, size: 12),
            AppGap.md(),
            // Connection info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(
                    connectionType.localizedLabel(context),
                  ),
                  AppGap.xs(),
                  AppText.bodySmall(
                    isConnected ? wanIp : '--',
                  ),
                ],
              ),
            ),
            // Edit / Close toggle. `internet-settings-edit-toggle` doubles as the
            // E2E hook for this page (P07, F04, and F07 via the card-nav fixture —
            // all built with `force="local"`); a Remote Assistance spec needs a
            // different one, since it is absent there by design.
            if (onEditToggle case final onTap?)
              AppIconButton(
                icon: Icon(isEditing ? AppFontIcons.close : AppFontIcons.edit),
                semanticLabel:
                    isEditing ? loc(context).close : loc(context).edit,
                identifier: 'internet-settings-edit-toggle',
                onTap: onTap,
              ),
          ],
        ),
      ),
    );
  }
}
