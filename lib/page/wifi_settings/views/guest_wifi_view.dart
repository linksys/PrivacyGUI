import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class GuestWiFiSettingsView extends ArgumentsConsumerStatefulView {
  const GuestWiFiSettingsView({super.key});

  @override
  ConsumerState<GuestWiFiSettingsView> createState() =>
      _GuestWiFiSettingsViewState();
}

class _GuestWiFiSettingsViewState extends ConsumerState<GuestWiFiSettingsView> {
  late TextEditingController _guestPasswordController;

  GuestWiFiState? _preservedState;

  @override
  void initState() {
    super.initState();
    _guestPasswordController = TextEditingController();
    doSomethingWithSpinner(
      context,
      ref.read(guestWifiProvider.notifier).fetch().then(
        (state) {
          ref.read(wifiViewProvider.notifier).setChanged(false);
          setState(
            () {
              _preservedState = state;
              _guestPasswordController.text = state.password;
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _guestPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestWifiProvider);
    ref.listen(guestWifiProvider, (previous, next) {
      ref.read(wifiViewProvider.notifier).setChanged(next != _preservedState);
    });
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      padding: EdgeInsets.zero,
      useMainPadding: false,
      bottomBar: PageBottomBar(
          isPositiveEnabled: state != _preservedState,
          onPositiveTap: () {
            doSomethingWithSpinner(
              context,
              ref.read(guestWifiProvider.notifier).save().then((state) {
                ref.read(wifiViewProvider.notifier).setChanged(false);
                setState(() {
                  _preservedState = state;
                  _guestPasswordController.text = state.password;
                });
                showSuccessSnackBar(context, loc(context).saved);
              }).onError(
                (error, stackTrace) => showFailedSnackBar(
                  context,
                  loc(context).unknownErrorCode(error ?? ''),
                ),
              ),
            );
          }),
      child: _guestWiFiContent(),
    );
  }

  Widget _guestWiFiContent() {
    final guest = ref.watch(guestWifiProvider);
    return AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppListCard(
              title: AppText.labelLarge(guest.ssid),
              description: AppText.bodyMedium(loc(context).guestWifiEnableDesc),
              trailing: AppSwitch(
                value: guest.isEnabled,
                onChanged: (value) {
                  ref.read(guestWifiProvider.notifier).setEnable(value);
                },
              ),
            ),
            if (guest.isEnabled) ...[
              const AppGap.large4(),
              AppText.labelLarge(loc(context).settings),
              const AppGap.small2(),
              AppSettingCard(
                title: loc(context).wifiName,
                description: guest.ssid,
                trailing: const Icon(LinksysIcons.edit),
                onTap: () {
                  _showGuestWiFiNameModal(guest.ssid);
                },
              ),
              const AppGap.small2(),
              AppListCard(
                title: AppText.bodyMedium(loc(context).routerPassword),
                description: IntrinsicWidth(
                    child: Theme(
                        data: Theme.of(context).copyWith(
                            inputDecorationTheme: const InputDecorationTheme(
                                isDense: true,
                                contentPadding: EdgeInsets.zero)),
                        child: AppPasswordField(
                          semanticLabel: 'router password',
                          readOnly: true,
                          border: InputBorder.none,
                          controller: _guestPasswordController,
                          suffixIconConstraints: const BoxConstraints(),
                        ))),
                trailing: const Icon(
                  LinksysIcons.edit,
                  semanticLabel: 'edit',
                ),
                onTap: () {
                  _showGuestWifiPasswordModal(guest.password);
                },
              ),
            ],
          ],
        ));
  }

  _showGuestWiFiNameModal(String initValue) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    bool isEmpty = initValue.isEmpty;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).guestWiFiName,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            semanticLabel: 'guest wifi name',
            controller: controller,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              setState(() {
                isEmpty = value.isEmpty;
              });
            },
          )
        ],
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => !isEmpty,
    );

    if (result != null) {
      ref.read(guestWifiProvider.notifier).setGuestSSID(result);
    }
  }

  _showGuestWifiPasswordModal(String initValue) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    bool isEmpty = initValue.isEmpty;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).guestWiFiPassword,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            semanticLabel: 'guest wifi password',
            controller: controller,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              setState(() {
                isEmpty = value.isEmpty;
              });
            },
          )
        ],
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => !isEmpty,
    );

    if (result != null) {
      ref.read(guestWifiProvider.notifier).setGuestPassword(result);
    }
  }
}
