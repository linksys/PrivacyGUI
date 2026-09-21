import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/util/date_format_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Node detail page — displays mesh node info and connected devices.
class UspNodeDetailView extends ConsumerWidget {
  final String deviceId;

  const UspNodeDetailView({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(uspNodeDetailProvider(deviceId));

    return UiKitPageView.withSliver(
      identifier: 'node-detail',
      scrollable: true,
      title: loc(context).nodeDetail,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspTopology,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (detail.node == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleMedium(loc(context).nodeNotFound),
                AppGap.lg(),
                AppButton.text(
                  label: loc(context).backToTopology,
                  identifier: 'node-detail-back',
                  onTap: () =>
                      context.navigateBack(fallback: RouteNamed.uspTopology),
                ),
              ],
            ),
          );
        }

        final node = detail.node!;
        return AppResponsiveLayout(
          mobile: (_) => _buildMobileLayout(context, ref, node, detail),
          tablet: (_) => _buildMobileLayout(context, ref, node, detail),
          desktop: (_) => _buildDesktopLayout(context, ref, node, detail),
        );
      },
    );
  }

  // ===========================================================================
  // Layouts
  // ===========================================================================

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref,
      NodeEntity node, UspNodeDetailState detail) {
    return Column(
      children: [
        _buildNodeInfoCard(context, node),
        AppGap.lg(),
        _buildNetworkCard(context, ref, node),
        if (node is SlaveNode) ...[
          AppGap.lg(),
          _buildBackhaulCard(context, node, detail.parentNode),
        ],
        AppGap.lg(),
        _buildConnectedDevicesCard(context, detail),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref,
      NodeEntity node, UspNodeDetailState detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.colWidth(4),
          child: Column(
            children: [
              _buildNodeInfoCard(context, node),
              AppGap.lg(),
              _buildNetworkCard(context, ref, node),
              if (node is SlaveNode) ...[
                AppGap.lg(),
                _buildBackhaulCard(context, node, detail.parentNode),
              ],
            ],
          ),
        ),
        AppGap.gutter(),
        SizedBox(
          width: context.colWidth(8),
          child: _buildConnectedDevicesCard(context, detail),
        ),
      ],
    );
  }

  // ===========================================================================
  // Node Info Card
  // ===========================================================================

  Widget _buildNodeInfoCard(BuildContext context, NodeEntity node) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — image, name, role chip, liveness badge.
          //
          // Role and liveness are two independent facts and get two widgets
          // (#1465). One badge used to carry both badly: `isActive: true` with
          // the role as its *active* label, so the dot was unconditionally green
          // and `node.isOnline` — the value #1430 made meaningful — appeared
          // nowhere on the page. Passing `isActive: node.isOnline` to that same
          // badge would only have traded the facts, replacing the role label
          // with the literal "Offline".
          //
          // So the role is an `AppTag` from the kit rather than a chip grown here
          // (Article XV), and `DetailStatusBadge` goes back to meaning what it
          // already means one page over (`usp_device_detail_view.dart:170`) —
          // liveness.
          //
          // Both chips sit *under* the name rather than the badge trailing the
          // row, which is where the device-detail page puts it. Measured, on the
          // golden this page already had: this card is `colWidth(4)` on desktop,
          // so at 1280px the header row divides 232px, and a trailing badge
          // leaves the name 75 of them — enough to break `MX2000` across two
          // lines *mid-word*. All 234 gate cells stay green through that, because
          // a wrap is not an overflow; it is the class of defect
          // `doc/testing/overflow_gate_architecture.md` §7 keeps outside the
          // sweep. Under the name the two chips share the row's full width and
          // the name keeps all 156px it had before this change.
          //
          // `Wrap` and not `Row`: both labels are translated, and the widest pair
          // is `el` at 24 characters (`Δευτερεύων` + `Εκτός σύνδεσης`) against
          // `en`'s 12 — measured across `lib/l10n/app_*.arb`. The pair has to be
          // able to take a second line rather than overflow.
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: AppImage.provider(
                    imageProvider: DeviceImageHelper.getRouterImage(
                      routerIconTestByModel(modelNumber: node.model),
                    ),
                    width: 48,
                    height: 48,
                  ),
                ),
                AppGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleLarge(node.displayName),
                      AppGap.xs(),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppTag(
                            label: node.isMaster
                                ? loc(context).master
                                : loc(context).slave,
                            // Spelled inline: the E2E identifier harvester reads
                            // this file as text, so a composed value never
                            // reaches the specs' SSOT. The role label is
                            // translated and has no other stable locator.
                            identifier: 'node-detail-role',
                          ),
                          DetailStatusBadge(
                            isActive: node.isOnline,
                            // Also spelled inline, and for the same reason: the
                            // badge's label is `online`/`offline` translated, so
                            // the hook is what lets a spec find the element and
                            // read the state out of its text.
                            identifier: 'node-detail-liveness',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Hardware Info Block
          DetailInfoBlock(
            children: [
              if (node.deviceId.toUpperCase() != 'GATEWAY')
                DetailCopyableTile(
                  icon: Icons.memory,
                  label: loc(context).macAddress,
                  value: node.deviceId,
                ),
              if (node.model.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.router,
                  label: loc(context).model,
                  value: node.model,
                ),
              if (node.manufacturer.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.business,
                  label: loc(context).manufacturer,
                  value: node.manufacturer,
                ),
              if (node.serialNumber.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.tag,
                  label: loc(context).serialNumberLabel,
                  value: node.serialNumber,
                ),
              if (node.softwareVersion.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.system_update,
                  label: loc(context).firmware,
                  value: node.softwareVersion,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Network Card
  // ===========================================================================

  Widget _buildNetworkCard(
      BuildContext context, WidgetRef ref, NodeEntity node) {
    final wanData =
        node.isMaster ? ref.watch(wanDataProvider).valueOrNull?.model : null;
    final wanIp = wanData?.ipAddress;
    final wanIpv6Addresses = wanData?.ipv6Addresses ?? [];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.lan,
            title: loc(context).network,
          ),
          AppGap.md(),
          DetailInfoBlock(
            children: [
              // LAN IPv4
              if (node.ipAddress != null && node.ipAddress!.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.language,
                  label: loc(context).lanIp,
                  value: node.ipAddress!,
                ),
              // LAN IPv6 (from Hosts) — routable addresses first; a link-local
              // address swaps its leading icon for a scope badge (see
              // #1128/#1129).
              for (final ipv6 in preferGlobalIpv6First(node.ipv6Addresses))
                DetailCopyableTile(
                  icon: Icons.language,
                  label: loc(context).lanIpv6,
                  value: ipv6,
                  leading: isLinkLocalIpv6(ipv6)
                      ? const Ipv6ScopeBadge(size: 16)
                      : null,
                ),
              // WAN IPv4 (master only)
              if (wanIp != null && wanIp.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.public,
                  label: loc(context).wanIp,
                  value: wanIp,
                ),
              // WAN IPv6 (master only) — routable addresses first; a link-local
              // address swaps its leading icon for a scope badge (see
              // #1128/#1129).
              for (final ipv6 in preferGlobalIpv6First(wanIpv6Addresses))
                DetailCopyableTile(
                  icon: Icons.public,
                  label: loc(context).wanIpv6,
                  value: ipv6,
                  leading: isLinkLocalIpv6(ipv6)
                      ? const Ipv6ScopeBadge(size: 16)
                      : null,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Backhaul Connection Card (Slave nodes only)
  // ===========================================================================

  Widget _buildBackhaulCard(
      BuildContext context, SlaveNode node, NodeEntity? parentNode) {
    final colorScheme = Theme.of(context).colorScheme;
    final backhaul = node.backhaul;
    final isWifiBackhaul = backhaul.isWifi;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.sync_alt,
            title: loc(context).backhaulConnection,
          ),
          AppGap.md(),
          // Connected To Block
          if (parentNode != null) ...[
            LayoutBlock(
              identifier: 'node-detail-parent',
              onTap: () => context.pushNamed(
                RouteNamed.uspNodeDetail,
                queryParameters: {'deviceId': parentNode.deviceId},
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.link,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  AppGap.sm(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelSmall(loc(context).connectedTo,
                            color: colorScheme.onSurfaceVariant),
                        AppText.bodyMedium(
                            '${parentNode.isMaster ? loc(context).master : loc(context).slave} (${parentNode.model})'),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
            AppGap.sm(),
          ],
          // Interface + Signal row (Wi-Fi backhaul)
          if (isWifiBackhaul) ...[
            Row(
              children: [
                Expanded(
                  child: LayoutBlock(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wifi,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            AppGap.xs(),
                            // The caption takes the space the icon leaves
                            // instead of its natural width: this tile is a
                            // half-width Expanded, leaving the row 99dp, while
                            // `fi` needs 102.6dp for `Käyttöliittymä`. The
                            // interface name is on the line below, so
                            // shortening the caption loses no information
                            // (#1302).
                            Expanded(
                              child: AppText.labelSmall(
                                loc(context).labelInterface,
                                color: colorScheme.onSurfaceVariant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        AppGap.xs(),
                        // Reachable null, and load-bearing: since #1555
                        // `hasInfo` is true for a link known only by its parent
                        // ID, so this arm renders for a node whose medium
                        // firmware left empty. `unknown` is the honest word for
                        // it — the alternative was fabricating "Wi-Fi" into the
                        // model to keep the two graders agreeing, which would
                        // print a medium nothing measured.
                        AppText.bodyMedium(
                            backhaul.linkType ?? loc(context).unknown),
                      ],
                    ),
                  ),
                ),
                if (backhaul.signalStrength != null) ...[
                  AppGap.sm(),
                  Expanded(
                    child:
                        BackhaulSignalIndicator(rssi: backhaul.signalStrength!),
                  ),
                ],
              ],
            ),
            AppGap.sm(),
          ] else if (backhaul.isEthernet) ...[
            // Ethernet backhaul — just interface block
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_ethernet,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      AppGap.xs(),
                      AppText.labelSmall(loc(context).labelInterface,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  AppGap.xs(),
                  AppText.bodyMedium(backhaul.linkType ?? loc(context).unknown),
                ],
              ),
            ),
            AppGap.sm(),
          ] else ...[
            // Backhaul present in the topology but with no medium reported
            // (`hasInfo` false): neither Wi-Fi nor Ethernet. Without this arm
            // the card renders as a bare header — every block below is also
            // gated on data this state does not have (no rates, no
            // `lastContactTime`), so the user gets a titled empty card with
            // nothing saying why.
            //
            // Reachable since #1430's liveness change: a node whose
            // DataElements subtree never arrived now stays online and
            // navigable (see `SlaveNode.livenessKnown`), so this page is
            // reachable in exactly the state that carries no backhaul.
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      AppGap.xs(),
                      AppText.labelSmall(loc(context).labelInterface,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  AppGap.xs(),
                  // Deliberately not "no backhaul": the node is connected (it
                  // is in the topology), only the medium is unreported.
                  AppText.bodyMedium(loc(context).unknown),
                ],
              ),
            ),
            AppGap.sm(),
          ],
          // Throughput Block
          if (backhaul.uplinkRate != null || backhaul.downlinkRate != null) ...[
            Row(
              children: [
                if (backhaul.uplinkRate != null)
                  Expanded(
                    child: DetailSpeedCard(
                      icon: Icons.upload,
                      label: loc(context).upload,
                      speedKbps: backhaul.uplinkRate!,
                      color: colorScheme.tertiary,
                    ),
                  ),
                if (backhaul.uplinkRate != null &&
                    backhaul.downlinkRate != null)
                  AppGap.sm(),
                if (backhaul.downlinkRate != null)
                  Expanded(
                    child: DetailSpeedCard(
                      icon: Icons.download,
                      label: loc(context).download,
                      speedKbps: backhaul.downlinkRate!,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            AppGap.xs(),
            // The rate is a node-to-node link rate — 2882 Mbps on the bench — and
            // without this line a customer reads it as their internet connection,
            // which is typically one or two orders of magnitude lower (#1442,
            // PM#124 REQ-12).
            //
            // A full-width row under the cards, **not** part of `DetailSpeedCard`'s
            // `label`, which is where the ticket's AC2 put it. Measured: that
            // caption gets 70.5dp here at 1241px, and `Download` already needs
            // 297dp in `fr` and 143dp in `pl`, so the slot is ellipsized in about
            // twenty locales before anything is added to it — and an ellipsis
            // here removes exactly the words REQ-12 asks for. Shortening a caption
            // is free when the number below carries the reading (#1302); it is not
            // free when the caption *is* the information. Guarded by
            // `usp_node_detail_backhaul_overflow_test.dart`, which is what AC2's
            // reasoning — "a new row would have no guard" — was protecting.
            //
            // No `maxLines`: free to wrap. A line cap would reintroduce the
            // truncation this placement exists to avoid.
            //
            // AC2's audit of the two rates' consumers, recorded because the ticket
            // got it wrong: it says this view is "the only one today", and
            // `usp_topology_builder.dart` also reads `uplinkRate`, as
            // `MeshLink.throughput`. That one needs no qualifier — ui_kit uses it
            // only as an animation-speed multiplier (`(throughput / 100).clamp(0.5,
            // 3.0)` in `link_renderer.dart` and `topology_graph_view.dart`) and
            // never renders it as text. So this is the only place a customer reads
            // the number, and the only place the sentence is needed.
            AppText.labelSmall(
              loc(context).backhaulRateNotInternetSpeed,
              color: colorScheme.onSurfaceVariant,
            ),
            AppGap.sm(),
          ],
          // Last Contact row
          //
          // A PHY Rate tile used to share this row. `BackhaulPHYRate` is not in
          // the prplMesh schema and has no replacement in it (#1555), so the
          // tile could only ever have rendered its `phyRate > 0` guard as false.
          // Its going leaves this tile full-width, which is a strict improvement
          // for the caption below: at half width `lastContact` overflows the
          // 99dp row in 21 locales.
          if (backhaul.lastContactTime != null)
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      AppGap.xs(),
                      // Kept ellipsising even at full width: the guard costs
                      // nothing and the row is still narrow at the 360px
                      // breakpoint (#1302).
                      Expanded(
                        child: AppText.labelSmall(
                          loc(context).lastContact,
                          color: colorScheme.onSurfaceVariant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppGap.xs(),
                  AppText.bodyMedium(DateFormatUtils.formatRelativeTime(
                      backhaul.lastContactTime)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Connected Devices Card
  // ===========================================================================

  Widget _buildConnectedDevicesCard(
      BuildContext context, UspNodeDetailState detail) {
    final devices = detail.connectedClients;
    final activeCount = detail.activeClientCount;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.devices,
            title: loc(context).connectedDevices,
            trailing: AppText.labelLarge(
              '$activeCount / ${devices.length}',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.md(),
          if (devices.isEmpty)
            DetailEmptyBlock(
              message: loc(context).noDevicesConnectedToNode,
            )
          else
            Column(
              children: [
                for (var i = 0; i < devices.length; i++) ...[
                  LayoutBlock(
                    identifier:
                        'node-device-open-${ruleIdentifierKey(devices[i].mac, null)}',
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: UspDeviceListTile(
                      device: devices[i],
                      variant: DeviceListTileVariant.flatLast,
                      onTap: () => context.pushNamed(
                        RouteNamed.uspDeviceDetail,
                        queryParameters: {'mac': devices[i].mac},
                      ),
                    ),
                  ),
                  if (i < devices.length - 1) AppGap.sm(),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
