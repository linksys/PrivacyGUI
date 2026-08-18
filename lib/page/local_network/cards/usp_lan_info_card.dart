import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspLanInfoCard extends ConsumerWidget {
  final LanInfoUIModel? info;

  const UspLanInfoCard({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = this.info ?? ref.watch(lanDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.info(rows: 4);
    final colorScheme = Theme.of(context).colorScheme;
    final density = CardDensityScope.of(context);

    return DashboardCardTemplate(
      title: loc(context).lanInformation,
      // Only in the degraded forms, so nothing changes above the threshold
      // (#1288). Below it the hero hides its own icon to give the IP the width it
      // needs, and this is where the icon goes instead: the header row already
      // exists, so it costs no height, and the popup form is built from the
      // template's header — with no `leading` it would show a value and no glyph,
      // where §2.1 promises an icon.
      leading: density == CardDensity.normal
          ? null
          : AppIcon.font(
              Icons.router,
              color: colorScheme.primary,
              size: BlockConstants.iconMd,
            ),
      // The router's own address: the one line worth a whole card at popup width.
      popupValue: info.ipAddress,
      detailRoute: RouteNamed.uspLocalNetwork,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero block - Router IP with DHCP status
          HeroBlock(
            compact: density == CardDensity.compact,
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: AppIcon.font(
                Icons.router,
                color: colorScheme.primary,
                size: 28,
              ),
            ),
            children: [
              AppText.titleLarge(info.ipAddress),
              AppGap.xxs(),
              // The hero's 56px avatar + `AppGap.lg` leave this column just
              // **61.4px** at the card's narrowest realization (measured), and a
              // `Row` hands a non-flex child unbounded width — so the status
              // label painted at its full intrinsic width and the row overflowed
              // in every locale, `en` included (+47.7px), up to +101.8px in `el`.
              //
              // Soft-wrap, not ellipsis: `DHCP Enabled` is a composed *status*,
              // and ~49px of text column would ellipsize it to `DHCP…` —
              // dropping the one word the row exists to show. §2.10a point 2's
              // rule, applied to a status instead of a statistic. The height a
              // second run costs is free here: this card's content sits in the
              // card template's `SingleChildScrollView`, so it yields, unlike the
              // fixed gauge of §2.10a point 3. `start` keeps the dot on the
              // label's first line rather than floating it to the vertical middle
              // of a wrapped block.
              //
              // What the wrap could not fix is a column too narrow for a single
              // *word*: at 61.4px `Ενεργοποιήθηκε` (107.2px) breaks mid-word,
              // which is the damage the ellipsis was rejected for. That is the
              // width this card now declares a threshold for (#1288), not
              // something a different wrap can reach.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: UspStatusDot(isActive: info.dhcpEnabled, size: 8),
                  ),
                  AppGap.xs(),
                  Flexible(
                    child: AppText.bodyMedium(
                      '${loc(context).dhcp} ${info.dhcpEnabled ? loc(context).enabled : loc(context).disabled}',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          AppGap.sm(),
          // Subnet & DNS - 2 columns
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  icon: Icons.lan,
                  label: loc(context).subnetMask,
                  value: info.subnetMask,
                  color: colorScheme.primary,
                ),
              ),
              AppGap.sm(),
              Expanded(
                child: MetricTile(
                  icon: Icons.dns,
                  label: 'DNS',
                  value: info.dnsServers.isNotEmpty ? info.dnsServers : '-',
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          // DHCP Range & IPv6
          if (info.dhcpEnabled && info.dhcpRange.isNotEmpty ||
              info.ipv6Addresses.isNotEmpty ||
              info.ipv6Enabled) ...[
            AppGap.sm(),
            InfoGrid(
              items: [
                if (info.dhcpEnabled && info.dhcpRange.isNotEmpty)
                  InfoGridItem(
                      label: loc(context).dhcpRange, value: info.dhcpRange),
                if (info.ipv6Addresses.isNotEmpty)
                  InfoGridItem(
                    label: 'IPv6',
                    value: info.ipv6Addresses.first,
                    copyable: true,
                    // The representative address prefers global unicast; when
                    // only a link-local (fe80::/10) address exists it is still
                    // shown, tagged with a scope badge rather than hidden.
                    // See #1129.
                    labelTrailing: isLinkLocalIpv6(info.ipv6Addresses.first)
                        ? const Ipv6ScopeBadge()
                        : null,
                  )
                else if (info.ipv6Enabled)
                  // `IPv6` is a protocol name and stays as it is, like `DHCP`
                  // above; the *value* is prose and was not. Localizing it is
                  // safe here without new measurement, which is not usually
                  // true of a hardcoded string (#1266): this branch never
                  // renders under the gate's fixture, but the cell it renders
                  // into is the shared `InfoGrid` value, which soft-wraps since
                  // #1236 and is measured in all 26 locales via the sibling
                  // branch — and that sibling paints a full IPv6 address, far
                  // longer than the longest `enabled` translation.
                  InfoGridItem(label: 'IPv6', value: loc(context).enabled),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
