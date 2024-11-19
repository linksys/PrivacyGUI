import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class WifiAdvancedSettingsView extends ArgumentsConsumerStatefulView {
  const WifiAdvancedSettingsView({super.key});

  @override
  ConsumerState<WifiAdvancedSettingsView> createState() =>
      _WifiAdvancedSettingsViewState();
}

class _WifiAdvancedSettingsViewState
    extends ConsumerState<WifiAdvancedSettingsView> {
  WifiAdvancedSettingsState? _preservedState;

  @override
  void initState() {
    super.initState();

    ref.read(wifiAdvancedProvider.notifier).fetch().then(
      (state) {
        ref.read(wifiViewProvider.notifier).setChanged(false);
        setState(
          () {
            _preservedState = state;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wifiAdvancedProvider, (previous, next) {
      ref.read(wifiViewProvider.notifier).setChanged(next != _preservedState);
    });
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      useMainPadding: false,
      bottomBar: PageBottomBar(
          isPositiveEnabled: _preservedState != ref.read(wifiAdvancedProvider),
          onPositiveTap: () {
            if (ref.read(wifiAdvancedProvider).isDFSEnabled == true) {
              _showConfirmDFSModal().then((value) {
                if (value == true) {
                  save();
                }
              });
            } else {
              save();
            }
          }),
      child: _buildGrid(),
    );
  }

  Future save() {
    return doSomethingWithSpinner(
      context,
      ref.read(wifiAdvancedProvider.notifier).save().then(
        (state) {
          setState(() {
            ref.read(wifiViewProvider.notifier).setChanged(false);
            _preservedState = state;
          });
        },
      ),
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
            AppCard(
              padding: const EdgeInsets.all(Spacing.large2),
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).clientSteering),
                semanticLabel: 'client steering',
                description:
                    AppText.bodyMedium(loc(context).clientSteeringDesc),
                value: value,
                toggleInCenter: true,
                onChanged: (value) {
                  ref
                      .read(wifiAdvancedProvider.notifier)
                      .setClientSteeringEnabled(value);
                },
              ),
            ),
            const AppGap.small2()
          ]
        : [];
  }

  List<Widget> _buildNodeSteering(bool? value) {
    return value != null
        ? [
            AppCard(
              padding: const EdgeInsets.all(Spacing.large2),
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).nodeSteering),
                semanticLabel: 'node steering',
                description: AppText.bodyMedium(loc(context).nodeSteeringDesc),
                value: value,
                toggleInCenter: true,
                onChanged: (value) {
                  ref
                      .read(wifiAdvancedProvider.notifier)
                      .setNodesSteeringEnabled(value);
                },
              ),
            ),
            const AppGap.small2()
          ]
        : [];
  }

  List<Widget> _buildIptv(bool? value) {
    return value != null
        ? [
            AppCard(
              padding: const EdgeInsets.all(Spacing.large2),
              child: AppSwitchTriggerTile(
                title: const AppText.labelLarge('IPTV'),
                semanticLabel: 'IPTV',
                subtitle: const AppText.labelSmall(
                    'Please check with your ISP if IPTV service is compatible with this router.'),
                description: const AppText.bodySmall(
                    'IPTV subscribers should turn this feature ON to get the most out of the service. Depending on your network configuration, you might have to reconnect some devices.'),
                value: value,
                toggleInCenter: true,
                onChanged: (value) {
                  ref.read(wifiAdvancedProvider.notifier).setIptvEnabled(value);
                },
              ),
            ),
            const AppGap.small2()
          ]
        : [];
  }

  List<Widget> _buildDFS(bool? value) {
    return value != null
        ? [
            AppCard(
              padding: const EdgeInsets.all(Spacing.large2),
              child: AppSwitchTriggerTile(
                title: AppText.labelLarge(loc(context).dfs),
                semanticLabel: 'dfs',
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
                toggleInCenter: true,
                onChanged: (value) {
                  ref.read(wifiAdvancedProvider.notifier).setDFSEnabled(value);
                },
              ),
            ),
            const AppGap.small2()
          ]
        : [];
  }

  List<Widget> _buildMLO(bool? value) {
    final wifiList = ref.read(wifiListProvider).mainWiFi;
    bool showMLOWarning = ref
        .read(wifiListProvider.notifier)
        .checkingMLOSettingsConflicts(
            Map.fromIterables(wifiList.map((e) => e.radioID), wifiList));
    return value != null
        ? [
            AppCard(
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
                value: value,
                toggleInCenter: true,
                onChanged: (value) {
                  ref.read(wifiAdvancedProvider.notifier).setMLOEnabled(value);
                },
              ),
            ),
            const AppGap.small2()
          ]
        : [];
  }

  void _showDFSModal() {
    showMessageAppOkDialog(context,
        title: loc(context).dfs, message: loc(context).modalDFSDesc);
  }

  Future<bool?> _showConfirmDFSModal() {
    return showMessageAppDialog(context,
        title: loc(context).dfs,
        message: loc(context).modalDFSDesc,
        actions: [
          AppTextButton(
            loc(context).cancel,
            onTap: () {
              context.pop();
            },
          ),
          AppTextButton(
            loc(context).ok,
            onTap: () {
              context.pop(true);
            },
          ),
        ]);
  }
}
