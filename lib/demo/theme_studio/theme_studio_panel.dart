import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';

import 'tabs/design_tab.dart';
import 'tabs/palette_tab.dart';
import 'tabs/status_tab.dart';
import 'tabs/components_tab.dart';
import 'tabs/topology_tab.dart';

/// The dedicated settings panel content.
class ThemeStudioPanel extends ConsumerStatefulWidget {
  const ThemeStudioPanel({super.key});

  @override
  ConsumerState<ThemeStudioPanel> createState() => _ThemeStudioPanelState();
}

class _ThemeStudioPanelState extends ConsumerState<ThemeStudioPanel> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(demoThemeConfigProvider);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header with Actions
            _buildHeader(context),
            const AppDivider(),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: AppTabs(
                initialIndex: _selectedTabIndex,
                isScrollable: true,
                displayMode: TabDisplayMode.underline,
                tabs: const [
                  TabItem(label: 'Design', icon: Icons.brush_outlined),
                  TabItem(label: 'Palette', icon: Icons.palette_outlined),
                  TabItem(label: 'Status', icon: Icons.traffic_outlined),
                  TabItem(label: 'Components', icon: Icons.extension_outlined),
                  TabItem(label: 'Topology', icon: Icons.hub_outlined),
                ],
                onTabChanged: (index) {
                  setState(() => _selectedTabIndex = index);
                },
              ),
            ),
            const AppDivider(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildTabContent(context, config),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const AppText(
            'Theme Studio',
            variant: AppTextVariant.titleMedium,
            fontWeight: FontWeight.bold,
          ),
          const Spacer(),
          AppIconButton.icon(
            icon: AppIcon.font(Icons.download_outlined, size: 20),
            tooltip: 'Import Config',
            onTap: () => _showImportDialog(context),
          ),
          AppIconButton.icon(
            icon: AppIcon.font(Icons.upload_outlined, size: 20),
            tooltip: 'Export Config',
            onTap: () => _showExportDialog(context),
          ),
          AppIconButton.icon(
            icon: AppIcon.font(Icons.refresh_outlined, size: 20),
            tooltip: 'Reset to Defaults',
            onTap: () {
              ref.read(demoThemeConfigProvider.notifier).reset();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, DemoThemeConfig config) {
    switch (_selectedTabIndex) {
      case 0:
        return const DesignTab();
      case 1:
        return const PaletteTab();
      case 2:
        return const StatusTab();
      case 3:
        return const ComponentsTab();
      case 4:
        return const TopologyTab();
      default:
        return const SizedBox();
    }
  }

  void _showExportDialog(BuildContext context) {
    final config = ref.read(demoThemeConfigProvider);
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(config.toJson());
    final dialogContext = routerKey.currentContext ?? context;

    showDialog(
      useRootNavigator: true,
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Configuration'),
          content: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          actions: [
            AppButton.text(
              label: 'Close',
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            AppButton.primary(
              label: 'Copy to Clipboard',
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: jsonString));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('Config copied to clipboard!')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    final dialogContext = routerKey.currentContext ?? context;

    showDialog(
      useRootNavigator: true,
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste JSON here...',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.text(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  AppButton.primary(
                    label: 'Import',
                    onTap: () {
                      try {
                        final json = jsonDecode(controller.text);
                        ref
                            .read(demoThemeConfigProvider.notifier)
                            .importConfig(json);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Theme imported!')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('Invalid JSON: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
