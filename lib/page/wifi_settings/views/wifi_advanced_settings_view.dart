import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
            horizontal:
                context.isMobileLayout ? AppSpacing.lg : AppSpacing.xxl),
        child: MasonryGridView.count(
          crossAxisCount: context.isMobileLayout ? 1 : 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: context.colWidth(1),
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: _WifiSwitchTile(
        title: AppText.labelLarge(loc(context).clientSteering),
        description: AppText.bodyMedium(loc(context).clientSteeringDesc),
        value: isEnabled,
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: _WifiSwitchTile(
        title: AppText.labelLarge(loc(context).nodeSteering),
        description: AppText.bodyMedium(loc(context).nodeSteeringDesc),
        value: isEnabled,
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: _WifiSwitchTile(
        title: AppText.labelLarge('IPTV'),
        subtitle: AppText.labelSmall(
            'Please check with your ISP if IPTV service is compatible with this router.'),
        description: AppText.bodySmall(
            'IPTV subscribers should turn this feature ON to get the most out of the service. Depending on your network configuration, you might have to reconnect some devices.'),
        value: isEnabled,
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: _WifiSwitchTile(
        title: AppText.labelLarge(loc(context).dfs),
        description: _buildDFSDescription(context),
        value: isEnabled,
        onChanged: (value) {
          notifier.setDFSEnabled(value);
        },
      ),
    );
  }

  Widget _buildDFSDescription(BuildContext context) {
    return AppStyledText(
      text: loc(context).dfsDesc,
      onTapHandlers: {
        'a': () => _showDFSModal(context),
      },
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
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: _WifiSwitchTile(
        title: AppText.labelLarge(loc(context).mlo),
        description: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).mloDesc),
            if (showMLOWarning) ...[
              AppGap.md(),
              AppText.labelLarge(loc(context).mloWarning),
            ],
          ],
        ),
        value: isEnabled,
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

class _WifiSwitchTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _WifiSwitchTile({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: title),
            AppSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
        if (subtitle != null) ...[
          AppGap.xs(),
          subtitle!,
        ],
        AppGap.md(),
        description,
      ],
    );
  }
}
