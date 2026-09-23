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
///
/// ⚠️ KNOWN INCONSISTENCY WITH THE DASHBOARD CARD, LEFT AS IT WAS.
/// `usp_network_status_card.dart` renders online/offline from `wan.isUp` (the TR-181
/// `Status` field); this banner infers it from the address being non-empty. The two
/// disagree while a link is UP BUT HAS NO ADDRESS YET — mid-DHCP, mid-PPPoE — where the
/// card says Online and this says offline.
///
/// That predates this change: the banner drew the same inference from
/// `readOnlyInfo.staticIpAddress`. It is deliberately not fixed here, because switching
/// to `isUp` would change BEHAVIOUR while this change is only about where the value is
/// read from, and "what should a connecting link look like" is a product question. Both
/// now read the same provider, which is what makes the difference easy to close later.
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
    final wanAsync = ref.watch(wanDataProvider);
    final wanIp = wanAsync.valueOrNull?.model.ipAddress ?? '';

    // UNKNOWN IS NOT OFFLINE. `valueOrNull` is null for three different states, and
    // reading the dot straight off `wanIp.isNotEmpty` claimed "disconnected" for all
    // three — including `AsyncError`, which is reachable on an ordinary path:
    // `uspWanDataServiceProvider` throws `ServiceNotInitializedError` whenever
    // `uspClientProvider` is null (session not yet established, re-auth, dropped
    // socket), and any transport failure inside `fetch()` arrives as a `ServiceError`.
    // Measured: that state rendered a dim dot and '--' with no error surfaced, and
    // because this provider is not autoDispose and has no retry, it stayed that way
    // until a `wanStatus` push or a save happened to invalidate it.
    //
    // `hasValue` is the discriminator, not `hasError`: during a refresh riverpod keeps
    // the previous value (measured — an external `ref.invalidate` from a save or DHCP
    // renew yields `isLoading: true, hasValue: true` carrying the old address), so
    // `hasValue` covers "settled" and "refreshing with a value" and excludes only the
    // two states where we genuinely do not know.
    //
    // WHY THIS IS NOT AN EARLY-RETURN SKELETON, even though the dashboard's
    // `UspNetworkStatusCard` does exactly that for `wan == null`. This banner also hosts
    // the page's edit toggle, whose identifier `internet-settings-edit-toggle` is the
    // arrival hook two real-router specs depend on (`R01-boot-smoke` asserts the page was
    // reached by it; `R20-sse-push` waits on it). Replacing the banner with a skeleton
    // takes that control off the page — and in the `AsyncError` case it never comes back,
    // because this provider has no retry. So the unknown state degrades the READING and
    // keeps the CONTROL.
    final isKnown = wanAsync.hasValue;
    final isConnected = isKnown && wanIp.isNotEmpty;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Status indicator. `isActive` is false for both "offline" and "unknown";
            // the address line below is what distinguishes them, and a third dot state
            // is a design question rather than something to invent here.
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
                  // Three readings, not two: an address, a known-empty address, and
                  // "we could not read it". The third used to render as '--', which is
                  // what a genuinely absent address looks like — so a failed read was
                  // indistinguishable from a successful read of "no address".
                  AppText.bodySmall(
                    !isKnown
                        ? loc(context).unknown
                        : isConnected
                            ? wanIp
                            : '--',
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
