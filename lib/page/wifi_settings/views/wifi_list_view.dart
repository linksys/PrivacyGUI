import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_app/page/wifi_settings/providers/wifi_state.dart';
import 'package:linksys_app/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:linksys_app/validator_rules/rules.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/list_card.dart';
import 'package:linksys_widgets/widgets/card/setting_card.dart';
import 'package:linksys_widgets/widgets/input_field/validator_widget.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:linksys_widgets/widgets/radios/radio_list.dart';

enum WiFiListViewMode {
  simple,
  advanced,
  ;
}

class WiFiListView extends ConsumerStatefulWidget {
  const WiFiListView({Key? key}) : super(key: key);

  @override
  ConsumerState<WiFiListView> createState() => _WiFiListViewState();
}

class _WiFiListViewState extends ConsumerState<WiFiListView> {
  WiFiState? _preservedState;

  bool _isLoading = false;
  WiFiListViewMode _mode = WiFiListViewMode.simple;

  final TextEditingController _simplePasswordController =
      TextEditingController();
  final Map<WifiRadioBand, TextEditingController> _advancedPasswordController =
      {};

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    ref.read(wifiListProvider.notifier).fetch().then((state) {
      ref.read(wifiViewProvider.notifier).setChanged(false);
      setState(() {
        _mode = ref.read(wifiListProvider.notifier).isAllBandsConsistent()
            ? WiFiListViewMode.simple
            : WiFiListViewMode.advanced;
        _preservedState = state;
        _isLoading = false;
        _simplePasswordController.text =
            state.mainWiFi.firstOrNull?.password ?? '';
        for (var wifi in state.mainWiFi) {
          final controller = TextEditingController()..text = wifi.password;
          _advancedPasswordController.putIfAbsent(
              wifi.radioID, () => controller);
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _simplePasswordController.dispose();
    for (var element in _advancedPasswordController.values) {
      element.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);

    ref.listen(wifiListProvider, (previous, next) {
      ref.read(wifiViewProvider.notifier).setChanged(next != _preservedState);
    });
    return _isLoading
        ? AppFullScreenSpinner(
            text: loc(context).processing,
          )
        : StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            scrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            bottomBar: PageBottomBar(
                isPositiveEnabled: _mode == WiFiListViewMode.simple
                    ? _preservedState?.simpleWiFi != state.simpleWiFi
                    : !const ListEquality()
                        .equals(_preservedState?.mainWiFi, state.mainWiFi),
                onPositiveTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  ref
                      .read(wifiListProvider.notifier)
                      .save(_mode)
                      .then((_) =>
                          showSuccessSnackBar(context, loc(context).saved))
                      .onError((error, stackTrace) => loc(context).generalError)
                      .whenComplete(() => setState(() {
                            _isLoading = false;
                          }));
                }),
            child: switch (_mode) {
              WiFiListViewMode.simple => _simpleWiFiView(),
              WiFiListViewMode.advanced => _advancedWiFiView(),
            },
          );
  }

  Widget _simpleWiFiView() {
    final state = ref.watch(wifiListProvider);
    final mainRadio = state.simpleWiFi;
    return AppBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelLarge(loc(context).wifi),
              AppTextButton(
                loc(context).showAdvanced,
                icon: LinksysIcons.settings,
                onTap: () {
                  setState(() {
                    _mode = WiFiListViewMode.advanced;
                  });
                },
              )
            ],
          ),
          const AppGap.regular(),
          AppSettingCard(
            title: loc(context).wifiName,
            description: mainRadio.ssid,
            trailing: const Icon(LinksysIcons.edit),
            onTap: () {
              _showWiFiNameModal(mainRadio.ssid, (value) {
                ref.read(wifiListProvider.notifier).setWiFiSSID(value, null);
              });
            },
          ),
          AppListCard(
            title: AppText.bodyLarge(loc(context).wifiPassword),
            description: IntrinsicWidth(
                child: Theme(
                    data: Theme.of(context).copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                            isDense: true, contentPadding: EdgeInsets.zero)),
                    child: AppPasswordField(
                      readOnly: true,
                      border: InputBorder.none,
                      controller: _simplePasswordController,
                      suffixIconConstraints: const BoxConstraints(),
                    ))),
            trailing: const Icon(LinksysIcons.edit),
            onTap: () {
              _showWifiPasswordModal(mainRadio.password, (value) {
                ref
                    .read(wifiListProvider.notifier)
                    .setWiFiPassword(value, null);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _advancedWiFiView() {
    final state = ref.watch(wifiListProvider);

    return AppBasicLayout(
      crossAxisAlignment: CrossAxisAlignment.start,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelLarge(loc(context).wifi),
              const AppGap.regular(),
              AppTextButton(
                loc(context).showBasic,
                icon: LinksysIcons.settings,
                onTap: () {
                  setState(() {
                    _mode = WiFiListViewMode.simple;
                  });
                },
              )
            ],
          ),
          const AppGap.regular(),
          ...state.mainWiFi.map((radio) => _advancedWiFiCard(radio)),
        ],
      ),
    );
  }

  Widget _advancedWiFiCard(WiFiItem radio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
            child: Column(
          children: [
            _advancedWiFiBandCard(radio),
            const Divider(),
            _advancedWiFiNameCard(radio),
            const Divider(),
            _advancedWiFiPasswordCard(radio),
            const Divider(),
            _advancedWiFiSecurityTypeCard(radio),
            const Divider(),
            _advanvedWiFiWirelessModeCard(radio),
            const Divider(),
            _advancedWiFiBoradcastCard(radio),
            const Divider(),
            _advancedWiFiChannelWidthCard(radio),
            const Divider(),
            _advancedWiFiChannelCard(radio),
          ],
        )),
        const AppGap.big(),
      ],
    );
  }

  ///
  /// Advanced Cards
  ///
  Widget _advancedWiFiBandCard(WiFiItem radio) => AppListCard(
        showBorder: false,
        padding: EdgeInsets.zero,
        title:
            AppText.labelLarge(getWifiRadioBandTitle(context, radio.radioID)),
        trailing: AppSwitch(
          value: radio.isEnabled,
          onChanged: (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiEnabled(value, radio.radioID);
          },
        ),
      );
  Widget _advancedWiFiNameCard(WiFiItem radio) => AppSettingCard.noBorder(
        title: loc(context).wifiName,
        description: radio.ssid,
        padding: EdgeInsets.zero,
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showWiFiNameModal(radio.ssid, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiSSID(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiPasswordCard(WiFiItem radio) => AppListCard(
        showBorder: false,
        padding: EdgeInsets.zero,
        title: AppText.bodyLarge(loc(context).wifiPassword),
        description: IntrinsicWidth(
            child: Theme(
                data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                        isDense: true, contentPadding: EdgeInsets.zero)),
                child: AppPasswordField(
                  readOnly: true,
                  border: InputBorder.none,
                  controller: _advancedPasswordController[radio.radioID],
                  suffixIconConstraints: const BoxConstraints(),
                ))),
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showWifiPasswordModal(radio.password, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiPassword(value, radio.radioID);
            _advancedPasswordController[radio.radioID]?.text = value;
          });
        },
      );

  Widget _advancedWiFiSecurityTypeCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        title: loc(context).securityMode,
        description: getWifiSecurityTypeTitle(context, radio.securityType),
        padding: EdgeInsets.zero,
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showSecurityModeModal(
              radio.securityType, radio.availableSecurityTypes, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiSecurityType(value, radio.radioID);
          });
        },
      );

  Widget _advanvedWiFiWirelessModeCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        title: loc(context).wifiMode,
        description: getWifiWirelessModeTitle(
          context,
          radio.wirelessMode,
          radio.defaultMixedMode,
        ),
        padding: EdgeInsets.zero,
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showWirelessWiFiModeModal(radio.wirelessMode, radio.defaultMixedMode,
              radio.availableWirelessModes, (value) {});
        },
      );

  Widget _advancedWiFiBoradcastCard(WiFiItem radio) => AppListCard(
        showBorder: false,
        title: AppText.labelLarge(loc(context).broadcastSSID),
        padding: EdgeInsets.zero,
        trailing: AppSwitch(
          value: radio.isBroadcast,
          onChanged: (value) {
            ref
                .read(wifiListProvider.notifier)
                .setEnableBoardcast(value, radio.radioID);
          },
        ),
      );
  Widget _advancedWiFiChannelWidthCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        title: loc(context).channelWidth,
        description: getWifiChannelWidthTitle(
          context,
          radio.channelWidth,
        ),
        padding: EdgeInsets.zero,
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showChannelWidthModal(
            radio.channelWidth,
            radio.availableChannels.keys.toList(),
            (value) {
              ref
                  .read(wifiListProvider.notifier)
                  .setChannelWidth(value, radio.radioID);
            },
          );
        },
      );
  Widget _advancedWiFiChannelCard(WiFiItem radio) => AppSettingCard.noBorder(
        title: loc(context).channel,
        description: getWifiChannelTitle(
          context,
          radio.channel,
          radio.radioID,
        ),
        padding: EdgeInsets.zero,
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showChannelModal(
              radio.channel,
              radio.availableChannels[radio.channelWidth] ?? [],
              radio.radioID, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setChannel(value, radio.radioID);
          });
        },
      );

  ///
  /// Dialog modal
  ///
  _showWiFiNameModal(String initValue, void Function(String) onEdited) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    bool isEmpty = initValue.isEmpty;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiName,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
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
      // ref.read(wifiListProvider.notifier).setGuestSSID(result);
      onEdited.call(result);
    }
  }

  _showWifiPasswordModal(
      String initValue, void Function(String) onEdited) async {
    TextEditingController controller = TextEditingController()
      ..text = initValue;
    bool isPasswordValid = true;
    final result = await showSubmitAppDialog<String>(
      context,
      title: loc(context).wifiPassword,
      contentBuilder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPasswordField.withValidator(
            autofocus: true,
            controller: controller,
            border: const OutlineInputBorder(),
            validations: [
              Validation(
                description: '8 - 64 characters',
                validator: ((text) =>
                    LengthRule(min: 8, max: 64).validate(text)),
              ),
            ],
            onValidationChanged: (isValid) => setState(() {
              isPasswordValid = isValid;
            }),
          )
        ],
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => isPasswordValid,
    );

    if (result != null) {
      // ref.read(guestWifiProvider.notifier).setGuestPassword(result);
      onEdited(result);
    }
  }

  _showSecurityModeModal(
    WifiSecurityType type,
    List<WifiSecurityType> list,
    void Function(WifiSecurityType) onSelected,
  ) async {
    WifiSecurityType selected = type;
    final result = await showSimpleAppDialog<WifiSecurityType?>(context,
        title: loc(context).securityMode,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRadioList<WifiSecurityType>(
              initial: type,
              mainAxisSize: MainAxisSize.min,
              items: list
                  .map((e) => AppRadioListItem(
                        title: getWifiSecurityTypeTitle(context, e),
                        value: e,
                      ))
                  .toList(),
              onChanged: (index, selectedType) {
                if (selectedType != null) {
                  selected = selectedType;
                }
              },
            ),
          ],
        ),
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
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      // _notifier.setAccess(result.name);
      onSelected.call(result);
    }
  }

  _showWirelessWiFiModeModal(
    WifiWirelessMode mode,
    WifiWirelessMode? defaultMixedMode,
    List<WifiWirelessMode> list,
    void Function(WifiWirelessMode) onSelected,
  ) async {
    WifiWirelessMode selected = mode;
    final result = await showSimpleAppDialog<WifiWirelessMode?>(context,
        title: loc(context).wifiMode,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppRadioList<WifiWirelessMode>(
              initial: mode,
              mainAxisSize: MainAxisSize.min,
              items: list
                  .map((e) => AppRadioListItem(
                        title: getWifiWirelessModeTitle(
                            context, e, defaultMixedMode),
                        value: e,
                      ))
                  .toList(),
              onChanged: (index, selectedType) {
                if (selectedType != null) {
                  selected = selectedType;
                }
              },
            ),
          ],
        ),
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
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      // _notifier.setAccess(result.name);
      onSelected.call(result);
    }
  }

  _showChannelModal(
    int channel,
    List<int> list,
    WifiRadioBand band,
    void Function(int) onSelected,
  ) async {
    int selected = channel;
    final result = await showSimpleAppDialog<int?>(context,
        title: loc(context).channel,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRadioList<int>(
                initial: channel,
                mainAxisSize: MainAxisSize.min,
                items: list
                    .map((e) => AppRadioListItem(
                          title: getWifiChannelTitle(context, e, band),
                          value: e,
                        ))
                    .toList(),
                onChanged: (index, selectedType) {
                  if (selectedType != null) {
                    selected = selectedType;
                  }
                },
              ),
            ],
          ),
        ),
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
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      // _notifier.setAccess(result.name);
      onSelected.call(result);
    }
  }

  _showChannelWidthModal(
    WifiChannelWidth channelWidth,
    List<WifiChannelWidth> list,
    void Function(WifiChannelWidth) onSelected,
  ) async {
    WifiChannelWidth selected = channelWidth;
    final result = await showSimpleAppDialog<WifiChannelWidth?>(context,
        title: loc(context).channelWidth,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppRadioList<WifiChannelWidth>(
                initial: channelWidth,
                mainAxisSize: MainAxisSize.min,
                items: list
                    .map((e) => AppRadioListItem(
                          title: getWifiChannelWidthTitle(
                            context,
                            e,
                          ),
                          value: e,
                        ))
                    .toList(),
                onChanged: (index, selectedType) {
                  if (selectedType != null) {
                    selected = selectedType;
                  }
                },
              ),
            ],
          ),
        ),
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
              context.pop(selected);
            },
          ),
        ]);

    if (result != null) {
      // _notifier.setAccess(result.name);
      onSelected.call(result);
    }
  }
}
