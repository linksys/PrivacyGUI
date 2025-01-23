import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

class AdministrationSettingsView extends ArgumentsConsumerStatefulView {
  const AdministrationSettingsView({super.key, super.args});

  @override
  ConsumerState<AdministrationSettingsView> createState() =>
      _AdministrationSettingsViewState();
}

class _AdministrationSettingsViewState
    extends ConsumerState<AdministrationSettingsView> {
  AdministrationSettingsState? _preservedState;

  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(context,
            ref.read(administrationSettingsProvider.notifier).fetch(true))
        .then((value) {
      setState(() {
        _preservedState = value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(administrationSettingsProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).administration,
      onBackTap: _preservedState != state
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                ref.read(administrationSettingsProvider.notifier).fetch();
                context.pop();
              }
            }
          : null,
      bottomBar: PageBottomBar(
          isPositiveEnabled:
              _preservedState != null && _preservedState != state,
          onPositiveTap: () {
            doSomethingWithSpinner(
                context,
                ref
                    .read(administrationSettingsProvider.notifier)
                    .save()
                    .then((value) {
                  _preservedState = value;
                  showSuccessSnackBar(context, loc(context).saved);
                }).onError((error, stackTrace) {
                  showFailedSnackBar(
                      context, loc(context).unknownErrorCode(error ?? ''));
                }));
          }),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.managementSettings.isManageWirelesslySupported &&
                state.canDisAllowLocalMangementWirelessly) ...[
              AppCard(
                child: AppSwitchTriggerTile(
                  semanticLabel: 'allow local management wirelessly',
                  title: AppText.labelLarge(loc(context)
                      .administrationAllowLocalManagementWirelessly),
                  value: state.managementSettings.canManageWirelessly ?? false,
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
                    semanticLabel: 'upnp',
                    title: AppText.labelLarge(loc(context).upnp),
                    value: state.isUPnPEnabled,
                    onChanged: (value) {
                      ref
                          .read(administrationSettingsProvider.notifier)
                          .setUPnPEnabled(value);
                    },
                  ),
                  if (state.isUPnPEnabled) ...[
                    const Divider(),
                    AppCheckbox(
                      value: state.canUsersConfigure,
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
                      value: state.canUsersDisableWANAccess,
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
                semanticLabel: 'application layer gateway',
                title: AppText.labelLarge(
                    loc(context).administrationApplicationLayerGateway),
                value: state.enabledALG,
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
                semanticLabel: 'express forwarding',
                title: AppText.labelLarge(
                    loc(context).administrationExpressForwarding),
                value: state.enabledExpressForwarfing,
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
      ),
    );
  }
}
