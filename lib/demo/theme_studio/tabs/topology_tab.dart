import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/compact_color_picker.dart';

class TopologyTab extends ConsumerWidget {
  const TopologyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(demoThemeConfigProvider);
    final override = config.overrides?.component?.topology;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Expanded Live Preview ---
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            border:
                Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildTopologyPreview(context, override: override),
          ),
        ),
        const SizedBox(height: 24),

        // --- Link Style ---
        const SectionHeader(title: 'Link Animations & Colors'),
        const SizedBox(height: 16),
        _buildLinkStyleSection(context, ref, override),
        const SizedBox(height: 24),

        // --- Node Style ---
        const SectionHeader(title: 'Node Animations & Colors'),
        const SizedBox(height: 16),
        _buildNodeStyleSection(context, ref, override),
      ],
    );
  }

  Widget _buildTopologyPreview(BuildContext context,
      {TopologyColorOverride? override}) {
    final now = DateTime.now();

    final gw = MeshNode(
      id: 'gw',
      name: 'Gateway',
      type: MeshNodeType.gateway,
      status: MeshNodeStatus.online,
      signalQuality: SignalQuality.strong,
    );

    // Extender with Ethernet Backhaul
    final exEth = MeshNode(
      id: 'ex_eth',
      parentId: 'gw',
      name: 'Ex (Eth)',
      type: MeshNodeType.extender,
      status: MeshNodeStatus.online,
      signalQuality: SignalQuality.wired,
    );

    // Extender with WiFi Backhaul (Medium)
    final exWifi = MeshNode(
      id: 'ex_wifi',
      parentId: 'gw',
      name: 'Ex (WiFi)',
      type: MeshNodeType.extender,
      status: MeshNodeStatus.online,
      signalQuality: SignalQuality.medium,
    );

    // Client with Strong Signal
    final clStrong = MeshNode(
      id: 'cl_strong',
      parentId: 'ex_eth',
      name: 'Strong',
      type: MeshNodeType.client,
      status: MeshNodeStatus.online,
      signalQuality: SignalQuality.strong,
    );

    // Client with Weak Signal
    final clWeak = MeshNode(
      id: 'cl_weak',
      parentId: 'ex_wifi',
      name: 'Weak',
      type: MeshNodeType.client,
      status: MeshNodeStatus.online,
      signalQuality: SignalQuality.weak,
    );

    // Client with Medium Signal (Moved to Ex Eth to balance layout)
    final clMed = MeshNode(
      id: 'cl_med',
      parentId: 'ex_eth',
      name: 'Medium',
      type: MeshNodeType.client,
      status: MeshNodeStatus.online,
      signalQuality: SignalQuality.medium,
    );

    // Offline Client
    final clOff = MeshNode(
      id: 'cl_off',
      // parentId: 'gw',
      name: 'Offline',
      type: MeshNodeType.client,
      status: MeshNodeStatus.offline,
      signalQuality: SignalQuality.unknown,
    );

    final nodes = [gw, exEth, exWifi, clStrong, clWeak, clMed, clOff];
    final links = [
      MeshLink(
        sourceId: 'gw',
        targetId: 'ex_eth',
        connectionType: ConnectionType.ethernet,
        throughput: 1000,
      ),
      MeshLink(
        sourceId: 'gw',
        targetId: 'ex_wifi',
        connectionType: ConnectionType.wifi,
        rssi: -65, // Medium (-50 to -70)
        throughput: 150,
      ),
      MeshLink(
        sourceId: 'ex_eth',
        targetId: 'cl_strong',
        connectionType: ConnectionType.wifi,
        rssi: -40, // Strong > -50
        throughput: 300,
      ),
      MeshLink(
        sourceId: 'ex_wifi',
        targetId: 'cl_weak',
        connectionType: ConnectionType.wifi,
        rssi: -80, // Weak < -70
        throughput: 50,
      ),
      MeshLink(
        sourceId: 'ex_eth',
        targetId: 'cl_med',
        connectionType: ConnectionType.wifi,
        rssi: -60, // Medium (-50 to -70)
        throughput: 100,
      ),
    ];

    final topology = MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: now,
    );

    return AppTopology(
      key: ValueKey(override?.hashCode ?? 0),
      topology: topology,
      interactive: false,
      enableAnimation: true,
      viewMode: TopologyViewMode.graph,
    );
  }

  Widget _buildLinkStyleSection(
      BuildContext context, WidgetRef ref, TopologyColorOverride? override) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ethernet Row
        Row(
          children: [
            SizedBox(
              width: 100,
              child: AppText.labelMedium('Ethernet'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: LinkAnimationType.values.map((type) {
                  final isSelected = (override?.ethernetAnimationType ??
                          LinkAnimationType.none) ==
                      type;
                  return AppTag(
                    label: type.name.toUpperCase(),
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(demoThemeConfigProvider.notifier)
                          .updateTopologyColors(ethernetAnimationType: type);
                    },
                  );
                }).toList(),
              ),
            ),
            CompactColorPicker(
              label: 'Color',
              color: override?.ethernetLinkColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateTopologyColors(ethernetLinkColor: c),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // WiFi Row (Animations shared, colors split)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: AppText.labelMedium('WiFi'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: LinkAnimationType.values.map((type) {
                      final isSelected = (override?.wifiAnimationType ??
                              LinkAnimationType.none) ==
                          type;
                      return AppTag(
                        label: type.name.toUpperCase(),
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(demoThemeConfigProvider.notifier)
                              .updateTopologyColors(wifiAnimationType: type);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CompactColorPicker(
                        label: 'Strong',
                        color: override?.wifiStrongColor,
                        onChanged: (c) => ref
                            .read(demoThemeConfigProvider.notifier)
                            .updateTopologyColors(wifiStrongColor: c),
                      ),
                      CompactColorPicker(
                        label: 'Medium',
                        color: override?.wifiMediumColor,
                        onChanged: (c) => ref
                            .read(demoThemeConfigProvider.notifier)
                            .updateTopologyColors(wifiMediumColor: c),
                      ),
                      CompactColorPicker(
                        label: 'Weak',
                        color: override?.wifiWeakColor,
                        onChanged: (c) => ref
                            .read(demoThemeConfigProvider.notifier)
                            .updateTopologyColors(wifiWeakColor: c),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNodeStyleSection(
      BuildContext context, WidgetRef ref, TopologyColorOverride? override) {
    return Column(
      children: [
        _buildNodeConfigRow(
          context,
          'Gateway',
          override?.gatewayRenderer,
          (type) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateTopologyColors(gatewayRenderer: type),
          [
            CompactColorPicker(
              label: 'Bg',
              color: override?.gatewayNormalBackgroundColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateTopologyColors(gatewayNormalBackgroundColor: c),
            ),
            CompactColorPicker(
                label: 'Icon',
                color: override?.gatewayNormalIconColor,
                onChanged: (c) => ref
                    .read(demoThemeConfigProvider.notifier)
                    .updateTopologyColors(gatewayNormalIconColor: c)),
          ],
        ),
        const SizedBox(height: 16),
        _buildNodeConfigRow(
          context,
          'Extender',
          override?.extenderRenderer,
          (type) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateTopologyColors(extenderRenderer: type),
          [
            CompactColorPicker(
              label: 'Bg',
              color: override?.extenderNormalBackgroundColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateTopologyColors(extenderNormalBackgroundColor: c),
            ),
            CompactColorPicker(
                label: 'Icon',
                color: override?.extenderNormalIconColor,
                onChanged: (c) => ref
                    .read(demoThemeConfigProvider.notifier)
                    .updateTopologyColors(extenderNormalIconColor: c)),
          ],
        ),
        const SizedBox(height: 16),
        _buildNodeConfigRow(
          context,
          'Client',
          override?.clientRenderer,
          (type) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateTopologyColors(clientRenderer: type),
          [
            CompactColorPicker(
              label: 'Bg',
              color: override?.clientNormalBackgroundColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateTopologyColors(clientNormalBackgroundColor: c),
            ),
            CompactColorPicker(
                label: 'Icon',
                color: override?.clientNormalIconColor,
                onChanged: (c) => ref
                    .read(demoThemeConfigProvider.notifier)
                    .updateTopologyColors(clientNormalIconColor: c)),
          ],
        ),
      ],
    );
  }

  Widget _buildNodeConfigRow(
    BuildContext context,
    String label,
    MeshNodeRendererType? currentType,
    ValueChanged<MeshNodeRendererType> onTypeChanged,
    List<Widget> colorPickers,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: AppText.labelMedium(label)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MeshNodeRendererType.values.map((type) {
                  final isSelected =
                      (currentType ?? MeshNodeRendererType.ripple) == type;
                  return AppTag(
                    label: type.name.toUpperCase(),
                    isSelected: isSelected,
                    onTap: () => onTypeChanged(type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: colorPickers),
            ],
          ),
        ),
      ],
    );
  }
}
