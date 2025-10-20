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
      ref.read(dmzSettingsProvider.notifier).fetch(true),
    ).then((state) {
      if (state != null) {
        _updateController(state);
        if (state.settings.destinationType == DMZDestinationType.ip) {
          _checkDestinationIPAdress();
        } else {
          _checkDestinationMACAddress();
        }
      }
    });
  }

  void _updateController(DMZSettingsState state) {
    _sourceFirstIPController.text =
        state.settings.settings.sourceRestriction?.firstIPAddress ?? '';
    _sourceLastIPController.text =
        state.settings.settings.sourceRestriction?.lastIPAddress ?? '';
    _destinationIPController.text =
        state.settings.settings.destinationIPAddress ??
            ref.read(dmzSettingsProvider.notifier).ipAddress.replaceAll('.0', '');
    _destinationMACController.text =
        state.settings.settings.destinationMACAddress ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmzSettingsProvider);
    final notifier = ref.watch(dmzSettingsProvider.notifier);
    return StyledAppPageView(
      title: loc(context).dmz,
      onBackTap: notifier.isDirty
          ? () {
              showUnsavedAlert(context).then((value) {
                if (value == true) {
                  notifier.restore();
                  context.pop();
                }
              });
            }
          : null,
      bottomBar: PageBottomBar(
        isPositiveEnabled:
            notifier.isDirty && (_sourceError == null && _destinationError == null),
        onPositiveTap: () {
          doSomethingWithSpinner(
            context,
            notifier.save().then((_) {
              showSuccessSnackBar(context, loc(context).saved);
            }).catchError((error) {
              final errorMsg = errorCodeHelper(
                  context, (error as JNAPError?)?.result ?? '');
              if (errorMsg != null) {
                showFailedSnackBar(context, errorMsg);
              } else {
                showFailedSnackBar(context, loc(context).unknownError);
              }
            }),
          );
        },
      ),
      child: (context, constraints) => SingleChildScrollView(
        child: Column(
          children: [
            AppInfoCard(
              title: loc(context).dmz,
              description: loc(context).dmzDescription,
              trailing: Padding(
                padding: const EdgeInsets.only(left: Spacing.medium),
                child: AppSwitch(
                  semanticLabel: 'dmz',
                  value: state.settings.settings.isDMZEnabled,
                  onChanged: (value) {
                    notifier.setSettings(
                        state.settings.settings.copyWith(isDMZEnabled: value));
                  },
                ),
              ),
            ),
            if (state.settings.settings.isDMZEnabled) ...[
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
        ),
      ),
    );
  }

  Widget _sourceIPWidget(DMZSettingsState state) {
    final notifier = ref.watch(dmzSettingsProvider.notifier);
    return AppListCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      title: AppText.labelLarge(loc(context).dmzSourceIPAddress),
      description: AppRadioList(
        selected: state.settings.sourceType,
        itemHeight: 56,
        items: [
          AppRadioListItem(
              title: loc(context).automatic, value: DMZSourceType.auto),
          AppRadioListItem(
            title: loc(context).specifiedRange,
            expandedWidget: state.settings.sourceType == DMZSourceType.range
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
                                state.settings.settings.sourceRestriction ??
                                    const DMZSourceRestriction(
                                        firstIPAddress: '', lastIPAddress: '');
                            notifier.setSettings(state.settings.settings.copyWith(
                                sourceRestriction: () => sourceSettings
                                    .copyWith(firstIPAddress: value)));
                          },
                          onFocusChanged: (value) {
                            if (!value) {
                              _checkSourceIPRange();
                            }
                          },
                          errorText: _sourceError != null ? '' : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(Spacing.small2),
                          child:
                              Center(child: AppText.bodyMedium(loc(context).to)),
                        ),
                        AppIPFormField(
                          semanticLabel: 'specified range ip address end',
                          border: const OutlineInputBorder(),
                          controller: _sourceLastIPController,
                          onChanged: (value) {
                            final sourceSettings =
                                state.settings.settings.sourceRestriction ??
                                    const DMZSourceRestriction(
                                        firstIPAddress: '', lastIPAddress: '');
                            notifier.setSettings(state.settings.settings.copyWith(
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
            value: DMZSourceType.range,
          ),
        ],
        onChanged: (index, value) {
          if (value == state.settings.sourceType) {
            return;
          }
          if (value != null) {
            notifier.setSourceType(value);
          }
          if (value == DMZSourceType.auto) {
            setState(() {
              _sourceFirstIPController.text = '';
              _sourceLastIPController.text = '';
              _sourceError = null;
            });
            notifier.setSettings(
              DMZSettings(
                isDMZEnabled: state.settings.settings.isDMZEnabled,
                destinationIPAddress:
                    state.settings.settings.destinationIPAddress,
                destinationMACAddress:
                    state.settings.settings.destinationMACAddress,
              ),
            );
          } else {
            _sourceFirstIPController.text = '';
            _sourceLastIPController.text = '';
            notifier.setSettings(
              DMZSettings(
                isDMZEnabled: state.settings.settings.isDMZEnabled,
                sourceRestriction: DMZSourceRestriction(
                  firstIPAddress: _sourceFirstIPController.text,
                  lastIPAddress: _sourceLastIPController.text,
                ),
                destinationIPAddress:
                    state.settings.settings.destinationIPAddress,
                destinationMACAddress:
                    state.settings.settings.destinationMACAddress,
              ),
            );
            _checkSourceIPRange();
          }
        },
      ),
    );
  }

  Widget _destinationIPWidget(DMZSettingsState state) {
    final notifier = ref.watch(dmzSettingsProvider.notifier);
    final subnetMask = notifier.subnetMask.split('.');
    return AppListCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      title: AppText.labelLarge(loc(context).dmzDestinationIPAddress),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRadioList(
            initial: state.settings.destinationType,
            itemHeight: 56,
            items: [
              AppRadioListItem(
                title: loc(context).ipAddress,
                expandedWidget:
                    state.settings.destinationType == DMZDestinationType.ip
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
                                notifier.setSettings(state.settings.settings
                                    .copyWith(destinationIPAddress: () => value));
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
                value: DMZDestinationType.ip,
              ),
              AppRadioListItem(
                title: loc(context).macAddress,
                expandedWidget:
                    state.settings.destinationType == DMZDestinationType.mac
                        ? Container(
                            constraints: const BoxConstraints(maxWidth: 429),
                            child: AppTextField.macAddress(
                              border: const OutlineInputBorder(),
                              controller: _destinationMACController,
                              onChanged: (value) {
                                notifier.setSettings(state.settings.settings
                                    .copyWith(
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
                value: DMZDestinationType.mac,
              ),
            ],
            onChanged: (index, value) {
              if (value == state.settings.destinationType) {
                return;
              }
              if (value != null) {
                notifier.setDestinationType(value);
              }
              if (value == DMZDestinationType.ip) {
                _destinationError = null;
                _destinationMACController.text = '';
                _destinationIPController.text =
                    state.settings.settings.destinationIPAddress ??
                        notifier.ipAddress.replaceAll('.0', '');
                notifier.setSettings(
                  state.settings.settings.copyWith(
                    destinationIPAddress: () => _destinationIPController.text,
                    destinationMACAddress: () => null,
                  ),
                );
                _checkDestinationIPAdress();
              } else {
                _destinationError = null;
                _destinationIPController.text = '';
                _destinationMACController.text =
                    state.settings.settings.destinationMACAddress ?? '';
                notifier.setSettings(
                  state.settings.settings.copyWith(
                    destinationMACAddress: () => _destinationMACController.text,
                    destinationIPAddress: () => null,
                  ),
                );
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
                },
              );
              if (result != null) {
                if (state.settings.destinationType == DMZDestinationType.ip) {
                  _destinationIPController.text = result.first.ipv4Address;
                  notifier.setSettings(
                    state.settings.settings.copyWith(
                      destinationIPAddress: () => result.first.ipv4Address,
                      destinationMACAddress: () => null,
                    ),
                  );
                  _checkDestinationIPAdress();
                } else {
                  _destinationMACController.text = result.first.macAddress;
                  notifier.setSettings(
                    state.settings.settings.copyWith(
                      destinationMACAddress: () => result.first.macAddress,
                      destinationIPAddress: () => null,
                    ),
                  );
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
