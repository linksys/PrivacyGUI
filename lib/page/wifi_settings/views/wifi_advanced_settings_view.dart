import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class WifiAdvancedSettingsView extends ConsumerWidget {
  const WifiAdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The state is now read from the single bundle provider.
    final advancedState = ref.watch(
        wifiBundleProvider.select((state) => state.settings.current.advanced));
    return _buildGrid(context, ref, advancedState);
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, WifiAdvancedSettingsState state) {
    final notifier = ref.read(wifiBundleProvider.notifier);
    final advancedSettingWidgets = [
      if (state.isClientSteeringEnabled != null)
        _buildClientSteering(context, notifier, state.isClientSteeringEnabled!),
      if (state.isNodesSteeringEnabled != null)
        _buildNodeSteering(context, notifier, state.isNodesSteeringEnabled!),
      if (state.isDFSEnabled != null)
        _buildDFS(context, notifier, state.isDFSEnabled!),
      if (state.isMLOEnabled != null)
        _buildMLO(context, ref, notifier, state.isMLOEnabled!),
      if (state.isIptvEnabled != null)
        _buildIptv(context, notifier, state.isIptvEnabled!),
    ];
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: ResponsiveLayout.pageHorizontalPadding(context)),
        child: MasonryGridView.count(
          crossAxisCount: ResponsiveLayout.isMobileLayout(context) ? 1 : 2,
          mainAxisSpacing: Spacing.small2,
          crossAxisSpacing: ResponsiveLayout.columnPadding(context),
          itemCount: advancedSettingWidgets.length,
          itemBuilder: (context, index) => advancedSettingWidgets[index],
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  Widget _buildClientSteering(
      BuildContext context, WifiBundleNotifier notifier, bool isEnabled) {
    return AppCard(
      key: const Key('clientSteering'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: AppText.labelLarge(loc(context).clientSteering),
        semanticLabel: 'client steering',
        description: AppText.bodyMedium(loc(context).clientSteeringDesc),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          notifier.setClientSteeringEnabled(value);
        },
      ),
    );
  }

  Widget _buildNodeSteering(
      BuildContext context, WifiBundleNotifier notifier, bool isEnabled) {
    return AppCard(
      key: const Key('nodeSteering'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: AppText.labelLarge(loc(context).nodeSteering),
        semanticLabel: 'node steering',
        description: AppText.bodyMedium(loc(context).nodeSteeringDesc),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          notifier.setNodesSteeringEnabled(value);
        },
      ),
    );
  }

  Widget _buildIptv(
      BuildContext context, WifiBundleNotifier notifier, bool isEnabled) {
    return AppCard(
      key: const Key('iptv'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: const AppText.labelLarge('IPTV'),
        semanticLabel: 'IPTV',
        subtitle: const AppText.labelSmall(
            'Please check with your ISP if IPTV service is compatible with this router.'),
        description: const AppText.bodySmall(
            'IPTV subscribers should turn this feature ON to get the most out of the service. Depending on your network configuration, you might have to reconnect some devices.'),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          notifier.setIptvEnabled(value);
        },
      ),
    );
  }

  Widget _buildDFS(
      BuildContext context, WifiBundleNotifier notifier, bool isEnabled) {
    return AppCard(
      key: const Key('dfs'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: AppText.labelLarge(loc(context).dfs),
        semanticLabel: 'dfs',
        description: AppStyledText.bold(
          loc(context).dfsDesc,
          defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
          color: Theme.of(context).colorScheme.primary,
          tags: const ['a'],
          callbackTags: {
            'a': (String? text, Map<String?, String?> attrs) {
              _showDFSModal(context);
            }
          },
        ),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          notifier.setDFSEnabled(value);
        },
      ),
    );
  }

  Widget _buildMLO(BuildContext context, WidgetRef ref,
      WifiBundleNotifier notifier, bool isEnabled) {
    final wifiList = ref.watch(
        wifiBundleProvider.select((s) => s.settings.current.wifiList.mainWiFi));
    // This logic might need to be moved to the notifier itself to be a derived state (status)
    bool showMLOWarning = notifier.checkingMLOSettingsConflicts(
        Map.fromIterables(wifiList.map((e) => e.radioID), wifiList));
    return AppCard(
      key: const Key('mlo'),
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: AppText.labelLarge(loc(context).mlo),
        semanticLabel: 'mlo',
        description: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).mloDesc),
            if (showMLOWarning) ...[
              const AppGap.medium(),
              AppText.labelLarge(loc(context).mloWarning),
            ],
          ],
        ),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          notifier.setMLOEnabled(value);
        },
      ),
    );
  }

  void _showDFSModal(BuildContext context) {
    showMessageAppOkDialog(context,
        title: loc(context).dfs, message: loc(context).modalDFSDesc);
  }
}
