import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_app/page/wifi_settings/providers/wifi_view_provider.dart';
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
  bool _isLoading = false;
  WifiAdvancedSettingsState? _preservedState;

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    ref.read(wifiAdvancedProvider.notifier).fetch().then((value) {
      ref.read(wifiViewProvider.notifier).setChanged(false);
      final state = ref.read(wifiAdvancedProvider);
      setState(() {
        _preservedState = state;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wifiAdvancedProvider, (previous, next) {
      ref.read(wifiViewProvider.notifier).setChanged(next != _preservedState);
    });
    return _isLoading
        ? AppFullScreenSpinner(
            text: loc(context).processing,
          )
        : StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            bottomBar: PageBottomBar(
                isPositiveEnabled:
                    _preservedState != ref.read(wifiAdvancedProvider),
                onPositiveTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  ref.read(wifiAdvancedProvider.notifier).save().then((_) {
                    setState(() {
                      _isLoading = false;
                      ref.read(wifiViewProvider.notifier).setChanged(false);
                    });
                  });
                }),
            child: _buildGrid(),
          );
  }

  Widget _buildGrid() {
    final state = ref.watch(wifiAdvancedProvider);
    return ListView(
      children: [
        ..._buildClientSteering(state.isClientSteeringEnabled),
        ..._buildNodeSteering(state.isNodesSteeringEnabled),
        ..._buildIptv(state.isIptvEnabled),
        ..._buildDFS(state.isDFSEnabled),
        ..._buildMLO(state.isMLOEnabled),
      ],
    );
  }

  List<Widget> _buildClientSteering(bool? value) {
    return value != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).clientSteering),
              description: AppText.bodyMedium(loc(context).clientSteeringDesc),
              value: value,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                ref
                    .read(wifiAdvancedProvider.notifier)
                    .setClientSteeringEnabled(value);
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildNodeSteering(bool? value) {
    return value != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).nodeSteering),
              description: AppText.bodyMedium(loc(context).nodeSteeringDesc),
              value: value,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                ref
                    .read(wifiAdvancedProvider.notifier)
                    .setNodesSteeringEnabled(value);
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildIptv(bool? value) {
    return value != null
        ? [
            AppSwitchTriggerTile(
              title: const AppText.labelLarge('IPTV'),
              subtitle: const AppText.labelSmall(
                  'Please check with your ISP if IPTV service is compatible with this router.'),
              description: const AppText.bodySmall(
                  'IPTV subscribers should turn this feature ON to get the most out of the service. Depending on your network configuration, you might have to reconnect some devices.'),
              value: value,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                ref.read(wifiAdvancedProvider.notifier).setIptvEnabled(value);
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildDFS(bool? value) {
    return value != null
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
              value: value,
              showSwitchIcon: true,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                ref.read(wifiAdvancedProvider.notifier).setDFSEnabled(value);
              },
            ),
            const AppGap.regular()
          ]
        : [];
  }

  List<Widget> _buildMLO(bool? value) {
    return value != null
        ? [
            AppSwitchTriggerTile(
              title: AppText.labelLarge(loc(context).mlo),
              description: AppText.bodyMedium(loc(context).mloDesc),
              value: value,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(Spacing.big),
              toggleInCenter: true,
              onChanged: (value) {
                ref.read(wifiAdvancedProvider.notifier).setMLOEnabled(value);
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