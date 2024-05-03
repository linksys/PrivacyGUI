import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    ref.read(wifiAdvancedProvider.notifier).fetch().then((value) {
      final state = ref.read(wifiAdvancedProvider);
      setState(() {
        _isClientSteeringEnabled = state.isClientSteeringEnabled;
        _isNodeSteeringEnabled = state.isNodesSteeringEnabled;
        _isIptvEnabled = state.isIptvEnabled;
        _isMLOEnabled = state.isMLOEnabled;
        _isDFSEnabled = state.isDFSEnabled;
        _isAirtimeFairnessEnabled = state.isAirtimeFairnessEnabled;

        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? AppFullScreenSpinner(
            text: loc(context).processing,
          )
        : StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            saveAction: SaveAction(
                enabled: true,
                onSave: () {
                  ref.read(wifiAdvancedProvider.notifier).save(
                        isClientSteeringEnabled: _isClientSteeringEnabled,
                        isNodeSteeringEnabled: _isNodeSteeringEnabled,
                        isDFSEnabled: _isDFSEnabled,
                        isMLOEnabled: _isMLOEnabled,
                        isIptvEnabled: _isIptvEnabled,
                        isAirtimeFairnessEnabled: _isAirtimeFairnessEnabled,
                      );
                }),
            child: _buildGrid(),
          );
  }

  Widget _buildGrid() {
    return ListView(
      children: [
        ..._buildClientSteering(),
        ..._buildNodeSteering(),
        ..._buildIptv(),
        ..._buildDFS(),
        ..._buildMLO(),
      ],
    );
  }

  List<Widget> _buildClientSteering() {
    return _isClientSteeringEnabled != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).clientSteering),
              description: AppText.bodyMedium(loc(context).clientSteeringDesc),
              value: _isClientSteeringEnabled!,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                setState(() {
                  _isClientSteeringEnabled = value;
                });
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildNodeSteering() {
    return _isNodeSteeringEnabled != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).nodeSteering),
              description: AppText.bodyMedium(loc(context).nodeSteeringDesc),
              value: _isNodeSteeringEnabled!,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                setState(() {
                  _isNodeSteeringEnabled = value;
                });
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildIptv() {
    return _isIptvEnabled != null
        ? [
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
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                setState(() {
                  _isIptvEnabled = value;
                });
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildDFS() {
    return _isDFSEnabled != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).dfs),
              description: AppStyledText.bold(
                loc(context).dfsDesc,
                defaultTextStyle: Theme.of(context).textTheme.bodyLarge!,
                color: Theme.of(context).colorScheme.primary,
                tags: const ['a'],
                callbackTags: {
                  'a': (String? text, Map<String?, String?> attrs) {
                    _showDFSModal();
                  }
                },
              ),
              value: _isDFSEnabled!,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                setState(() {
                  _isDFSEnabled = value;
                });
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildMLO() {
    return _isMLOEnabled != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).mlo),
              description: AppText.bodyMedium(loc(context).mloDesc),
              value: _isMLOEnabled!,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                setState(() {
                  _isMLOEnabled = value;
                });
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  void _showDFSModal() {
    showMessageAppOkDialog(context,
        title: loc(context).dfs, message: loc(context).modalDFSDesc);
  }
}
