import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/administration/providers/administration_settings_provider.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/shortcuts/spinners.dart';
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
    doSomethingWithSpinner(
            context, ref.read(administrationSettingsProvider.notifier).fetch())
        .then((value) {
      _preservedState = value;
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
            if (state.managementSettings.isManageWirelesslySupported) ...[
              AppCard(
                child: AppSwitchTriggerTile(
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
              const AppGap.medium(),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSwitchTriggerTile(
                    title: AppText.labelLarge(loc(context).upnp),
                    value: state.isUPnPEnabled,
                    onChanged: (value) {
                      ref
                          .read(administrationSettingsProvider.notifier)
                          .setUPnPEnabled(value);
                    },
                  ),
                  const Divider(),
                  AppCheckbox(
                    value: state.canUsersConfigure,
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
                  const AppGap.medium(),
                  AppCheckbox(
                    value: state.canUsersDisableWANAccess,
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
              ),
            ),
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
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
            const AppGap.medium(),
            AppCard(
              child: AppSwitchTriggerTile(
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
            const AppGap.medium(),
          ],
        ),
      ),
    );
  }
}
