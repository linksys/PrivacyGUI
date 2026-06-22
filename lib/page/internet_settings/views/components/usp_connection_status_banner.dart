import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A prominent banner at the top of the Internet Settings page.
///
/// Displays current connection type, WAN IP address, status indicator,
/// and an edit icon button for entering/exiting edit mode.
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
                    _connectionTypeLabel(context, connectionType),
                  ),
                  AppGap.xs(),
                  AppText.bodySmall(
                    isConnected ? wanIp : '--',
                  ),
                ],
              ),
            ),
            // Edit / Close toggle
            AppIconButton(
              icon: Icon(isEditing ? AppFontIcons.close : AppFontIcons.edit),
              onTap: onEditToggle,
            ),
          ],
        ),
      ),
    );
  }

  String _connectionTypeLabel(BuildContext context, UspWanConnectionType type) {
    final l = loc(context);
    return switch (type) {
      UspWanConnectionType.dhcp => l.connectionTypeDhcp,
      UspWanConnectionType.staticIp => l.staticIp,
      UspWanConnectionType.pppoe => l.connectionTypePppoe,
      UspWanConnectionType.bridge => l.connectionTypeBridge,
    };
  }
}
