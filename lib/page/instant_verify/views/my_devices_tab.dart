import 'diagnostic_selection_area.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'instant_test_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/mesh_node_info.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/device_actions.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';

/// PRD v0.7 Tab 1: My Devices
///
/// Shows all connected devices with signal quality badges, grouped by mesh node
/// when applicable. Guest devices separated. Tapping a device opens a detail
/// sheet with tailored advice.
class MyDevicesTab extends ConsumerWidget {
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const MyDevicesTab({super.key, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading =
        ref.watch(instantVerifyPivotProvider).phase == PivotLoadPhase.loading;
    // Re-scan for devices (e.g. a device that joined after the last test).
    void refresh() => ref
        .read(instantVerifyPivotProvider.notifier)
        .fetch(forceSpeedTest: true);
    return StyledAppPageView(
      title: 'Device details',
      scrollable: true,
      onRefresh: () async => refresh(),
      // Refresh sits in the title row, as on Instant-Topology.
      actions: [
        AppIconButton.noPadding(
          icon: LinksysIcons.refresh,
          semanticLabel: 'Refresh devices',
          color: Theme.of(context).colorScheme.primary,
          onTap: loading ? null : refresh,
        ),
      ],
      child: (context, constraints) =>
          DiagnosticSelectionArea(child: _content(context, ref)),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref) {
    final state = ref.watch(instantVerifyPivotProvider);

    if (state.phase == PivotLoadPhase.idle ||
        state.phase == PivotLoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.clients.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Spacing.large3),
          child: AppText.bodyMedium(
            'No devices found. Run Instant-Test first to discover connected devices.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalCount = state.clients.length;
    final wirelessCount = state.wirelessDeviceCount;
    final wiredCount = state.wiredDeviceCount;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary (the page title row holds refresh) ─────────────
          AppText.titleMedium(
            '$totalCount device${totalCount == 1 ? '' : 's'} connected',
          ),
          const AppGap.small1(),
          AppText.bodyMedium(
            '$wirelessCount wireless, $wiredCount wired',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const AppGap.medium(),

          // ── Device list ─────────────────────────────────────────────
          if (state.isMeshNetwork)
            _MeshGroupedList(state: state, onNavigateToFlow: onNavigateToFlow)
          else
            _FlatDeviceList(state: state, onNavigateToFlow: onNavigateToFlow),
        ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRD signal quality badge — uses PRD v0.7 thresholds, NOT DeviceScore buckets
// ═══════════════════════════════════════════════════════════════════════════

enum _SignalBadge { good, weak, poor, wired }

_SignalBadge _badgeFor(DiagnosticClient client) {
  if (!client.isWireless) return _SignalBadge.wired;
  final signal = client.signalDecibels;
  final rate = client.txRateMbps;

  // Poor: signal < -75 dBm OR data rate < 10 Mbps
  if (signal != null && signal < -75) return _SignalBadge.poor;
  if (rate != null && rate < 10) return _SignalBadge.poor;

  // Weak: signal -70 to -75 dBm OR data rate 10-30 Mbps
  if (signal != null && signal <= -70) return _SignalBadge.weak;
  if (rate != null && rate < 30) return _SignalBadge.weak;

  // Good: signal >= -70 dBm AND data rate >= 30 Mbps
  return _SignalBadge.good;
}

String _badgeLabel(_SignalBadge badge) {
  switch (badge) {
    case _SignalBadge.good:
      return 'Good';
    case _SignalBadge.weak:
      return 'Weak';
    case _SignalBadge.poor:
      return 'Poor';
    case _SignalBadge.wired:
      return 'Wired';
  }
}

InstantTestTone _badgeTone(_SignalBadge badge) {
  switch (badge) {
    case _SignalBadge.good:
      return InstantTestTone.good;
    case _SignalBadge.weak:
      return InstantTestTone.warning;
    case _SignalBadge.poor:
      return InstantTestTone.problem;
    case _SignalBadge.wired:
      return InstantTestTone.neutral;
  }
}

/// The kit's status label: a colored dot and word. Wired has no signal
/// quality, so it reads in the neutral "off" color.
Widget _badgeStatus(BuildContext context, _SignalBadge badge) {
  return AppStatusLabel(
    label: _badgeLabel(badge),
    offLabel: _badgeLabel(badge),
    isOff: badge == _SignalBadge.wired,
    onColor: _badgeTone(badge).color(context),
  );
}

IconData _deviceIcon(DiagnosticClient client) {
  if (!client.isWireless) return LinksysIcons.ethernet;
  final name = (client.hostname ?? '').toLowerCase();
  final mfr = (client.manufacturer ?? '').toLowerCase();
  if (name.contains('iphone') || name.contains('android') || name.contains('pixel') || name.contains('galaxy')) {
    return LinksysIcons.smartPhone;
  }
  if (name.contains('ipad') || name.contains('tablet')) return LinksysIcons.smartPhone;
  if (name.contains('tv') || name.contains('roku') || name.contains('shield') || mfr.contains('roku') || mfr.contains('nvidia')) {
    return LinksysIcons.smartTv;
  }
  if (name.contains('echo') || name.contains('nest') || name.contains('sonos') || mfr.contains('sonos') || mfr.contains('amazon')) {
    return LinksysIcons.musicSpeaker;
  }
  if (name.contains('macbook') || name.contains('laptop') || name.contains('surface')) {
    return LinksysIcons.computer;
  }
  if (name.contains('desktop') || name.contains('pc') || mfr.contains('dell') || mfr.contains('hp')) {
    return LinksysIcons.computer;
  }
  if (mfr.contains('espressif') || mfr.contains('tuya') || mfr.contains('wyze')) {
    return LinksysIcons.smartPlug;
  }
  if (mfr.contains('nintendo') || mfr.contains('sony/ps') || mfr.contains('xbox')) {
    return LinksysIcons.stadiaController;
  }
  return LinksysIcons.devices;
}

// ═══════════════════════════════════════════════════════════════════════════
// Sort order: Issues (Poor → Weak) first, then alphabetical within each tier
// ═══════════════════════════════════════════════════════════════════════════

int _sortOrder(_SignalBadge badge) {
  switch (badge) {
    case _SignalBadge.poor:
      return 0;
    case _SignalBadge.weak:
      return 1;
    case _SignalBadge.good:
      return 2;
    case _SignalBadge.wired:
      return 3;
  }
}

List<DiagnosticClient> _sorted(List<DiagnosticClient> clients) {
  final sorted = List<DiagnosticClient>.from(clients);
  sorted.sort((a, b) {
    final badgeA = _badgeFor(a);
    final badgeB = _badgeFor(b);
    final cmp = _sortOrder(badgeA).compareTo(_sortOrder(badgeB));
    if (cmp != 0) return cmp;
    return a.displayNameWithOui
        .toLowerCase()
        .compareTo(b.displayNameWithOui.toLowerCase());
  });
  return sorted;
}

// ═══════════════════════════════════════════════════════════════════════════
// Flat list (non-mesh)
// ═══════════════════════════════════════════════════════════════════════════

class _FlatDeviceList extends StatelessWidget {
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _FlatDeviceList({required this.state, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context) {
    return _DeviceCards(
      clients: _sorted(state.clients),
      state: state,
      onNavigateToFlow: onNavigateToFlow,
    );
  }
}

/// Device cards separated like the device list on the Devices page.
class _DeviceCards extends StatelessWidget {
  final List<DiagnosticClient> clients;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _DeviceCards({
    required this.clients,
    required this.state,
    this.onNavigateToFlow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < clients.length; i++) ...[
          if (i > 0) const AppGap.small2(),
          _DeviceRow(
              client: clients[i],
              state: state,
              onNavigateToFlow: onNavigateToFlow),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Mesh-grouped list
// ═══════════════════════════════════════════════════════════════════════════

class _MeshGroupedList extends StatelessWidget {
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _MeshGroupedList({required this.state, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context) {
    // Identify guests by the router's `isGuest` flag — not by lack of node
    // mapping, which mislabeled mapped guests and un-mapped main clients (Q-08).
    final guestClients = state.clients.where((c) => c.isGuest == true).toList();
    final mainClients = state.clients.where((c) => c.isGuest != true).toList();

    // Group clients by node
    final controller = state.meshNodes.where((n) => n.isController).toList();
    final satellites = state.meshNodes.where((n) => !n.isController).toList();
    final allNodes = [...controller, ...satellites];

    // Bucket main clients by their node; any without a mapping are attributed
    // to the controller so they are never dropped.
    final controllerId =
        controller.isNotEmpty ? controller.first.deviceId : null;
    final byNode = <String, List<DiagnosticClient>>{};
    for (final c in mainClients) {
      final nodeId = state.clientToNodeId[c.macAddress] ?? controllerId;
      if (nodeId == null) continue;
      byNode.putIfAbsent(nodeId, () => []).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < allNodes.length; i++)
          _NodeGroup(
            node: allNodes[i],
            clients: _sorted(byNode[allNodes[i].deviceId] ?? []),
            // Show the user-assigned node name (was hardcoded, ignoring it).
            label: allNodes[i].name,
            state: state,
            onNavigateToFlow: onNavigateToFlow,
          ),
        if (guestClients.isNotEmpty)
          _NodeGroup(
            node: null,
            clients: _sorted(guestClients),
            label: 'Guest Devices',
            state: state,
            onNavigateToFlow: onNavigateToFlow,
          ),
      ],
    );
  }
}

class _NodeGroup extends StatefulWidget {
  final MeshNodeInfo? node;
  final List<DiagnosticClient> clients;
  final String label;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;

  const _NodeGroup({
    required this.node,
    required this.clients,
    required this.label,
    required this.state,
    this.onNavigateToFlow,
  });

  @override
  State<_NodeGroup> createState() => _NodeGroupState();
}

class _NodeGroupState extends State<_NodeGroup> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = true; // always expanded
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clientCount = widget.clients.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group heading: a borderless list row that collapses the group,
          // announced as one button that is expanded or collapsed.
          MergeSemantics(
            child: Semantics(
              button: true,
              expanded: _expanded,
              child: AppListCard(
                showBorder: false,
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.small2, vertical: Spacing.small2),
                onTap: () => setState(() => _expanded = !_expanded),
                leading: Icon(
                  _expanded
                      ? LinksysIcons.arrowDropDown
                      : LinksysIcons.chevronRight,
                  color: colors.onSurfaceVariant,
                ),
                title: AppText.titleMedium(widget.label),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.bodySmall(
                      '$clientCount device${clientCount == 1 ? '' : 's'}',
                      color: colors.onSurfaceVariant,
                    ),
                    if (widget.node?.hasWeakBackhaul == true) ...[
                      const AppGap.small2(),
                      Icon(InstantTestTone.warning.icon,
                          color: InstantTestTone.warning.color(context)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const AppGap.small2(),
            if (widget.clients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.small2),
                child: AppText.bodyMedium(
                  'No devices connected',
                  color: colors.onSurfaceVariant,
                ),
              )
            else
              _DeviceCards(
                clients: widget.clients,
                state: widget.state,
                onNavigateToFlow: widget.onNavigateToFlow,
              ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Device row
// ═══════════════════════════════════════════════════════════════════════════

class _DeviceRow extends StatelessWidget {
  final DiagnosticClient client;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _DeviceRow({required this.client, required this.state, this.onNavigateToFlow});

  @override
  Widget build(BuildContext context) {
    final badge = _badgeFor(client);

    // The Devices page's device card: icon, name, band, status. The band
    // sits under the name so narrow phones keep room for the status.
    // Announced as one button that opens the device's details.
    final card = MergeSemantics(
      child: Semantics(
        button: true,
        child: AppDeviceListCard(
          leading: _deviceIcon(client),
          title: client.displayNameWithOui,
          description: client.isWireless
              ? AppText.bodyMedium(
                  client.band,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
          trailing: _badgeStatus(context, badge),
          onTap: () => _showDeviceDetail(context, client, state,
              onNavigateToFlow: onNavigateToFlow),
        ),
      ),
    );
    return client.hostname == null && client.manufacturer != null
        ? Tooltip(
            message: 'Name from device hardware ID — many smart home brands show unfamiliar names',
            child: card,
          )
        : card;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Device detail bottom sheet
// ═══════════════════════════════════════════════════════════════════════════

void _showDeviceDetail(
  BuildContext context,
  DiagnosticClient client,
  InstantVerifyPivotState state, {
  void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => DiagnosticSelectionArea(
      child: _DeviceDetailSheet(
        client: client,
        state: state,
        onNavigateToFlow: onNavigateToFlow,
      ),
    ),
  );
}

class _DeviceDetailSheet extends ConsumerStatefulWidget {
  final DiagnosticClient client;
  final InstantVerifyPivotState state;
  final void Function(int flow, {DiagnosticClient? device})? onNavigateToFlow;
  const _DeviceDetailSheet({required this.client, required this.state, this.onNavigateToFlow});

  @override
  ConsumerState<_DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends ConsumerState<_DeviceDetailSheet> {
  bool _isDisconnecting = false;
  bool _isChangingChannel = false;

  DiagnosticClient get client => widget.client;
  InstantVerifyPivotState get state => widget.state;
  void Function(int flow, {DiagnosticClient? device})? get onNavigateToFlow => widget.onNavigateToFlow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badge = _badgeFor(client);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            Spacing.large2, 0, Spacing.large2, Spacing.large2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device name + icon
            Row(
              children: [
                Icon(_deviceIcon(client), size: 32, color: colors.primary),
                const AppGap.small3(),
                Expanded(
                  child: AppText.titleLarge(
                    client.displayNameWithOui,
                    selectable: true,
                  ),
                ),
              ],
            ),
            const AppGap.medium(),

            // Connection info
            _connectionInfo(context),
            const AppGap.medium(),

            // IP + MAC (selectable for copy)
            _deviceMeta(context, colors),
            const AppGap.medium(),

            // Signal quality bar (wireless only)
            if (client.isWireless) ...[
              _signalBar(context, badge, colors),
              const AppGap.medium(),
            ],

            // Advice
            _advice(context, badge),
            const AppGap.medium(),

            // Actions
            _actions(context, colors),
          ],
        ),
      ),
    );
  }

  Widget _connectionInfo(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!client.isWireless) {
      return Row(
        children: [
          Icon(LinksysIcons.ethernet, size: 18, color: colors.onSurfaceVariant),
          const AppGap.small2(),
          Expanded(
            child: AppText.bodyMedium(
              'Connected by Ethernet cable',
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    // Determine which node this device is connected to
    final nodeId = state.clientToNodeId[client.macAddress];
    String connectionLabel;
    if (nodeId != null && state.meshNodes.isNotEmpty) {
      final node = state.meshNodes
          .cast<MeshNodeInfo?>()
          .firstWhere((n) => n!.deviceId == nodeId, orElse: () => null);
      if (node != null) {
        if (node.isController) {
          connectionLabel = 'Connected to router on ${client.band}';
        } else {
          // The node's own name, matching network details (was "Child Node N").
          connectionLabel = node.name.trim().isEmpty
              ? 'Connected to a mesh node on ${client.band}'
              : 'Connected to ${node.name} on ${client.band}';
        }
      } else {
        connectionLabel = 'Connected on ${client.band}';
      }
    } else {
      connectionLabel = 'Connected on ${client.band}';
    }

    return Row(
      children: [
        Icon(LinksysIcons.wifi, size: 18, color: colors.onSurfaceVariant),
        const AppGap.small2(),
        Expanded(
          child: AppText.bodyMedium(
            connectionLabel,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _signalBar(BuildContext context, _SignalBadge badge, ColorScheme colors) {
    final color = _badgeTone(badge).color(context);
    final fraction = badge == _SignalBadge.good
        ? 1.0
        : badge == _SignalBadge.weak
            ? 0.55
            : 0.25;

    // Signal row as on the device detail page: colored level, then a meter.
    return AppListCard(
      padding: const EdgeInsets.all(Spacing.medium),
      title: AppText.labelLarge(
        'Signal: ${_badgeLabel(badge)}',
        color: color,
      ),
      description: Padding(
        padding: const EdgeInsets.only(top: Spacing.small2),
        child: ClipRRect(
          borderRadius: CustomTheme.of(context).radius.asBorderRadius().small,
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: Spacing.small2,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
    );
  }

  Widget _advice(BuildContext context, _SignalBadge badge) {
    if (!client.isWireless) {
      // Wired device advice — PRD spec: checklist + restart option
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.labelLarge('If this device has connection issues:'),
          const AppGap.small2(),
          _checklistItem(context, 'Check that the Ethernet cable is firmly plugged in at both ends'),
          _checklistItem(context, 'Try a different cable if available'),
          _checklistItem(context, 'Try a different port on your router'),
        ],
      );
    }

    switch (badge) {
      case _SignalBadge.poor:
        return const AppText.bodyMedium(
          'Move this device closer to your router, or move your router to a more central location.',
        );
      case _SignalBadge.weak:
        if (client.band.contains('2.4')) {
          return const AppText.bodyMedium(
            'Connect to the 5 GHz network for faster speeds — it has the same name and password.',
          );
        }
        final rate = client.txRateMbps;
        if (rate != null && rate < 30 && (client.signalDecibels ?? -90) >= -70) {
          return const AppText.bodyMedium(
            'Thick walls, metal objects, or appliances may be blocking the signal between this device and your router.',
          );
        }
        return const AppText.bodyMedium(
          'Move this device closer to your router, or move your router to a more central location.',
        );
      case _SignalBadge.good:
        return const AppText.bodyMedium(
          'This device has a strong WiFi connection.',
        );
      case _SignalBadge.wired:
        return const SizedBox.shrink(); // handled above
    }
  }

  Widget _deviceMeta(BuildContext context, ColorScheme colors) {
    final rows = <Widget>[];
    if (client.ipAddress != null) {
      rows.add(_metaRow('IP', client.ipAddress!));
    }
    rows.add(_metaRow('MAC', client.macAddress));
    final leaseMin = widget.state.dhcpLeaseMinutes;
    if (leaseMin != null && leaseMin > 0) {
      final hours = (leaseMin / 60).ceil();
      rows.add(_metaRow('Connected',
          'Within the last ${hours == 1 ? "hour" : "$hours hours"}'));
    } else {
      rows.add(_metaRow('Status', 'Connected now'));
    }
    // One setting card per field, as on the device detail page.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const AppGap.small2(),
          rows[i],
        ],
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return AppSettingCard(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.large2, vertical: Spacing.medium),
      title: label,
      description: value,
      selectableDescription: true,
    );
  }

  Widget _actions(BuildContext context, ColorScheme colors) {
    final badge = _badgeFor(client);
    final isWeak = badge == _SignalBadge.poor || badge == _SignalBadge.weak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Troubleshoot
        AppOutlinedButton('Troubleshoot this device',
                onTap: () {
            Navigator.pop(context);
            if (onNavigateToFlow != null) {
              onNavigateToFlow!(30, device: client); // 30 = Flow 3 pre-connected
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: AppText.bodyMedium(
                      'Go to Help Me Fix It → Device connectivity issues',
                      color: colors.onInverseSurface),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
                icon: LinksysIcons.resetWrench),

        // Disconnect/Reconnect — useful for weak signal devices and all wireless
        if (client.isWireless) ...[
          const AppGap.small2(),
          _isDisconnecting
              // Disabled kit button while the request runs.
              ? const AppOutlinedButton('Disconnecting…',
                  icon: LinksysIcons.signalWifiOff)
              : AppOutlinedButton('Disconnect and reconnect this device',
                onTap: () => _disconnectDevice(context),
                icon: LinksysIcons.signalWifiOff),
          if (isWeak)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.small1),
              child: AppText.bodySmall(
                'Reconnecting forces the device to re-select its WiFi connection, '
                'which can improve a weak signal.',
                color: colors.onSurfaceVariant,
              ),
            ),
        ],

        // Channel change — shown when channel data is available and signal is weak
        if (isWeak && state.channelInfo != null) ...[
          const AppGap.small2(),
          _isChangingChannel
              ? const AppOutlinedButton('Changing channel…',
                  icon: LinksysIcons.wifi)
              : AppOutlinedButton('Try a cleaner WiFi channel',
                onTap: () => _triggerChannelRescan(context),
                icon: LinksysIcons.wifi),
        ],
      ],
    );
  }

  Future<void> _disconnectDevice(BuildContext context) async {
    await confirmAndDeauth(
      context,
      ref,
      mac: client.macAddress,
      displayName: client.displayNameWithOui,
      onProgress: (busy) {
        if (mounted) setState(() => _isDisconnecting = busy);
      },
    );
  }

  Future<void> _triggerChannelRescan(BuildContext context) async {
    // Real firmware RF scan picks the clearest channels (not a hardcoded 6/36).
    final snackTextColor = Theme.of(context).colorScheme.onInverseSurface;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const AppText.titleMedium('Optimize WiFi channels?'),
        content: const AppText.bodyMedium(
            'Your router will scan for the clearest WiFi channels and switch '
            'automatically. This takes about a minute, and devices may briefly '
            'disconnect and reconnect.'),
        actions: [
          AppTextButton('Cancel',
                onTap: () => Navigator.pop(ctx, false)),
          AppFilledButton('Optimize',
                onTap: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isChangingChannel = true);
    final result = await ref
        .read(instantVerifyPivotProvider.notifier)
        .optimizeChannels();
    if (!mounted) return;
    setState(() => _isChangingChannel = false);
    final msg = switch (result.status) {
      ChannelOptimizeStatus.optimized =>
        'WiFi channels optimized. Devices will reconnect in a moment.',
      ChannelOptimizeStatus.alreadyOptimal =>
        'Your WiFi is already on the clearest channels.',
      ChannelOptimizeStatus.error =>
        'Couldn\'t optimize right now — please try again in a moment.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: AppText.bodyMedium(msg, color: snackTextColor),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _checklistItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Non-interactive bullet. Was Icons.check_box_outline_blank, which
          // looked like a tappable checkbox but had no handler (J-09).
          Padding(
            padding: const EdgeInsets.only(top: 6, right: Spacing.small2),
            child: Icon(LinksysIcons.circle, size: 6,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Expanded(child: AppText.bodyMedium(text)),
        ],
      ),
    );
  }
}
