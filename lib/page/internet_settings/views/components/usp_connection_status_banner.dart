import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_type_label.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A prominent banner at the top of the Internet Settings page.
///
/// Displays current connection type, WAN IP address, status indicator,
/// and an edit icon button for entering/exiting edit mode.
///
/// WHY THE ADDRESS COMES FROM L1 AND THE TYPE DOES NOT (#1587 Phase 2).
///
/// The test is "can the user edit this value?" — if not, it does not belong to the
/// page's L2 working copy:
///
///   connectionType   editable on this page  → L2 (`state`), so it tracks the form
///   WAN IP address   read-only              → L1 (`wanDataProvider`), so it is live
///
/// It used to read `state.readOnlyInfo.staticIpAddress`. L2 is snapshotted when the
/// page opens and deliberately does not change underneath the user, so the address
/// froze at whatever it was on entry. Measured on real hardware: with the WAN taken
/// down over SSH, the dashboard dropped the address within a minute while this banner
/// still showed it 120 seconds later — see linksys/PrivacyGUI-RealRouter-E2E's
/// `R20-sse-push.spec.ts`.
///
/// `wanDataProvider` is the right source rather than merely a fresher one: it reads
/// the SAME TR-181 parameter (`Device.IP.Interface.{wan}.IPv4Address.1.IPAddress`,
/// with the instance resolved by Alias in both cases), and it already listens for
/// `InvalidationDomain.wanStatus` so a push refreshes it.
///
/// The alternative — giving the notifier an `onSseInvalidation()` listener — was
/// rejected in #1587: the dirty guard skips the refresh exactly when the page is
/// dirty, which is the one state where stale values get written back on save.
class UspConnectionStatusBanner extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionType = state.connectionType;
    // `valueOrNull` rather than a `when`: while L1 is loading for the first time this
    // renders '--' and a dim dot, which is what an unknown address should look like.
    // During an SSE-triggered refresh riverpod preserves the previous value, so the
    // address does not blink back to '--' on every notification.
    final wanIp = ref.watch(wanDataProvider).valueOrNull?.model.ipAddress ?? '';
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
            // Edit / Close toggle
            AppIconButton(
              icon: Icon(isEditing ? AppFontIcons.close : AppFontIcons.edit),
              semanticLabel: isEditing ? loc(context).close : loc(context).edit,
              identifier: 'internet-settings-edit-toggle',
              onTap: onEditToggle,
            ),
          ],
        ),
      ),
    );
  }
}
