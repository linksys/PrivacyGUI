import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/dashboard/models/card_density.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';
import 'package:privacy_gui/page/devices/views/components/usp_signal_strength_indicator.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';

/// Card content width at which the two status counts stop sitting side by side.
///
/// Side by side, each count gets `(content − 8) / 2` of block and `− 24` of
/// padding inside that. The pair has to hold a dot (10px), an 8px gap, the
/// count, a 4px gap and the word — and the binding locale is `el`, whose
/// «Χωρίς σύνδεση» needs **116.7px** all in (`en` needs 66.8px, `zh` 52.2px).
/// Side by side therefore needs `2 × (116.7 + 24) + 8` = **289.4px** of content,
/// which neither narrow realization has: a 191px card gives 157.4px (50.7px per
/// block, so the widest 15 locales overflow by +14px to +66px) and a 288px card
/// gives 254px (99.0px per block, which is where `el`'s single
/// `preferred|0` coordinate comes from, +18px).
///
/// Stacked, each block gets the full 133.4px of inner width at 191px and 230px
/// at 288px, so every locale fits unbroken with 16.7px to spare in the worst
/// case.
///
/// ## 297, not the 296 that shipped with #1238
///
/// #1238 read the 6.6px between 289.4 and 296 as slack, on the grounds that "the
/// realized content widths either side are 254px and ~600px, so nothing lands
/// within 200px of it". Both halves of that were wrong, and #1289's 1px × 26
/// locale sweep of the card is what caught it:
///
///   - the derivation was 6.9px optimistic. At content 296 — the trigger width
///     itself — `el` overflows its half by **0.264px**. So the true demand is
///     296.264 and 296 was not slack but a knife edge landed on exactly.
///   - the *realizations* are 200px apart; the *widths* are not. A user drags a
///     card to any span the grid offers, and a 3-column span on a 700px screen
///     is 228.5px. 330px — where this fires — is an ordinary width.
///
/// Raised to the widest failing width + 1, which is how every other threshold in
/// this file was derived. The half grows 0.5px per content px, so 297 seats the
/// Greek pair with 0.236px to spare — thin, and deliberately the same kind of thin
/// as [_kSignalLabelContentMinWidth]'s 231 (clean at +0.287px over its own 230).
///
/// Not caused by the density work and not fixed by it: nothing here reads
/// [CardDensity], so this half-pixel was live in the normal form from #1238
/// onward. The #1183 gate could not see it — 0.264px is inside its 2.0px
/// tolerance, and it never pumps 330px anyway (#1289).
const double _kStatusCountsSideBySideMinWidth = 297;

/// Widest the parent-node badge may draw, label and padding included.
///
/// Shared by the badge itself and by [_nodeBadgeNaturalWidth], which decides
/// whether it is drawn at all — the two must agree or the badge is measured at a
/// width it cannot have.
const double _kNodeBadgeMaxWidth = 100;

/// Card content width at which the signal indicator can carry its `-NN dBm`
/// label.
///
/// The indicator is 4 fixed-width bars, 3 gaps, a 4px gap and an unwrapped
/// `AppText`, so it holds its natural width at any box width and cannot yield:
/// **80.8px** at the widest reading (`-100 dBm`, 3 digits), 75.0px at a 2-digit
/// one, 22.0px with the label suppressed.
///
/// ## Where 231 comes from
///
/// `ListTileContentLayout` divides the row, not the card: it reserves 25% of the
/// row for the content column and splits the rest in two, then lends each side
/// whatever the other did not want. With the tile's 32px of padding and its two
/// 16px gaps that makes
///
///     available    = content − 64
///     share        = 0.375 × available
///     trailingCap  = share + max(0, share − 44)        // 44px leading icon
///
/// so once `share ≥ 44` the trailing gets `0.75 × available − 44`, and seating
/// the 80.8px reading needs `content ≥ 64 + (80.8 + 44) / 0.75` = **230.4px**.
/// Measured on the fixture, and this is the whole reason the number is not lower:
///
///     content 157.4 (min realization)  cap 35.0   label suppressed, clean
///     content 229                      cap 79.8   +1.0px right
///     content 230                      cap 80.5   +0.287px right
///     content 231                      cap 81.3   clean
///     content 254.0 (preferred)        cap 98.5   clean
///
/// The gate only ever pumps the *narrowest* realization of each span — 157.4px
/// and 254.0px — so every width in between is invisible to it, and a threshold
/// derived from the 25% floor alone (174.7px) is green on the gate and overflows
/// by up to +33px on a card the user can actually drag to. `connected_devices`
/// readability tests pump those in-between widths for exactly this reason.
///
/// ## Why this is decided from the card and not from the slot
///
/// ui_kit v2.34.10 caps the trailing slot instead of laying it out at
/// `maxWidth: Infinity` (linksys/privacyGUI-UI-kit#20), which is what makes a
/// `LayoutBuilder` in that slot legal at all — and the tile's overflow grew from
/// +25.6px to +40.0px on the bump because the shortfall is now reported against
/// that cap instead of being absorbed by starving the title column to 0px.
///
/// But the cap is a *lend-back* of what the other slots did not want, so it is
/// not a budget the row can read: measured on the dashboard fixture at a 512px
/// card, `iPhone-15` was handed 75.0px and `MacBook-Air` — same badge, same
/// indicator, longer name — 64.8px, and `Smart-Speaker` 22.0px. Gating the label
/// on the slot therefore deletes the reading on a 1440px screen for the rows with
/// the longest names, while the row above keeps one, for a reason the user cannot
/// see. The card's content width is the same for every row, so this is decided
/// once, here (#1238).
const double _kSignalLabelContentMinWidth = 231;

/// How wide the parent-node badge would draw for [nodeName] if nothing
/// constrained it: its `labelSmall` label plus the badge's own padding, capped at
/// [_kNodeBadgeMaxWidth].
///
/// The badge ellipsizes, so a slot narrower than this does not overflow — it just
/// stops naming anything. Measuring the label is what lets the badge be dropped
/// exactly when it cannot be shown whole, rather than at some width threshold:
/// the trailing slot's width is what this row asked for, so a two-letter node
/// name is granted the ~30px it wants at every card width. At the narrowest card
/// `Extender-1` wants 78.3px and the slot offers 35.0px, while `N1` wants 30.1px
/// and is handed all of it — so any constant floor high enough to reject the
/// first would also reject the second, which fits everywhere (#1238).
double _nodeBadgeNaturalWidth(BuildContext context, String nodeName) {
  final painter = TextPainter(
    text: TextSpan(
      text: nodeName,
      // ui_kit's own resolver, not `textTheme.labelSmall` — `AppText` draws with
      // this and it is not the raw theme style: it re-applies the design theme's
      // `bodyFontFamily` bare (dropping the `packages/ui_kit_library/` prefix the
      // theme carries) and prepends the locale fallback family. Measuring with
      // the theme style measures a node name in a font the badge will not use,
      // which for a CJK or Greek name is a different width.
      style: AppTextVariant.labelSmall.resolve(context),
    ),
    textDirection: Directionality.of(context),
    // The badge scales with the platform text size; the measurement has to too.
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = math.min(
    painter.width + AppSpacing.sm * 2,
    _kNodeBadgeMaxWidth,
  );
  // This runs inside a `LayoutBuilder.builder`, once per device row per layout
  // pass, so the paragraph handle has to be released here rather than left to
  // the finalizer.
  painter.dispose();
  return width;
}

class UspConnectedDevicesCard extends ConsumerWidget {
  final List<ClientDevice>? devices;

  const UspConnectedDevicesCard({
    super.key,
    this.devices,
  });

  static const _maxDisplayCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final devices = this.devices ?? devicesData?.clientDevices;
    if (devices == null) return const CardSkeleton.list(rows: 3);
    final activeDevices = devices.where((d) => d.isActive).toList();
    final inactiveDevices = devices.where((d) => !d.isActive).toList();
    final displayDevices = activeDevices.take(_maxDisplayCount).toList();
    final compact = CardDensityScope.of(context) == CardDensity.compact;

    return DashboardCardTemplate(
      title: loc(context).connectedDevices,
      // No `leading`, at any density — unlike #1288's three hero cards, which
      // gained a header icon in their degraded forms because the icon was lost
      // from the hero block they collapsed. Nothing leaves this card's header,
      // and the measurement on #1289 found the title itself already ellipsized
      // at 288px in `id` and `ru`; an icon there would take width from it.
      //
      // Those title floors — 312px in `id`, 300px in `ru` — are deliberately not
      // folded into the threshold, even though the row floor it was derived from
      // (336px) now happens to clear both. The header is
      // `DashboardCardTemplate`'s and no density changes it, so a form this card
      // selects cannot fix a clipped title at 288px whichever way the number
      // goes; the title is readable above 336px because the *rows* needed that
      // width, not because the title was priced in. Rolling it in would encode a
      // constraint shared by all 18 cards into one card's threshold.
      //
      // Both counts rather than just the online one: at popup width this is a
      // one-line reading of the network, and "3 online" without a total says
      // nothing about the 3 that are not. `nOnlineOfTotal` is already localized
      // in all 26 locales for `usp_network_topology_card`.
      popupValue: loc(context).nOnlineOfTotal(
        '${activeDevices.length}',
        '${devices.length}',
      ),
      titleBadge: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          UspStatusDot(isActive: true, size: 8),
          AppGap.xs(),
          AppText.labelSmall('${activeDevices.length}'),
          AppGap.sm(),
          UspStatusDot(isActive: false, size: 8),
          AppGap.xs(),
          AppText.labelSmall('${inactiveDevices.length}'),
        ],
      ),
      detailRoute: RouteNamed.uspDeviceList,
      itemCount: devices.length,
      detailLabel: loc(context).viewAll,
      content: LayoutBuilder(
        builder: (context, constraints) {
          // One decision for the whole list, taken from the width every row
          // shares — see [_kSignalLabelContentMinWidth] for why the tile's own
          // trailing cap cannot answer this.
          final showSignalLabel =
              constraints.maxWidth >= _kSignalLabelContentMinWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status summary - metric tiles style using LayoutBlock
              _StatusCounts(
                online: _StatusCountSpec(
                  isActive: true,
                  count: activeDevices.length,
                  label: loc(context).online,
                ),
                offline: _StatusCountSpec(
                  isActive: false,
                  count: inactiveDevices.length,
                  label: loc(context).offline,
                ),
              ),
              AppGap.md(),
              // Device list - only online devices, max 5
              if (activeDevices.isEmpty)
                EmptyState(
                  icon: Icons.devices,
                  message: loc(context).noDevicesOnline,
                )
              else
                for (var i = 0; i < displayDevices.length; i++) ...[
                  _buildDeviceRow(context, displayDevices[i],
                      showSignalLabel: showSignalLabel, compact: compact),
                  if (i < displayDevices.length - 1) AppGap.sm(),
                ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceRow(
    BuildContext context,
    ClientDevice device, {
    required bool showSignalLabel,
    required bool compact,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final deviceCategory = DeviceClassifier.classify(
      hostname: device.hostName,
      mac: device.mac,
    );

    return DeviceRow(
      // The compact form's whole content is the 60px the icon block gives back —
      // see [DeviceRow.compact]. The row keeps the device name, the address and
      // the signal reading, which is the trade the threshold was derived from:
      // an IPv4 address is the widest *bounded* token here, and truncating it
      // destroys the value instead of shortening it (#1289).
      compact: compact,
      icon: DeviceIconWithBadge.multiInterface(
        icon: deviceCategory.icon,
        size: 28,
        iconColor: scheme.onSurface,
        hasMultipleInterfaces: device.hasMultipleInterfaces,
      ),
      title: device.displayName,
      subtitle: device.ip,
      // The compact form keeps only what carries a *reading*, and that is the
      // rest of the 93.1px the address needs — the icon block alone does not get
      // there on the narrowest rows. Both of the things dropped here are demands
      // this row makes on a column it is simultaneously too narrow for:
      //
      //  * the parent-node badge, whose demand is a node *name* — unbounded user
      //    data, capped at [_kNodeBadgeMaxWidth] — so keeping it would make the
      //    content column a function of how the user named their extender
      //    instead of how wide the card is. At the 100px cap it costs the
      //    address 43px it does not have.
      //  * the `WiFi`/`Wired` interface label, which is the *widest* fixed
      //    trailing this row has (34.2px against the four bars' 22.0px) and the
      //    only one that is pure text. Measured: with it, a wired row's quad is
      //    granted 85.4px at a 200px card and clips; without it the row has no
      //    trailing slot at all, so ui_kit's 16px gap goes back too and the
      //    column is 134.0px.
      //
      // The bars stay, because they are a measurement of this device and nothing
      // else on the row carries it — whereas the interface label is a *type*
      // statement the row's icon also makes in the normal form, and the device
      // list page makes in full (#1289).
      trailing: compact
          ? (device.hasSignalDisplay
              ? UspSignalStrengthIndicator(
                  rssi: device.signalStrength!,
                  showLabel: showSignalLabel,
                )
              // `null`, not an empty `Column`: an occupied slot costs a 16px gap
              // whatever it renders, and this is the row the band is tightest
              // for.
              : null)
          // The badge is the one decision the slot itself can answer, because
          // the slot's cap is this row's own demand and the badge is what
          // demands it: a name that fits whole is granted the width it asked
          // for, and a name that does not is the only thing that gets squeezed.
          // So it is dropped exactly where it could only ellipsize, which
          // differs per row — unlike the dBm label, which every row must agree
          // on (#1238).
          : LayoutBuilder(
              builder: (context, constraints) {
                final nodeName = device.parentNodeName;
                final showBadge = nodeName != null &&
                    constraints.maxWidth >=
                        _nodeBadgeNaturalWidth(context, nodeName);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dropped rather than ellipsized: a node name clipped to
                    // three characters and a dash names nothing, and the row's
                    // own title is the information here.
                    if (showBadge) _buildParentNodeBadge(context, nodeName),
                    if (device.hasSignalDisplay)
                      UspSignalStrengthIndicator(
                        rssi: device.signalStrength!,
                        // The four bars keep their design size and carry the
                        // strength on their own; only the numeric label gives
                        // way.
                        showLabel: showSignalLabel,
                      )
                    else
                      AppText.bodySmall(
                        device.isWifi ? 'WiFi' : 'Wired',
                        color: scheme.onSurfaceVariant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                );
              },
            ),
    );
  }

  // ui_kit has `AppBadge` and `AppTag` for this, and both are the right thing to
  // move to — but not from an overflow ticket. Each is a fixed-height
  // `AppSurface` (24px × spacingFactor and 32px respectively) against this
  // hand-rolled ~20px, so swapping either in changes the trailing column's height
  // inside a 44px row and re-opens every width measured for #1238. This markup
  // predates the ticket and is unchanged by it; #1240 rebuilds the row and is
  // where the swap belongs.
  Widget _buildParentNodeBadge(BuildContext context, String nodeName) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: _kNodeBadgeMaxWidth),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: AppText.labelSmall(
        nodeName,
        color: scheme.onSurfaceVariant,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// One status count: a coloured dot, the number, and the word for the state.
class _StatusCountSpec {
  const _StatusCountSpec({
    required this.isActive,
    required this.count,
    required this.label,
  });

  final bool isActive;
  final int count;
  final String label;
}

/// Lays the online and offline counts out side by side, or stacks them once the
/// card's content is narrower than [_kStatusCountsSideBySideMinWidth].
///
/// The two counts are a matched pair — same chrome, same treatment — so they are
/// one widget rendered twice from a [_StatusCountSpec] rather than two copies of
/// the same markup, and no change can reach one without the other (#1238).
///
/// This is the same arrangement `_SummaryTiles` in
/// `usp_ethernet_ports_card.dart` uses, and the shape is deliberately *not*
/// extracted into `lib/page/_shared/components/layout_blocks/` yet: it is two
/// occurrences, the only shared part is ~15 lines of `LayoutBuilder`/`Row`/
/// `Column` (each site keeps its own measured threshold and its own stacked
/// treatment — `ethernet_ports` tightens padding when stacked, this does not),
/// and #1240 replaces both arrangements with a declared compact form. A third
/// card needing it is the trigger to extract.
///
/// The *tile* did get extracted, in #1275: it is `layout_blocks`'
/// [SummaryTile.inline], the same block `ethernet_ports` uses stacked. Only the
/// arrangement is still here.
class _StatusCounts extends StatelessWidget {
  const _StatusCounts({required this.online, required this.offline});

  final _StatusCountSpec online;
  final _StatusCountSpec offline;

  /// One count from [spec].
  ///
  /// A method rather than four `SummaryTile.inline(...)` calls below, so the
  /// matched pair cannot drift (#1238).
  ///
  /// `inline`, and no `compact`: neither the count nor the state word may yield —
  /// a count is meaningless truncated and `off…` names nothing — so the tile is
  /// not overflow-safe on its own below ~120px of inner width, which is what the
  /// arrangement above exists to guarantee. It also has the vertical budget to
  /// keep the standard 12px padding: the pair costs 96px of a 261px content
  /// viewport, where `ethernet_ports` has to fit 120px into 121px.
  Widget _tile(_StatusCountSpec spec) => SummaryTile.inline(
        leading: UspStatusDot(isActive: spec.isActive, size: 10),
        value: '${spec.count}',
        label: spec.label,
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _kStatusCountsSideBySideMinWidth) {
          return Row(
            children: [
              Expanded(child: _tile(online)),
              AppGap.sm(),
              Expanded(child: _tile(offline)),
            ],
          );
        }
        // Stretch keeps each count full-width. The pair goes from 44px to 96px
        // of the content column, and those 52px are scrolled, not clipped — the
        // template already scrolls this card's content, whose five 68px device
        // rows exceed the 3-row viewport by more than that on their own, so
        // stacking cannot trade a right overflow for a bottom one (#1238).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _tile(online),
            AppGap.sm(),
            _tile(offline),
          ],
        );
      },
    );
  }
}
