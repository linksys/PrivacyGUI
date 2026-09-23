import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/theme_studio_config_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/compact_color_picker.dart';

class TopologyTab extends ConsumerWidget {
  const TopologyTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(themeStudioConfigProvider);
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

    final gw = GraphNode(
      id: 'gw',
      name: 'Gateway',
      styleSlot: 'primary',
      status: NodeState.active,
    );

    // Extender with Ethernet Backhaul
    final exEth = GraphNode(
      id: 'ex_eth',
      parentId: 'gw',
      name: 'Ex (Eth)',
      styleSlot: 'secondary',
      status: NodeState.active,
    );

    // Extender with WiFi Backhaul (Medium)
    final exWifi = GraphNode(
      id: 'ex_wifi',
      parentId: 'gw',
      name: 'Ex (WiFi)',
      styleSlot: 'secondary',
      status: NodeState.active,
    );

    // Client with Strong Signal
    final clStrong = GraphNode(
      id: 'cl_strong',
      parentId: 'ex_eth',
      name: 'Strong',
      styleSlot: 'leaf',
      status: NodeState.active,
    );

    // Client with Weak Signal
    final clWeak = GraphNode(
      id: 'cl_weak',
      parentId: 'ex_wifi',
      name: 'Weak',
      styleSlot: 'leaf',
      status: NodeState.active,
    );

    // Client with Medium Signal (Moved to Ex Eth to balance layout)
    final clMed = GraphNode(
      id: 'cl_med',
      parentId: 'ex_eth',
      name: 'Medium',
      styleSlot: 'leaf',
      status: NodeState.active,
    );

    // Offline Client
    final clOff = GraphNode(
      id: 'cl_off',
      // parentId: 'gw',
      name: 'Offline',
      styleSlot: 'leaf',
      status: NodeState.inactive,
    );

    final nodes = [gw, exEth, exWifi, clStrong, clWeak, clMed, clOff];
    // One edge per authored style, so the preview shows every dial this tab can
    // change. Strengths are **stated** rather than implied by an RSSI: ui_kit
    // 3.4.0 stopped deriving them from dBm, which suits a theme preview — it was
    // always the resulting style this fixture cared about, not the radio reading
    // that happened to produce it. A direct edge states no strength, because none
    // is read for one.
    final edges = [
      GraphEdge(
        sourceId: 'gw',
        targetId: 'ex_eth',
        kind: EdgeKind.direct,
      ),
      GraphEdge(
        sourceId: 'gw',
        targetId: 'ex_wifi',
        kind: EdgeKind.indirect,
        strength: EdgeStrength.good,
      ),
      GraphEdge(
        sourceId: 'ex_eth',
        targetId: 'cl_strong',
        kind: EdgeKind.indirect,
        strength: EdgeStrength.strong,
      ),
      GraphEdge(
        sourceId: 'ex_wifi',
        targetId: 'cl_weak',
        kind: EdgeKind.indirect,
        strength: EdgeStrength.weak,
      ),
      GraphEdge(
        sourceId: 'ex_eth',
        targetId: 'cl_med',
        kind: EdgeKind.indirect,
        strength: EdgeStrength.good,
      ),
      // The kind-undeclared case, which has its own authored style and no flow
      // animation. It had no representation here before 3.4.0 made null the way
      // to say it.
      GraphEdge(
        sourceId: 'gw',
        targetId: 'cl_off',
      ),
    ];

    final topology = GraphData(
      nodes: nodes,
      edges: edges,
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
                children: EdgeAnimationType.values.map((type) {
                  final isSelected = (override?.directEdgeAnimationType ??
                          EdgeAnimationType.none) ==
                      type;
                  return AppTag(
                    label: type.name.toUpperCase(),
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(themeStudioConfigProvider.notifier)
                          .updateTopologyColors(directEdgeAnimationType: type);
                    },
                  );
                }).toList(),
              ),
            ),
            CompactColorPicker(
              label: 'Color',
              color: override?.directEdgeColor,
              onChanged: (c) => ref
                  .read(themeStudioConfigProvider.notifier)
                  .updateTopologyColors(directEdgeColor: c),
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
                    children: EdgeAnimationType.values.map((type) {
                      final isSelected = (override?.indirectEdgeAnimationType ??
                              EdgeAnimationType.none) ==
                          type;
                      return AppTag(
                        label: type.name.toUpperCase(),
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(themeStudioConfigProvider.notifier)
                              .updateTopologyColors(
                                  indirectEdgeAnimationType: type);
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
                        color: override?.strongEdgeColor,
                        onChanged: (c) => ref
                            .read(themeStudioConfigProvider.notifier)
                            .updateTopologyColors(strongEdgeColor: c),
                      ),
                      CompactColorPicker(
                        label: 'Medium',
                        color: override?.goodEdgeColor,
                        onChanged: (c) => ref
                            .read(themeStudioConfigProvider.notifier)
                            .updateTopologyColors(goodEdgeColor: c),
                      ),
                      CompactColorPicker(
                        label: 'Weak',
                        color: override?.weakEdgeColor,
                        onChanged: (c) => ref
                            .read(themeStudioConfigProvider.notifier)
                            .updateTopologyColors(weakEdgeColor: c),
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
          override?.primaryRenderer,
          (type) => ref
              .read(themeStudioConfigProvider.notifier)
              .updateTopologyColors(primaryRenderer: type),
          [
            CompactColorPicker(
              label: 'Bg',
              color: override?.gatewayNormalBackgroundColor,
              onChanged: (c) => ref
                  .read(themeStudioConfigProvider.notifier)
                  .updateTopologyColors(gatewayNormalBackgroundColor: c),
            ),
            CompactColorPicker(
                label: 'Icon',
                color: override?.gatewayNormalIconColor,
                onChanged: (c) => ref
                    .read(themeStudioConfigProvider.notifier)
                    .updateTopologyColors(gatewayNormalIconColor: c)),
          ],
        ),
        const SizedBox(height: 16),
        _buildNodeConfigRow(
          context,
          'Extender',
          override?.secondaryRenderer,
          (type) => ref
              .read(themeStudioConfigProvider.notifier)
              .updateTopologyColors(secondaryRenderer: type),
          [
            CompactColorPicker(
              label: 'Bg',
              color: override?.extenderNormalBackgroundColor,
              onChanged: (c) => ref
                  .read(themeStudioConfigProvider.notifier)
                  .updateTopologyColors(extenderNormalBackgroundColor: c),
            ),
            CompactColorPicker(
                label: 'Icon',
                color: override?.extenderNormalIconColor,
                onChanged: (c) => ref
                    .read(themeStudioConfigProvider.notifier)
                    .updateTopologyColors(extenderNormalIconColor: c)),
          ],
        ),
        const SizedBox(height: 16),
        _buildNodeConfigRow(
          context,
          'Client',
          override?.leafRenderer,
          (type) => ref
              .read(themeStudioConfigProvider.notifier)
              .updateTopologyColors(leafRenderer: type),
          [
            CompactColorPicker(
              label: 'Bg',
              color: override?.clientNormalBackgroundColor,
              onChanged: (c) => ref
                  .read(themeStudioConfigProvider.notifier)
                  .updateTopologyColors(clientNormalBackgroundColor: c),
            ),
            CompactColorPicker(
                label: 'Icon',
                color: override?.clientNormalIconColor,
                onChanged: (c) => ref
                    .read(themeStudioConfigProvider.notifier)
                    .updateTopologyColors(clientNormalIconColor: c)),
          ],
        ),
      ],
    );
  }

  Widget _buildNodeConfigRow(
    BuildContext context,
    String label,
    NodeRendererType? currentType,
    ValueChanged<NodeRendererType> onTypeChanged,
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
                children: NodeRendererType.values.map((type) {
                  final isSelected =
                      (currentType ?? NodeRendererType.ripple) == type;
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
