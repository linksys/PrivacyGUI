import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class DMZSettingsView extends ArgumentsConsumerStatefulView {
  const DMZSettingsView({super.key, super.args});

  @override
  ConsumerState<DMZSettingsView> createState() => _DMZSettingsViewState();
}

class _DMZSettingsViewState extends ConsumerState<DMZSettingsView> {
  DMZSettingsState? _preservedState;
  late TextEditingController _sourceFirstIPController;
  late TextEditingController _sourceLastIPController;
  late TextEditingController _destinationIPController;
  late TextEditingController _destinationMACController;
  String? _sourceError;
  String? _destinationError;

  @override
  void initState() {
    super.initState();

    _sourceFirstIPController = TextEditingController();
    _sourceLastIPController = TextEditingController();
    _destinationIPController = TextEditingController();
    _destinationMACController = TextEditingController();

    doSomethingWithSpinner(
        context,
        ref.read(dmzSettingsProvider.notifier).fetch(true).then((value) {
          _preservedState = value;
          _sourceFirstIPController.text =
              value.settings.sourceRestriction?.firstIPAddress ?? '';
          _sourceLastIPController.text =
              value.settings.sourceRestriction?.lastIPAddress ?? '';
          _destinationIPController.text = value.settings.destinationIPAddress ??
              ref
                  .read(dmzSettingsProvider.notifier)
                  .ipAddress
                  .replaceAll('.0', '');
          _destinationMACController.text =
              value.settings.destinationMACAddress ?? '';
          return value;
        })).then((state) {
      if (state?.destinationType == DMZDestinationType.ip) {
        _checkDestinationIPAdress();
      } else {
        _checkDestinationMACAddress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmzSettingsProvider);
    return StyledAppPageView(
        title: loc(context).dmz,
        onBackTap: _preservedState != ref.read(dmzSettingsProvider)
            ? () {
                showUnsavedAlert(context).then((value) {
                  if (value == true) {
                    ref.read(dmzSettingsProvider.notifier).fetch();
                    context.pop();
                  }
                });
              }
            : null,
        scrollable: true,
        bottomBar: PageBottomBar(
            isPositiveEnabled: _preservedState != state &&
                (_sourceError == null && _destinationError == null),
            onPositiveTap: () {
              doSomethingWithSpinner(
                  context,
                  ref.read(dmzSettingsProvider.notifier).save().then((value) {
                    setState(() {
                      _preservedState = value;
                    });
                    _sourceFirstIPController.text =
                        value.settings.sourceRestriction?.firstIPAddress ?? '';
                    _sourceLastIPController.text =
                        value.settings.sourceRestriction?.lastIPAddress ?? '';
                    _destinationIPController.text =
                        value.settings.destinationIPAddress ??
                            ref
                                .read(dmzSettingsProvider.notifier)
                                .ipAddress
                                .replaceAll('.0', '');
                    _destinationMACController.text =
                        value.settings.destinationMACAddress ?? '';
                    showSuccessSnackBar(context, loc(context).saved);
                  }).onError((error, stackTrace) {
                    final errorMsg = errorCodeHelper(
                        context, (error as JNAPError?)?.result ?? '');
                    if (errorMsg != null) {
                      showFailedSnackBar(context, errorMsg);
                    } else {
                      showFailedSnackBar(context, loc(context).unknownError);
                    }
                  }));
            }),
        child: (context, constraints) => Column(
              children: [
                AppInfoCard(
                  title: loc(context).dmz,
                  description: loc(context).dmzDescription,
                  trailing: Padding(
                    padding: const EdgeInsets.only(left: Spacing.medium),
                    child: AppSwitch(
                      semanticLabel: 'dmz',
                      value: state.settings.isDMZEnabled,
                      onChanged: (value) {
                        ref.read(dmzSettingsProvider.notifier).setSettings(
                            state.settings.copyWith(isDMZEnabled: value));
                      },
                    ),
                  ),
                ),
                if (state.settings.isDMZEnabled) ...[
                  const AppGap.medium(),
                  AppCard(
                    child: Column(
                      children: [
                        _sourceIPWidget(state),
                      ],
                    ),
                  ),
                  const AppGap.medium(),
                  AppCard(
                    child: Column(
                      children: [_destinationIPWidget(state)],
                    ),
                  ),
                ]
              ],
            ));
  }

  Widget _sourceIPWidget(DMZSettingsState state) {
    return AppListCard(
        showBorder: false,
        padding: EdgeInsets.zero,
        title: AppText.labelLarge(loc(context).dmzSourceIPAddress),
        description: AppRadioList(
          selected: state.sourceType,
          itemHeight: 56,
          items: [
            AppRadioListItem(
                title: loc(context).automatic, value: DMZSourceType.auto),
            AppRadioListItem(
                title: loc(context).specifiedRange,
                expandedWidget: state.sourceType == DMZSourceType.range
                    ? Container(
                        constraints: const BoxConstraints(maxWidth: 429),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppIPFormField(
                              semanticLabel: 'specified range ip address start',
                              border: const OutlineInputBorder(),
                              controller: _sourceFirstIPController,
                              onChanged: (value) {
                                final sourceSettings =
                                    state.settings.sourceRestriction ??
                                        const DMZSourceRestriction(
                                            firstIPAddress: '',
                                            lastIPAddress: '');
                                ref
                                    .read(dmzSettingsProvider.notifier)
                                    .setSettings(state.settings.copyWith(
                                        sourceRestriction: () => sourceSettings
                                            .copyWith(firstIPAddress: value)));
                              },
                              onFocusChanged: (value) {
                                if (!value) {
                                  final firstValue = NetworkUtils.ipToNum(
                                      _sourceFirstIPController.text);
                                  final lastValue = NetworkUtils.ipToNum(
                                      _sourceLastIPController.text);
                                  setState(() {
                                    _sourceError = lastValue - firstValue > 0
                                        ? null
                                        : loc(context).dmzSourceRangeError;
                                  });
                                }
                              },
                              errorText: _sourceError != null ? '' : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(Spacing.small2),
                              child: Center(
                                  child: AppText.bodyMedium(loc(context).to)),
                            ),
                            AppIPFormField(
                              semanticLabel: 'specified range ip address end',
                              border: const OutlineInputBorder(),
                              controller: _sourceLastIPController,
                              onChanged: (value) {
                                final sourceSettings =
                                    state.settings.sourceRestriction ??
                                        const DMZSourceRestriction(
                                            firstIPAddress: '',
                                            lastIPAddress: '');
                                ref
                                    .read(dmzSettingsProvider.notifier)
                                    .setSettings(state.settings.copyWith(
                                        sourceRestriction: () => sourceSettings
                                            .copyWith(lastIPAddress: value)));
                              },
                              onFocusChanged: (value) {
                                if (!value) {
                                  _checkSourceIPRange();
                                }
                              },
                              errorText: _sourceError,
                            ),
                          ],
                        ),
                      )
                    : null,
                value: DMZSourceType.range),
          ],
          onChanged: (index, value) {
            if (value == state.sourceType) {
              return;
            }
            if (value != null) {
              ref.read(dmzSettingsProvider.notifier).setSourceType(value);
            }
            if (value == DMZSourceType.auto) {
              setState(() {
                _sourceFirstIPController.text = '';
                _sourceLastIPController.text = '';
                _sourceError = null;
              });
              ref.read(dmzSettingsProvider.notifier).setSettings(DMZSettings(
                    isDMZEnabled: state.settings.isDMZEnabled,
                    destinationIPAddress: state.settings.destinationIPAddress,
                    destinationMACAddress: state.settings.destinationMACAddress,
                  ));
            } else {
              _sourceFirstIPController.text =
                  _preservedState?.settings.sourceRestriction?.firstIPAddress ??
                      '';
              _sourceLastIPController.text =
                  _preservedState?.settings.sourceRestriction?.lastIPAddress ??
                      '';
              ref.read(dmzSettingsProvider.notifier).setSettings(DMZSettings(
                    isDMZEnabled: state.settings.isDMZEnabled,
                    sourceRestriction: DMZSourceRestriction(
                        firstIPAddress: _sourceFirstIPController.text,
                        lastIPAddress: _sourceLastIPController.text),
                    destinationIPAddress: state.settings.destinationIPAddress,
                    destinationMACAddress: state.settings.destinationMACAddress,
                  ));
              _checkSourceIPRange();
            }
          },
        ));
  }

  Widget _destinationIPWidget(DMZSettingsState state) {
    final subnetMask =
        ref.read(dmzSettingsProvider.notifier).subnetMask.split('.');
    return AppListCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      title: AppText.labelLarge(loc(context).dmzDestinationIPAddress),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRadioList(
            initial: state.destinationType,
            itemHeight: 56,
            items: [
              AppRadioListItem(
                  title: loc(context).ipAddress,
                  expandedWidget: state.destinationType == DMZDestinationType.ip
                      ? Container(
                          constraints: const BoxConstraints(maxWidth: 429),
                          child: AppIPFormField(
                            semanticLabel: 'destination ip address',
                            border: const OutlineInputBorder(),
                            controller: _destinationIPController,
                            octet1ReadOnly: subnetMask[0] == '255',
                            octet2ReadOnly: subnetMask[1] == '255',
                            octet3ReadOnly: subnetMask[2] == '255',
                            octet4ReadOnly: subnetMask[3] == '255',
                            onChanged: (value) {
                              ref
                                  .read(dmzSettingsProvider.notifier)
                                  .setSettings(state.settings.copyWith(
                                      destinationIPAddress: () => value));
                            },
                            onFocusChanged: (value) {
                              if (!value) {
                                _checkDestinationIPAdress();
                              }
                            },
                            errorText: _destinationError,
                          ),
                        )
                      : null,
                  value: DMZDestinationType.ip),
              AppRadioListItem(
                  title: loc(context).macAddress,
                  expandedWidget:
                      state.destinationType == DMZDestinationType.mac
                          ? Container(
                              constraints: const BoxConstraints(maxWidth: 429),
                              child: AppTextField.macAddress(
                                border: const OutlineInputBorder(),
                                controller: _destinationMACController,
                                onChanged: (value) {
                                  ref
                                      .read(dmzSettingsProvider.notifier)
                                      .setSettings(state.settings.copyWith(
                                          destinationMACAddress: () => value));
                                },
                                onFocusChanged: (value) {
                                  if (!value) {
                                    _checkDestinationMACAddress();
                                  }
                                },
                                errorText: _destinationError,
                              ),
                            )
                          : null,
                  value: DMZDestinationType.mac),
            ],
            onChanged: (index, value) {
              if (value == state.destinationType) {
                return;
              }
              if (value != null) {
                ref
                    .read(dmzSettingsProvider.notifier)
                    .setDestinationType(value);
              }
              if (value == DMZDestinationType.ip) {
                _destinationError = null;
                _destinationMACController.text = '';
                _destinationIPController.text =
                    state.settings.destinationIPAddress ??
                        ref
                            .read(dmzSettingsProvider.notifier)
                            .ipAddress
                            .replaceAll('.0', '');
                ref.read(dmzSettingsProvider.notifier).setSettings(
                    state.settings.copyWith(
                        destinationIPAddress: () =>
                            _destinationIPController.text,
                        destinationMACAddress: () => null));
                _checkDestinationIPAdress();
              } else {
                _destinationError = null;
                _destinationIPController.text = '';
                _destinationMACController.text =
                    state.settings.destinationMACAddress ?? '';
                ref.read(dmzSettingsProvider.notifier).setSettings(
                    state.settings.copyWith(
                        destinationMACAddress: () =>
                            _destinationMACController.text,
                        destinationIPAddress: () => null));
                _checkDestinationMACAddress();
              }
            },
          ),
          const AppGap.medium(),
          AppTextButton(
            loc(context).dmzViewDHCP,
            onTap: () async {
              final result = await context.pushNamed<List<DeviceListItem>?>(
                  RouteNamed.devicePicker,
                  extra: {
                    'type': 'ipv4AndMac',
                    'selectMode': 'single',
                    'onlineOnly': true,
                  });
              if (result != null) {
                if (state.destinationType == DMZDestinationType.ip) {
                  _destinationIPController.text = result.first.ipv4Address;
                  ref.read(dmzSettingsProvider.notifier).setSettings(
                      state.settings.copyWith(
                          destinationIPAddress: () => result.first.ipv4Address,
                          destinationMACAddress: () => null));
                  _checkDestinationIPAdress();
                } else {
                  _destinationMACController.text = result.first.macAddress;
                  ref.read(dmzSettingsProvider.notifier).setSettings(
                      state.settings.copyWith(
                          destinationMACAddress: () => result.first.macAddress,
                          destinationIPAddress: () => null));
                  _checkDestinationMACAddress();
                }
              }
            },
          )
        ],
      ),
    );
  }

  _checkSourceIPRange() {
    final firstValue = NetworkUtils.ipToNum(_sourceFirstIPController.text);
    final lastValue = NetworkUtils.ipToNum(_sourceLastIPController.text);
    setState(() {
      _sourceError =
          lastValue - firstValue >= 0 ? null : loc(context).dmzSourceRangeError;
    });
  }

  _checkDestinationIPAdress() {
    final isValid =
        NetworkUtils.isValidIpAddress(_destinationIPController.text);
    setState(() {
      _destinationError = isValid ? null : loc(context).invalidIpAddress;
    });
  }

  _checkDestinationMACAddress() {
    final isValid = MACAddressRule().validate(_destinationMACController.text);
    setState(() {
      _destinationError = isValid ? null : loc(context).invalidMACAddress;
    });
  }
}
