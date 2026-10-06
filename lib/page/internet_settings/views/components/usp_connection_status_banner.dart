import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/wan_ip_reading.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
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
/// rejected in #1587 and that hook has since been DELETED (Phase 1): its dirty guard
/// skipped the refresh exactly when the page was dirty, which is the one state where
/// stale values get written back on save. It protected the harmless case and stepped
/// aside from the harmful one.
///
/// THE DOT AND THE ADDRESS ARE TWO QUESTIONS (#1620). The dot reads `wanIsUpProvider`
/// — `Status == 'Up'`, the app's one definition of online — and the address line reads
/// `wanIpReadingProvider`. This banner used to infer online from the address being
/// non-empty, which made it disagree with the dashboard for about 5 seconds after every
/// link recovery (measured: `Status` reads `Up` while the address is still arriving).
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
            // THE DOT READS THE LINK, THE LINE BELOW READS THE ADDRESS, and they are
            // deliberately different questions (#1620).
            //
            // The dot used to come from `reading.isOnline` — address non-empty — which
            // made this banner disagree with the dashboard for about 5 seconds after
            // every link recovery, measured on real hardware: `Status` reads `Up` while
            // the address is still arriving. Same router, same moment, two answers one
            // click apart. The dot now reads `wanIsUpProvider`, the app's one definition.
            //
            // `?? true`, the same as the dashboard — and the same for the same reason
            // (#1143): an unread L1 is not a disconnection, and rendering one as a dim
            // dot states a fact about the router that nobody has checked.
            //
            // An earlier version of this change wrote `?? false` here, reasoning that a
            // dim dot matches the "unknown" the address line shows one row below. That
            // reads well and is still wrong: it makes this screen pessimistic while the
            // dashboard is optimistic, which is a second axis of disagreement to
            // replace the one #1620 removed. The line below already says "unknown" in
            // words; the dot does not need to contradict the dashboard to say it twice.
            //
            // Offline and unknown therefore no longer share the dim dot — unknown
            // shares the ON dot with online, and the words carry the distinction. That
            // supersedes the 2026-09-24 note about a third dot state: the question was
            // never "which of three colours", it was "who decides when we do not know",
            // and the answer is the whole app, consistently.
            UspStatusDot(
                isActive: ref.watch(wanIsUpProvider) ?? true, size: 12),
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
            // Edit / Close toggle. `internet-settings-edit-toggle` doubles as the
            // E2E hook for this page in two repos — PrivacyGUI-USP-E2E (P07, F04,
            // and F07 via the card-nav fixture) and PrivacyGUI-RealRouter-E2E (R01,
            // R20), all built with `force=local`; a Remote Assistance spec needs a
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
