import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class AdministrationSettingsView extends ArgumentsConsumerStatefulView {
  const AdministrationSettingsView({super.key, super.args});

  @override
  ConsumerState<AdministrationSettingsView> createState() =>
      _AdministrationSettingsViewState();
}

class _AdministrationSettingsViewState
    extends ConsumerState<AdministrationSettingsView> {
  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
        context,
        ref
            .read(administrationSettingsProvider.notifier)
            .fetch(forceRemote: true));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(administrationSettingsProvider);
    return StyledAppPageView.withSliver(
      scrollable: true,
      title: loc(context).administration,
      bottomBar: PageBottomBar(
          isPositiveEnabled: state.isDirty,
          onPositiveTap: () {
            doSomethingWithSpinner(
                context,
                ref
                    .read(administrationSettingsProvider.notifier)
                    .save()
                    .then((value) {
                  if (context.mounted) {
                    showSuccessSnackBar(context, loc(context).saved);
                  }
                }).onError((error, stackTrace) {
                  if (context.mounted) {
                    showFailedSnackBar(
                        context, loc(context).unknownErrorCode(error ?? ''));
                  }
                }));
          }),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.current.managementSettings.isManageWirelesslySupported &&
              state.current.canDisAllowLocalMangementWirelessly) ...[
            AppCard(
              child: AppSwitchTriggerTile(
                key: const Key('wirelessManagementSwitch'),
                semanticLabel: 'allow local management wirelessly',
                title: AppText.labelLarge(
                    loc(context).administrationAllowLocalManagementWirelessly),
                value: state.current.managementSettings.canManageWirelessly ??
                    false,
                onChanged: (value) {
                  ref
                      .read(administrationSettingsProvider.notifier)
                      .setManagementSettings(value);
                },
              ),
            ),
            const AppGap.small2(),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSwitchTriggerTile(
                  key: const Key('upnpSwitch'),
                  semanticLabel: 'upnp',
                  title: AppText.labelLarge(loc(context).upnp),
                  value: state.current.isUPnPEnabled,
                  onChanged: (value) {
                    ref
                        .read(administrationSettingsProvider.notifier)
                        .setUPnPEnabled(value);
                  },
                ),
                if (state.current.isUPnPEnabled) ...[
                  const Divider(),
                  AppCheckbox(
                    key: const Key('upnpConfigureCheckbox'),
                    value: state.current.canUsersConfigure,
                    semanticLabel: 'upnp allow users configure',
                    text: loc(context).administrationUPnPAllowUsersConfigure,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      ref
                          .read(administrationSettingsProvider.notifier)
                          .setCanUsersConfigure(value);
                    },
                  ),
                  const AppGap.small2(),
                  AppCheckbox(
                    key: const Key('upnpDisableWANAccessCheckbox'),
                    value: state.current.canUsersDisableWANAccess,
                    semanticLabel: 'upnp allow users disable internet access',
                    text: loc(context)
                        .administrationUPnPAllowUsersDisableInternetAccess,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      ref
                          .read(administrationSettingsProvider.notifier)
                          .setCanUsersDisableWANAccess(value);
                    },
                  ),
                ],
              ],
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              key: const Key('algSwitch'),
              semanticLabel: 'application layer gateway',
              title: AppText.labelLarge(
                  loc(context).administrationApplicationLayerGateway),
              value: state.current.enabledALG,
              onChanged: (value) {
                ref
                    .read(administrationSettingsProvider.notifier)
                    .setALGEnabled(value);
              },
            ),
          ),
          const AppGap.small2(),
          AppCard(
            child: AppSwitchTriggerTile(
              key: const Key('expressForwardingSwitch'),
              semanticLabel: 'express forwarding',
              title: AppText.labelLarge(
                  loc(context).administrationExpressForwarding),
              value: state.current.enabledExpressForwarfing,
              onChanged: (value) {
                ref
                    .read(administrationSettingsProvider.notifier)
                    .setExpressForwarding(value);
              },
            ),
          ),
          const AppGap.small2(),
        ],
      ),
    );
  }
}
