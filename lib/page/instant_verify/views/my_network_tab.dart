import 'diagnostic_selection_area.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'instant_test_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/restart_helper.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

/// PRD v0.7 Tab 2: My Network
///
/// 5 sections: Internet Connection, Your Router, Satellite Nodes (mesh only),
/// WiFi Overview, Guest Network.
class MyNetworkTab extends ConsumerWidget {
  const MyNetworkTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => StyledAppPageView(
        title: 'Network details',
        scrollable: true,
        onRefresh: () => ref
            .read(instantVerifyPivotProvider.notifier)
            .fetch(forceSpeedTest: true),
        child: (context, constraints) =>
            DiagnosticSelectionArea(child: _content(context, ref)),
      );

  Widget _content(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);

    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: AppText.titleLarge('Your Network'),
              ),
              IconButton(
                icon: const Icon(LinksysIcons.refresh),
                tooltip: 'Refresh',
                onPressed: state.phase == PivotLoadPhase.loading
                    ? null
                    : () => ref
                        .read(instantVerifyPivotProvider.notifier)
                        .fetch(forceSpeedTest: true),
              ),
            ],
          ),
          const AppGap.small2(),
          _InternetConnectionCard(state: state, ref: ref),
          const AppGap.small3(),
          _YourRouterCard(state: state, ref: ref),
          if (state.isMeshNetwork) ...[
            const AppGap.small3(),
            _SatelliteNodesSection(state: state),
          ],
          const AppGap.small3(),
          _WifiOverviewCard(state: state),
          // Only show guest network card when it's enabled — not a config screen
          if (state.guestNetwork != null &&
              state.guestNetwork!['isGuestNetworkEnabled'] == true) ...[
            const AppGap.small3(),
            _GuestNetworkCard(state: state),
          ],
        ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 1: Internet Connection
// ═══════════════════════════════════════════════════════════════════════════

class _InternetConnectionCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  final WidgetRef ref;
  const _InternetConnectionCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final connected = state.wanConnected;
    final tone = connected ? InstantTestTone.good : InstantTestTone.problem;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connected ? LinksysIcons.public : LinksysIcons.publicOff,
                  color: tone.color(context),
                ),
                const AppGap.small2(),
                const AppText.titleMedium('Internet Connection'),
              ],
            ),
            const AppGap.small3(),
            _infoRow(context, 'Status',
                connected ? 'Connected' : 'Not Connected',
                valueColor: tone.color(context)),
            if (state.wanConnectionType != null)
              _infoRow(context, 'Type', state.wanConnectionType!),
            if (connected && state.wanIpAddress != null)
              _infoRow(context, 'IP Address', state.wanIpAddress!),
            if (!connected && !state.hasRestartedThisSession) ...[
              const AppGap.small3(),
              SizedBox(
                width: double.infinity,
                child: AppOutlinedButton('Restart Router',
                onTap: () => confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
              ),
            ],
            if (!connected && state.hasRestartedThisSession) ...[
              const AppGap.small3(),
              AppText.bodySmall(
                'You already restarted — if it\'s still disconnected, contact Linksys Support.',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }

}

// ═══════════════════════════════════════════════════════════════════════════
// Section 2: Your Router
// ═══════════════════════════════════════════════════════════════════════════

class _YourRouterCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  final WidgetRef ref;
  const _YourRouterCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final uptimeDays = state.uptimeSeconds ~/ 86400;
    final showUptime = uptimeDays >= 30;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LinksysIcons.router,
                    color: Theme.of(context).colorScheme.primary),
                const AppGap.small2(),
                AppText.titleMedium(
                  // Show the controller's custom name when available.
                  state.meshNodes.any((n) => n.isController)
                      ? state.meshNodes.firstWhere((n) => n.isController).name
                      : 'Your Router',
                ),
              ],
            ),
            const AppGap.small3(),
            if (state.routerModel != null)
              _infoRow(context, 'Model', state.routerModel!),
            _infoRow(
              context,
              'Firmware',
              state.firmwareUpdateAvailable
                  ? 'Update available'
                  : 'Up to date',
              valueColor: state.firmwareUpdateAvailable
                  ? InstantTestTone.warning.color(context)
                  : InstantTestTone.good.color(context),
            ),
            if (state.firmwareUpdateAvailable) ...[
              const AppGap.small2(),
              SizedBox(
                width: double.infinity,
                child: AppOutlinedButton('Update Now',
                onTap: () {
                    ref.read(instantVerifyPivotProvider.notifier).triggerFirmwareUpdate();
                  },
                icon: LinksysIcons.cloudDownload),
              ),
            ],
            if (showUptime) ...[
              const AppGap.small2(),
              Container(
                padding: const EdgeInsets.all(Spacing.small3),
                decoration: BoxDecoration(
                  color: InstantTestTone.warning.container(context),
                  borderRadius:
                      CustomTheme.of(context).radius.asBorderRadius().medium,
                ),
                child: Row(
                  children: [
                    Icon(LinksysIcons.uptime,
                        size: 18,
                        color: InstantTestTone.warning.onContainer(context)),
                    const AppGap.small2(),
                    Expanded(
                      child: AppText.bodyMedium(
                        'Running for $uptimeDays days — a restart may help',
                        color: InstantTestTone.warning.onContainer(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (!state.hasRestartedThisSession) ...[
                const AppGap.small2(),
                SizedBox(
                  width: double.infinity,
                  child: AppOutlinedButton('Restart Router',
                onTap: () => confirmAndRestart(context, ref),
                icon: LinksysIcons.restartAlt),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 3: Satellite Nodes (mesh only)
// ═══════════════════════════════════════════════════════════════════════════

class _SatelliteNodesSection extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _SatelliteNodesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final satellites = state.meshNodes.where((n) => !n.isController).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: Spacing.small1, bottom: Spacing.small2),
          child: AppText.titleMedium('Your Child Nodes'),
        ),
        for (int i = 0; i < satellites.length; i++)
          _SatelliteNodeCard(
            node: satellites[i],
            index: i + 1,
            deviceCount: state.clientCountForNode(satellites[i].deviceId),
          ),
      ],
    );
  }
}

class _SatelliteNodeCard extends StatelessWidget {
  final MeshNodeInfo node;
  final int index;
  final int deviceCount;
  const _SatelliteNodeCard({
    required this.node,
    required this.index,
    required this.deviceCount,
  });

  @override
  Widget build(BuildContext context) {
    final health = node.backhaulHealth;
    final isWeak = health == BackhaulHealth.weak || health == BackhaulHealth.critical;
    final isWired = node.hasWiredBackhaul;
    // A node with backhaul telemetry is provably reachable; otherwise trust the
    // online flag derived from GetDevices3 `connections`.
    final isOnline = node.isOnline || node.hasBackhaulData;

    final speedSuffix = node.backhaulSpeedMbps != null ? ' (${node.backhaulSpeedMbps} Mbps)' : '';
    String backhaulLabel;
    InstantTestTone? backhaulTone;
    if (!isOnline) {
      backhaulLabel = 'Offline — not responding';
      backhaulTone = InstantTestTone.problem;
    } else if (isWired) {
      backhaulLabel = 'Connected by Ethernet$speedSuffix';
    } else if (isWeak) {
      backhaulLabel = 'Connected wirelessly — ${health == BackhaulHealth.critical ? 'Critical' : 'Weak'}$speedSuffix';
      backhaulTone = InstantTestTone.warning;
    } else if (health == BackhaulHealth.moderate) {
      backhaulLabel = 'Connected wirelessly — Moderate$speedSuffix';
      backhaulTone = InstantTestTone.warning;
    } else if (health == BackhaulHealth.strong) {
      backhaulLabel = 'Connected wirelessly — Good$speedSuffix';
      backhaulTone = InstantTestTone.good;
    } else {
      // Online but no backhaul health data — don't assert "Good".
      backhaulLabel = 'Connected wirelessly — Health unknown';
    }

    return AppCard(
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: Spacing.small2),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LinksysIcons.networkNode,
                  color: !isOnline
                      ? InstantTestTone.problem.color(context)
                      : isWeak
                          ? InstantTestTone.warning.color(context)
                          : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const AppGap.small2(),
                Expanded(
                  child: AppText.titleSmall(
                    // Show the node's custom name (was hardcoded "Child Node N").
                    node.name,
                  ),
                ),
                if (!isOnline)
                  Icon(InstantTestTone.problem.icon,
                      color: InstantTestTone.problem.color(context), size: 18)
                else if (isWeak)
                  Icon(InstantTestTone.warning.icon,
                      color: InstantTestTone.warning.color(context), size: 18),
              ],
            ),
            const AppGap.small2(),
            AppText.bodyMedium(
              backhaulLabel,
              color: backhaulTone?.color(context),
            ),
            AppText.bodySmall(
              '$deviceCount device${deviceCount == 1 ? '' : 's'} connected',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (isWeak) ...[
              const AppGap.small2(),
              Container(
                padding: const EdgeInsets.all(Spacing.small3),
                decoration: BoxDecoration(
                  color: InstantTestTone.warning.container(context),
                  borderRadius:
                      CustomTheme.of(context).radius.asBorderRadius().medium,
                ),
                child: AppText.bodyMedium(
                  'This node has a weak connection to your router. Move it closer or connect it with an Ethernet cable.',
                  color: InstantTestTone.warning.onContainer(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 4: WiFi Overview
// ═══════════════════════════════════════════════════════════════════════════

class _WifiOverviewCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _WifiOverviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final count24 = state.twoPointFourGhzCount;
    final count5 = state.fiveGhzCount;
    final wirelessTotal = state.wirelessDeviceCount;
    final isOvercrowded =
        wirelessTotal >= 4 && count24 > 0 && (count24 / wirelessTotal) >= 0.6;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LinksysIcons.wifi,
                    color: Theme.of(context).colorScheme.primary),
                const AppGap.small2(),
                const AppText.titleMedium('WiFi Overview'),
              ],
            ),
            const AppGap.small3(),
            _bandRow(context, '$count24 device${count24 == 1 ? '' : 's'} on 2.4 GHz',
                'slower, longer range'),
            const AppGap.small1(),
            _bandRow(context, '$count5 device${count5 == 1 ? '' : 's'} on 5 GHz',
                'faster, shorter range'),
            if (isOvercrowded) ...[
              const AppGap.small3(),
              Container(
                padding: const EdgeInsets.all(Spacing.small3),
                decoration: BoxDecoration(
                  color: InstantTestTone.warning.container(context),
                  borderRadius:
                      CustomTheme.of(context).radius.asBorderRadius().medium,
                ),
                child: AppText.bodyMedium(
                  'Many of your devices are on the slower 2.4 GHz band. '
                  'Connect fast devices like phones and laptops to the '
                  '5 GHz network for better speeds.',
                  color: InstantTestTone.warning.onContainer(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bandRow(BuildContext context, String label, String hint) {
    return Row(
      children: [
        Expanded(
          child: AppText.bodyMedium(label),
        ),
        AppText.bodySmall(
          '($hint)',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section 5: Guest Network
// ═══════════════════════════════════════════════════════════════════════════

class _GuestNetworkCard extends StatelessWidget {
  final InstantVerifyPivotState state;
  const _GuestNetworkCard({required this.state});

  @override
  Widget build(BuildContext context) {
    // Read-only by design: this customer diagnostic tool does not change
    // router settings, so there is no guest on/off control (the card only
    // renders when guest WiFi is already enabled). Editing guest WiFi may be
    // added later as an explicit feature, but it's out of scope here.
    final count = _guestDeviceCount();
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LinksysIcons.group,
                    color: Theme.of(context).colorScheme.primary),
                const AppGap.small2(),
                const Expanded(
                  child: AppText.titleMedium('Guest Network'),
                ),
                AppText.labelLarge(
                  'On',
                  color: InstantTestTone.good.color(context),
                ),
              ],
            ),
            const AppGap.small1(),
            AppText.bodySmall(
              '$count guest device${count == 1 ? '' : 's'} connected',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  int _guestDeviceCount() {
    if (state.guestNetwork == null) return 0;
    // GetGuestNetworkSettings does not return a count on most firmware.
    final count = state.guestNetwork!['guestDeviceCount'] as int?;
    if (count != null) return count;
    // Authoritative: the per-client `isGuest` flag (works on all network
    // types, including non-mesh where the old unmapped heuristic returned 0).
    // If any client carries the flag, trust it even when the count is zero.
    if (state.clients.any((c) => c.isGuest != null)) {
      return state.clients.where((c) => c.isGuest == true).length;
    }
    // Legacy fallback when the flag is absent: unmapped clients in mesh mode.
    if (state.isMeshNetwork) {
      final mapped = state.clientToNodeId.keys.toSet();
      return state.clients.where((c) => !mapped.contains(c.macAddress)).length;
    }
    return 0;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared helper
// ═══════════════════════════════════════════════════════════════════════════

Widget _infoRow(BuildContext context, String label, String value,
    {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: Spacing.small1),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: AppText.bodyMedium(
            label,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          // A status value is emphasised in its tone color; plain values are
          // body copy.
          child: valueColor != null
              ? AppText.labelLarge(value, color: valueColor, selectable: true)
              : AppText.bodyMedium(value, selectable: true),
        ),
      ],
    ),
  );
}
