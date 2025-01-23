import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
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
    extends ConsumerState<WifiAdvancedSettingsView> with PageSnackbarMixin {
  WifiAdvancedSettingsState? _preservedState;

  @override
  void initState() {
    super.initState();

    ref.read(wifiAdvancedProvider.notifier).fetch().then(
      (state) {
        setState(
          () {
            _preservedState = state;
            ref
                .read(wifiViewProvider.notifier)
                .setWifiAdvancedSettingsViewChanged(state != _preservedState);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(wifiAdvancedProvider, (previous, next) {
      if (_preservedState != null) {
        ref
            .read(wifiViewProvider.notifier)
            .setWifiAdvancedSettingsViewChanged(next != _preservedState);
      }
    });
    final isPositiveEnabled =
        _preservedState != ref.watch(wifiAdvancedProvider);

    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      useMainPadding: false,
      bottomBar: PageBottomBar(
          isPositiveEnabled: isPositiveEnabled,
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
          success(state);
        },
      ),
    ).catchError((error) {
      routerNotFound();
    }, test: (error) => error is JNAPSideEffectError).onError(
        (error, stackTrace) {
      showErrorMessageSnackBar(error);
    });
  }

  void routerNotFound() {
    showRouterNotFoundAlert(context, ref, onComplete: () {
      ref.read(wifiAdvancedProvider.notifier).fetch(true).then((state) {
        success(state);
      });
    });
  }

  void success(WifiAdvancedSettingsState state) {
    setState(() {
      _preservedState = state;
      ref
          .read(wifiViewProvider.notifier)
          .setWifiAdvancedSettingsViewChanged(false);
    });
    showChangesSavedSnackBar();
  }

  Widget _buildGrid() {
    final state = ref.watch(wifiAdvancedProvider);
    final advancedSettingWidgets = [
      if (state.isClientSteeringEnabled != null)
        _buildClientSteering(state.isClientSteeringEnabled!),
      if (state.isNodesSteeringEnabled != null)
        _buildNodeSteering(state.isNodesSteeringEnabled!),
      if (state.isDFSEnabled != null) _buildDFS(state.isDFSEnabled!),
      if (state.isMLOEnabled != null) _buildMLO(state.isMLOEnabled!),
      if (state.isIptvEnabled != null) _buildIptv(state.isIptvEnabled!),
    ];
    return MasonryGridView.count(
      crossAxisCount: ResponsiveLayout.isMobileLayout(context) ? 1 : 2,
      mainAxisSpacing: Spacing.small2,
      crossAxisSpacing: ResponsiveLayout.columnPadding(context),
      itemCount: advancedSettingWidgets.length,
      itemBuilder: (context, index) => advancedSettingWidgets[index],
    );
  }

  Widget _buildClientSteering(bool isEnabled) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: AppText.labelLarge(loc(context).clientSteering),
        semanticLabel: 'client steering',
        description: AppText.bodyMedium(loc(context).clientSteeringDesc),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          ref
              .read(wifiAdvancedProvider.notifier)
              .setClientSteeringEnabled(value);
        },
      ),
    );
  }

  Widget _buildNodeSteering(bool isEnabled) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.large2),
      child: AppSwitchTriggerTile(
        title: AppText.labelLarge(loc(context).nodeSteering),
        semanticLabel: 'node steering',
        description: AppText.bodyMedium(loc(context).nodeSteeringDesc),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          ref
              .read(wifiAdvancedProvider.notifier)
              .setNodesSteeringEnabled(value);
        },
      ),
    );
  }

  Widget _buildIptv(bool isEnabled) {
    return AppCard(
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
          ref.read(wifiAdvancedProvider.notifier).setIptvEnabled(value);
        },
      ),
    );
  }

  Widget _buildDFS(bool isEnabled) {
    return AppCard(
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
              _showDFSModal();
            }
          },
        ),
        value: isEnabled,
        toggleInCenter: true,
        onChanged: (value) {
          ref.read(wifiAdvancedProvider.notifier).setDFSEnabled(value);
        },
      ),
    );
  }

  Widget _buildMLO(bool isEnabled) {
    final wifiList = ref.read(wifiListProvider).mainWiFi;
    bool showMLOWarning = ref
        .read(wifiListProvider.notifier)
        .checkingMLOSettingsConflicts(
            Map.fromIterables(wifiList.map((e) => e.radioID), wifiList));
    return AppCard(
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
          ref.read(wifiAdvancedProvider.notifier).setMLOEnabled(value);
        },
      ),
    );
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
