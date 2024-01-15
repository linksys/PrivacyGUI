import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/wifi_setting/wifi_advanced_provider.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/buttons/button.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';

class WifiAdvancedSettingsView extends ArgumentsConsumerStatefulView {
  const WifiAdvancedSettingsView({super.key});

  @override
  ConsumerState<WifiAdvancedSettingsView> createState() =>
      _WifiAdvancedSettingsViewState();
}

class _WifiAdvancedSettingsViewState
    extends ConsumerState<WifiAdvancedSettingsView> {
  bool? _isClientSteeringEnabled;
  bool? _isNodeSteeringEnabled;
  bool? _isIptvEnabled;
  bool? _isMLOEnabled;
  bool? _isDFSEnabled;
  bool? _isAirtimeFairnessEnabled;

  @override
  void initState() {
    super.initState();
    ref.read(wifiAdvancedProvider.notifier).fetch().then((value) {
      final state = ref.read(wifiAdvancedProvider);
      setState(() {
        _isClientSteeringEnabled = state.isClientSteeringEnabled;
        _isNodeSteeringEnabled = state.isNodesSteeringEnabled;
        _isIptvEnabled = state.isIptvEnabled;
        _isMLOEnabled = state.isMLOEnabled;
        _isDFSEnabled = state.isDFSEnabled;
        _isAirtimeFairnessEnabled = state.isAirtimeFairnessEnabled;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      actions: [
        AppTextButton.noPadding(
          'Save',
          onTap: () {
            ref.read(wifiAdvancedProvider.notifier).save(
                  isClientSteeringEnabled: _isClientSteeringEnabled,
                  isNodeSteeringEnabled: _isNodeSteeringEnabled,
                  isDFSEnabled: _isDFSEnabled,
                  isMLOEnabled: _isMLOEnabled,
                  isIptvEnabled: _isIptvEnabled,
                  isAirtimeFairnessEnabled: _isAirtimeFairnessEnabled,
                );
          },
        ),
      ],
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final column =
            width < 720 ? 1 : (ResponsiveLayout.isMobile(context) ? 1 : 2);
        return _buildGrid(column: column, width: width);
      }),
    );
  }

  Widget _buildGrid({int column = 1, required double width}) {
    return GridView.count(
      crossAxisCount: column,
      childAspectRatio: column == 1 ? (width < 550 ? 1.6 : 2.4) : 1.2,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      children: [
        if (_isClientSteeringEnabled != null)
          AppSwitchTriggerTile(
            title: const AppText.labelLarge('Client Steering'),
            description: const AppText.bodySmall(
                'Let your network direct your wireless devices to the node with the strongest signal.'),
            value: _isClientSteeringEnabled!,
            showSwitchIcon: true,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground)),
            padding: const EdgeInsets.all(Spacing.big),
            onChanged: (value) {
              setState(() {
                _isClientSteeringEnabled = value;
              });
            },
          ),
        if (_isNodeSteeringEnabled != null)
          AppSwitchTriggerTile(
            title: const AppText.labelLarge('Node Steering'),
            description: const AppText.bodySmall(
                'Allow your nodes to always connect to the node with the strongest signal. If you moce a node or one goes offline, any connected nodes will self-heal by connecting to the strongest signal available.'),
            value: _isNodeSteeringEnabled!,
            showSwitchIcon: true,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground)),
            padding: const EdgeInsets.all(Spacing.big),
            onChanged: (value) {
              setState(() {
                _isNodeSteeringEnabled = value;
              });
            },
          ),
        if (_isIptvEnabled != null)
          AppSwitchTriggerTile(
            title: const AppText.labelLarge('IPTV'),
            subtitle: const AppText.labelSmall(
                'Please check with your ISP if IPTV service is compatible with this router.'),
            description: const AppText.bodySmall(
                'IPTV subscribers should turn this feature ON to get the most out of the service. Depending on your network configuration, you might have to reconnect some devices.'),
            value: _isIptvEnabled!,
            showSwitchIcon: true,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground)),
            padding: const EdgeInsets.all(Spacing.big),
            onChanged: (value) {
              setState(() {
                _isIptvEnabled = value;
              });
            },
          ),
        if (_isDFSEnabled != null)
          AppSwitchTriggerTile(
            title:
                const AppText.labelLarge('Dynamic Frequency Selection (DFS)'),
            description: const AppText.bodySmall(
                'If this feature is on, your router may use 5GHz channels that are shared with radar systems. When a radar is detected on your operating channel, the router will search for an unoccupied DFS channel. During this time, you may lose Wi-Fi connectivity. Another limitation is that some devices do not support DFS channels. They will need to use your 2.4GHz network because they cannot detect the 5GHz network when the router is using a DFS channel.'),
            value: _isDFSEnabled!,
            showSwitchIcon: true,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground)),
            padding: const EdgeInsets.all(Spacing.big),
            onChanged: (value) {
              setState(() {
                _isDFSEnabled = value;
              });
            },
          ),
        if (_isMLOEnabled != null)
          AppSwitchTriggerTile(
            title: const AppText.labelLarge('Multi-Link Operation (MLO)'),
            description: const AppText.bodySmall(
                'Allow devices to use multiple bands and frequency channels simultaneously. This increases speed, reduces latency, and makes for a more reliable connection.'),
            value: _isMLOEnabled!,
            showSwitchIcon: true,
            decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground)),
            padding: const EdgeInsets.all(Spacing.big),
            onChanged: (value) {
              setState(() {
                _isMLOEnabled = value;
              });
            },
          ),
      ],
    );
  }
}
