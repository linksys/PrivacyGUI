import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/wan_ip_reading.dart';
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
///
/// ⚠️ This banner infers online/offline from the address being non-empty, while
/// `usp_network_status_card.dart` uses `wan.isUp`. The two disagree while a link is up
/// with no address yet. Predates this change, tracked in #1620 — it needs one definition
/// for the app, which is a product decision rather than a read-source change.
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
    // Three states, kept apart by `wanIpReadingProvider` rather than flattened here —
    // see that provider for why (#1613).
    //
    // NOT an early-return skeleton for the unknown state, though the dashboard's
    // `UspNetworkStatusCard` does that for `wan == null`: this banner hosts the page's
    // edit toggle, and `internet-settings-edit-toggle` is the arrival hook R01 and R20
    // depend on. The unknown state degrades the reading and keeps the control.
    final reading = ref.watch(wanIpReadingProvider);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // `isOnline`, not `!isOffline`, so `unknown` claims neither. Offline and
            // unknown deliberately share the dim dot (decided 2026-09-24): a third dot
            // state needs a colour and a meaning the design system does not have, and the
            // address line below already separates the two. The dot reads "not confirmed
            // online", true of both.
            UspStatusDot(isActive: reading.isOnline, size: 12),
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
                  // '--' means the device said there is no address; `unknown` means we
                  // could not ask it. Rendering both as '--' was the #1613 defect.
                  AppText.bodySmall(switch (reading) {
                    WanIpAddress(:final value) => value,
                    WanIpNone() => '--',
                    WanIpUnknown() => loc(context).unknown,
                  }),
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
