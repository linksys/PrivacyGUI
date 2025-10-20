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
  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
      context,
      ref.read(administrationSettingsProvider.notifier).fetch(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(administrationSettingsProvider);
    final notifier = ref.watch(administrationSettingsProvider.notifier);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).administration,
      onBackTap: notifier.isDirty
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                notifier.restore();
                context.pop();
              }
            }
          : null,
      bottomBar: PageBottomBar(
        isPositiveEnabled: notifier.isDirty,
        onPositiveTap: () {
          doSomethingWithSpinner(
            context,
            notifier.save().then((value) {
              showSuccessSnackBar(context, loc(context).saved);
            }).onError((error, stackTrace) {
              showFailedSnackBar(
                  context, loc(context).unknownErrorCode(error ?? ''));
            }),
          );
        },
      ),
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.settings.managementSettings.isManageWirelesslySupported &&
                state.settings.canDisAllowLocalMangementWirelessly) ...[
              AppCard(
                child: AppSwitchTriggerTile(
                  semanticLabel: 'allow local management wirelessly',
                  title: AppText.labelLarge(loc(context)
                      .administrationAllowLocalManagementWirelessly),
                  value:
                      state.settings.managementSettings.canManageWirelessly ??
                          false,
                  onChanged: (value) {
                    notifier.setManagementSettings(value);
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
                    value: state.settings.isUPnPEnabled,
                    onChanged: (value) {
                      notifier.setUPnPEnabled(value);
                    },
                  ),
                  if (state.settings.isUPnPEnabled) ...[
                    const Divider(),
                    AppCheckbox(
                      value: state.settings.canUsersConfigure,
                      semanticLabel: 'upnp allow users configure',
                      text: loc(context).administrationUPnPAllowUsersConfigure,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        notifier.setCanUsersConfigure(value);
                      },
                    ),
                    const AppGap.small2(),
                    AppCheckbox(
                      value: state.settings.canUsersDisableWANAccess,
                      semanticLabel: 'upnp allow users disable internet access',
                      text: loc(context)
                          .administrationUPnPAllowUsersDisableInternetAccess,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        notifier.setCanUsersDisableWANAccess(value);
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
                value: state.settings.enabledALG,
                onChanged: (value) {
                  notifier.setALGEnabled(value);
                },
              ),
            ),
            const AppGap.small2(),
            if (state.status.isExpressForwardingSupported) ...[
              AppCard(
                child: AppSwitchTriggerTile(
                  semanticLabel: 'express forwarding',
                  title: AppText.labelLarge(
                      loc(context).administrationExpressForwarding),
                  value: state.settings.enabledExpressForwarfing,
                  onChanged: (value) {
                    notifier.setExpressForwarding(value);
                  },
                ),
              ),
              const AppGap.small2(),
            ]
          ],
        ),
      ),
    );
  }
}
