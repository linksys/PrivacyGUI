import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/guest_wifi_item.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class WiFiListView extends ArgumentsConsumerStatefulView {
  const WiFiListView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<WiFiListView> createState() => _WiFiListViewState();
}

class _WiFiListViewState extends ConsumerState<WiFiListView> {
  WiFiState? _preservedMainWiFiState;

  final Map<String, TextEditingController> _advancedPasswordController = {};

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final index = widget.args['wifiIndex'] as int? ?? 0;
    _scrollController = ScrollController(initialScrollOffset: 760.0 * index);

    doSomethingWithSpinner(
      context,
      ref.read(wifiListProvider.notifier).fetch().then(
        (state) {
          ref.read(wifiViewProvider.notifier).setChanged(false);
          setState(
            () {
              final wifiState = state;
              _preservedMainWiFiState = wifiState;

              for (var wifi in wifiState.mainWiFi) {
                final controller = TextEditingController()
                  ..text = wifi.password;
                _advancedPasswordController.putIfAbsent(
                    wifi.radioID.value, () => controller);
              }
              _advancedPasswordController.putIfAbsent(
                  'guest',
                  () =>
                      TextEditingController()..text = state.guestWiFi.password);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (var element in _advancedPasswordController.values) {
      element.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wifiListProvider);

    ref.listen(wifiListProvider, (previous, next) {
      ref
          .read(wifiViewProvider.notifier)
          .setChanged(next != _preservedMainWiFiState);
    });

    final isPositiveEnabled = !const ListEquality()
            .equals(_preservedMainWiFiState?.mainWiFi, state.mainWiFi) ||
        _preservedMainWiFiState?.guestWiFi != state.guestWiFi;

    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      scrollable: true,
      controller: _scrollController,
      padding: EdgeInsets.zero,
      bottomBar: PageBottomBar(
          isPositiveEnabled: isPositiveEnabled,
          onPositiveTap: () {
            _showSaveConfirmModal();
          }),
      useMainPadding: false,
      child: _wifiContentView(),
    );
  }

  Widget _wifiContentView() {
    final state = ref.watch(wifiListProvider);

    final columnCount = ResponsiveLayout.isOverExtraLargeLayout(context)
        ? 4
        : ResponsiveLayout.isOverLargeLayout(context)
            ? 3
            : ResponsiveLayout.isOverMedimumLayout(context)
                ? 3
                : 2;
    final fixedWidth = ResponsiveLayout.isOverExtraLargeLayout(context)
        ? 3.col
        : ResponsiveLayout.isOverLargeLayout(context)
            ? 4.col
            : ResponsiveLayout.isOverMedimumLayout(context)
                ? 4.col
                : ResponsiveLayout.isOverSmallLayout(context)
                    ? 4.col
                    : 2.col;
    final columnWidths = Map.fromEntries(
        List.generate(columnCount, (index) => index).map((e) => e ==
                columnCount - 1
            ? MapEntry(e, FixedColumnWidth(fixedWidth))
            : MapEntry(
                e,
                FixedColumnWidth(
                    fixedWidth + ResponsiveLayout.columnPadding(context)))));

    final children = [
      columnCount > state.mainWiFi.length
          ? TableRow(children: [
              ...state.mainWiFi
                  .mapIndexed(
                      (index, e) => _mainWiFiCard(e, index == columnCount - 1))
                  .toList(),
              _guestWiFiCard(state.guestWiFi, true),
            ])
          : columnCount == state.mainWiFi.length
              ? TableRow(children: [
                  ...state.mainWiFi
                      .mapIndexed((index, e) =>
                          _mainWiFiCard(e, index == columnCount - 1))
                      .toList(),
                ])
              : TableRow(children: [
                  ...state.mainWiFi
                      .take(columnCount)
                      .mapIndexed((index, e) =>
                          _mainWiFiCard(e, index == columnCount - 1))
                      .toList(),
                ]),
      if (columnCount <= state.mainWiFi.length)
        columnCount == state.mainWiFi.length
            ? TableRow(children: [
                _guestWiFiCard(state.guestWiFi, false),
                const SizedBox.shrink(),
                const SizedBox.shrink()
              ])
            : TableRow(children: [
                ...state.mainWiFi
                    .getRange(columnCount, state.mainWiFi.length)
                    .mapIndexed((index, e) =>
                        _mainWiFiCard(e, index == columnCount - 1))
                    .toList(),
                _guestWiFiCard(state.guestWiFi, true),
              ])
    ];
    return AppBasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Table(
          border: const TableBorder(),
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: children,
        ));
  }

  Widget _guestWiFiCard(GuestWiFiItem state, [bool lastInRow = false]) {
    return Padding(
      padding: EdgeInsets.only(
        right: lastInRow ? 0 : ResponsiveLayout.columnPadding(context),
        bottom: Spacing.medium,
      ),
      child: Column(
        children: [
          AppCard(
              padding: const EdgeInsets.symmetric(
                  vertical: Spacing.small2, horizontal: Spacing.large2),
              child: Column(children: [
                _guestWiFiBandCard(state),
                if (state.isEnabled) ...[
                  const Divider(),
                  _guestWiFiNameCard(state),
                  const Divider(),
                  _guestWiFiPasswordCard(state),
                ],
              ])),
        ],
      ),
    );
  }

  Widget _mainWiFiCard(WiFiItem radio, [bool lastInRow = false]) {
    return Padding(
      padding: EdgeInsets.only(
        right: lastInRow ? 0 : ResponsiveLayout.columnPadding(context),
        bottom: Spacing.medium,
      ),
      child: Column(
        children: [
          AppCard(
              padding: const EdgeInsets.symmetric(
                  vertical: Spacing.small2, horizontal: Spacing.large2),
              child: Column(
                children: [
                  _advancedWiFiBandCard(radio),
                  if (radio.isEnabled) ...[
                    const Divider(),
                    _advancedWiFiNameCard(radio),
                    const Divider(),
                    if (!radio.securityType.isOpenVariant) ...[
                      _advancedWiFiPasswordCard(radio),
                      const Divider(),
                    ],
                    _advancedWiFiSecurityTypeCard(radio),
                    const Divider(),
                    _advanvedWiFiWirelessModeCard(radio),
                    const Divider(),
                    _advancedWiFiBoradcastCard(radio),
                    const Divider(),
                    _advancedWiFiChannelWidthCard(radio),
                    const Divider(),
                    _advancedWiFiChannelCard(radio),
                  ]
                ],
              )),
        ],
      ),
    );
  }

  ///
  /// Guest Cards
  Widget _guestWiFiBandCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.labelLarge(loc(context).guest),
        trailing: AppSwitch(
          semanticLabel: 'guest',
          value: state.isEnabled,
          onChanged: (value) {
            ref.read(wifiListProvider.notifier).setWiFiEnabled(value);
          },
        ),
      );
  Widget _guestWiFiNameCard(GuestWiFiItem state) => AppSettingCard.noBorder(
        title: loc(context).guestWiFiName,
        description: state.ssid,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          _showWiFiNameModal(state.ssid, (value) {
            ref.read(wifiListProvider.notifier).setWiFiSSID(value);
          });
        },
      );
  Widget _guestWiFiPasswordCard(GuestWiFiItem state) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.bodyMedium(loc(context).guestWiFiPassword),
        description: IntrinsicWidth(
            child: Theme(
                data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                        isDense: true, contentPadding: EdgeInsets.zero)),
                child: AppPasswordField(
                  semanticLabel: 'guest wifi password',
                  readOnly: true,
                  border: InputBorder.none,
                  controller: _advancedPasswordController['guest'],
                  suffixIconConstraints: const BoxConstraints(),
                ))),
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showWifiPasswordModal(state.password, (value) {
            ref.read(wifiListProvider.notifier).setWiFiPassword(value);
            _advancedPasswordController['guest']?.text = value;
          });
        },
      );

  ///
  /// Advanced Cards
  ///
  Widget _advancedWiFiBandCard(WiFiItem radio) => AppListCard(
        showBorder: false,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title:
            AppText.labelLarge(getWifiRadioBandTitle(context, radio.radioID)),
        trailing: AppSwitch(
          semanticLabel: getWifiRadioBandTitle(context, radio.radioID),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        title: AppText.bodyMedium(loc(context).wifiPassword),
        description: IntrinsicWidth(
            child: Theme(
                data: Theme.of(context).copyWith(
                    inputDecorationTheme: const InputDecorationTheme(
                        isDense: true, contentPadding: EdgeInsets.zero)),
                child: AppPasswordField(
                  semanticLabel: 'wifi password',
                  readOnly: true,
                  border: InputBorder.none,
                  controller: _advancedPasswordController[radio.radioID.value],
                  suffixIconConstraints: const BoxConstraints(),
                ))),
        trailing: const Icon(LinksysIcons.edit),
        onTap: () {
          _showWifiPasswordModal(radio.password, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiPassword(value, radio.radioID);
            _advancedPasswordController[radio.radioID.value]?.text = value;
          });
        },
      );

  Widget _advancedWiFiSecurityTypeCard(WiFiItem radio) =>
      AppSettingCard.noBorder(
        title: loc(context).securityMode,
        description: getWifiSecurityTypeTitle(context, radio.securityType),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () {
          _showWirelessWiFiModeModal(radio.wirelessMode, radio.defaultMixedMode,
              radio.availableWirelessModes, (value) {
            ref
                .read(wifiListProvider.notifier)
                .setWiFiMode(value, radio.radioID);
          });
        },
      );

  Widget _advancedWiFiBoradcastCard(WiFiItem radio) => AppListCard(
        showBorder: false,
        title: AppText.labelLarge(loc(context).broadcastSSID),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: AppCheckbox(
          value: radio.isBroadcast,
          onChanged: (value) {
            if (value == null) {
              return;
            }
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
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
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            semanticLabel: 'wifi name',
            controller: controller,
            border: const OutlineInputBorder(),
            onChanged: (value) {
              setState(() {
                isEmpty = value.isEmpty;
              });
            },
            onSubmitted: (_) {
              context.pop(controller.text);
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
      contentBuilder: (context, setState, onSubmit) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppPasswordField.withValidator(
            semanticLabel: 'wifi password',
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
            onSubmitted: (_) {
              context.pop(controller.text);
            },
          )
        ],
      ),
      event: () async => controller.text,
      checkPositiveEnabled: () => isPasswordValid,
    );

    if (result != null) {
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
              itemHeight: 56,
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
              itemHeight: 56,
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
                itemHeight: 56,
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
                itemHeight: 56,
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

  _showSaveConfirmModal() async {
    final newState = ref.read(wifiListProvider);
    final result = await showSubmitAppDialog(
      context,
      title: loc(context).wifiListSaveModalTitle,
      contentBuilder: (context, setState, onSubmit) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).wifiListSaveModalDesc),
            ..._mloWarning(newState),
            const AppGap.medium(),
            ..._buildNewSettings(newState),
            const AppGap.medium(),
            AppText.bodyMedium(loc(context).doYouWantToContinue),
          ],
        ),
      ),
      event: () async {
        await ref.read(wifiListProvider.notifier).save().then((state) {
          ref.read(wifiViewProvider.notifier).setChanged(false);
          setState(() {
            _preservedMainWiFiState = state;
          });
          showSuccessSnackBar(context, loc(context).saved);
        }).onError((error, stackTrace) =>
            showFailedSnackBar(context, loc(context).generalError));
      },
    );
  }

  List<Widget> _mloWarning(WiFiState state) {
    final radios =
        Map.fromIterables(state.mainWiFi.map((e) => e.radioID), state.mainWiFi);
    final isMLOEnabled = ref.read(wifiAdvancedProvider).isMLOEnabled ?? false;
    return ref
            .read(wifiListProvider.notifier)
            .checkingMLOSettingsConflicts(radios, isMloEnabled: isMLOEnabled)
        ? [
            const AppGap.small3(),
            AppText.labelLarge(
              loc(context).mloWarning,
              color: Theme.of(context).colorScheme.error,
            ),
          ]
        : [];
  }

  List<Widget> _buildNewSettings(WiFiState state) {
    List<Widget> advanced = state.mainWiFi
        .map(
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(e.radioID.value),
              SizedBox(
                width: double.infinity,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodyMedium('${loc(context).wifiName}: ${e.ssid}'),
                      AppText.bodyMedium(
                          '${loc(context).wifiPassword}: ${e.password}'),
                      AppText.bodyMedium(
                          '${loc(context).securityMode}: ${e.securityType.value}'),
                    ],
                  ),
                ),
              ),
              const AppGap.small3(),
            ],
          ),
        )
        .toList();
    advanced.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).guest),
          SizedBox(
            width: double.infinity,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                      '${loc(context).wifiName}: ${state.guestWiFi.ssid}'),
                  AppText.bodyMedium(
                      '${loc(context).wifiPassword}: ${state.guestWiFi.password}'),
                ],
              ),
            ),
          ),
          const AppGap.small3(),
        ],
      ),
    );
    return advanced;
  }
}
