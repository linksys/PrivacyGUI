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
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/composed/app_list_card.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/error_code_helper.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';
import 'package:ui_kit_library/ui_kit.dart';

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
      ref.read(dmzSettingsProvider.notifier).fetch(forceRemote: true),
    ).then((state) {
      if (!mounted || state == null) return;
      _updateControllers(state);
      if (state.settings.current.destinationType == DMZDestinationType.ip) {
        _checkDestinationIPAdress();
      } else {
        _checkDestinationMACAddress();
      }
    });
  }

  void _updateControllers(DMZSettingsState state) {
    _sourceFirstIPController.text =
        state.settings.current.sourceRestriction?.firstIPAddress ?? '';
    _sourceLastIPController.text =
        state.settings.current.sourceRestriction?.lastIPAddress ?? '';
    _destinationIPController.text =
        state.settings.current.destinationIPAddress ??
            ref.read(dmzSettingsProvider).status.ipAddress.replaceAll('.0', '');
    _destinationMACController.text =
        state.settings.current.destinationMACAddress ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmzSettingsProvider);
    // ref.listen(dmzSettingsProvider, (previous, next) {
    //   _updateControllers(next);
    // });
    final isDirty = ref.read(dmzSettingsProvider.notifier).isDirty();
    return UiKitPageView.withSliver(
        title: loc(context).dmz,
        bottomBar: UiKitBottomBarConfig(
            isPositiveEnabled:
                isDirty && (_sourceError == null && _destinationError == null),
            onPositiveTap: () {
              doSomethingWithSpinner(
                  context,
                  ref.read(dmzSettingsProvider.notifier).save().then((value) {
                    if (!mounted) return;
                    _updateControllers(value);
                    showSuccessSnackBar(context, loc(context).saved);
                  }).onError((error, stackTrace) {
                    if (!context.mounted) return;
                    final errorMsg = errorCodeHelper(
                        context, (error as JNAPError?)?.result ?? '');
                    if (errorMsg != null) {
                      showFailedSnackBar(context, errorMsg);
                    } else {
                      showFailedSnackBar(context, loc(context).unknownError);
                    }
                  }));
            }),
        child: (context, constraints) => SingleChildScrollView(
              child: Column(
                children: [
                  AppListCard(
                    title: AppText.labelLarge(loc(context).dmz),
                    description:
                        AppText.bodyMedium(loc(context).dmzDescription),
                    trailing: Padding(
                      padding: EdgeInsets.only(left: AppSpacing.lg),
                      child: AppSwitch(
                        key: const Key('dmzSwitch'),
                        value: state.settings.current.isDMZEnabled,
                        onChanged: (value) {
                          ref.read(dmzSettingsProvider.notifier).setSettings(
                              state.settings.current
                                  .copyWith(isDMZEnabled: value));
                        },
                      ),
                    ),
                  ),
                  if (state.settings.current.isDMZEnabled) ...[
                    AppGap.lg(),
                    AppCard(
                      child: Column(
                        children: [
                          _sourceIPWidget(state),
                        ],
                      ),
                    ),
                    AppGap.lg(),
                    AppCard(
                      child: Column(
                        children: [_destinationIPWidget(state)],
                      ),
                    ),
                  ]
                ],
              ),
            ));
  }

  Widget _sourceIPWidget(DMZSettingsState state) {
    return AppListCard(
        showBorder: false,
        padding: EdgeInsets.zero,
        title: AppText.labelLarge(loc(context).dmzSourceIPAddress),
        description: AppRadioList(
          key: const Key('sourceType'),
          selected: state.settings.current.sourceType,
          itemHeight: 56,
          items: [
            AppRadioListItem(
                title: loc(context).automatic, value: DMZSourceType.auto),
            AppRadioListItem(
                title: loc(context).specifiedRange,
                expandedWidget: state.settings.current.sourceType ==
                        DMZSourceType.range
                    ? Container(
                        constraints: const BoxConstraints(maxWidth: 429),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Focus(
                              onFocusChange: (value) {
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
                              child: AppIpv4TextField(
                                key: const Key('sourceFirstIP'),
                                controller: _sourceFirstIPController,
                                onChanged: (value) {
                                  final sourceSettings = state
                                          .settings.current.sourceRestriction ??
                                      const DMZSourceRestriction(
                                          firstIPAddress: '',
                                          lastIPAddress: '');
                                  ref
                                      .read(dmzSettingsProvider.notifier)
                                      .setSettings(state.settings.current
                                          .copyWith(
                                              sourceRestriction: () =>
                                                  sourceSettings.copyWith(
                                                      firstIPAddress: value)));
                                },
                                errorText: _sourceError != null ? '' : null,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              child: Center(
                                  child: AppText.bodyMedium(loc(context).to)),
                            ),
                            Focus(
                              onFocusChange: (value) {
                                if (!value) {
                                  _checkSourceIPRange();
                                }
                              },
                              child: AppIpv4TextField(
                                key: const Key('sourceLastIP'),
                                controller: _sourceLastIPController,
                                onChanged: (value) {
                                  final sourceSettings = state
                                          .settings.current.sourceRestriction ??
                                      const DMZSourceRestriction(
                                          firstIPAddress: '',
                                          lastIPAddress: '');
                                  ref
                                      .read(dmzSettingsProvider.notifier)
                                      .setSettings(state.settings.current
                                          .copyWith(
                                              sourceRestriction: () =>
                                                  sourceSettings.copyWith(
                                                      lastIPAddress: value)));
                                },
                                errorText: _sourceError,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
                value: DMZSourceType.range),
          ],
          onChanged: (index, value) {
            if (value == null || value == state.settings.current.sourceType) {
              return;
            }
            ref.read(dmzSettingsProvider.notifier).setSourceType(value);
          },
        ));
  }

  Widget _destinationIPWidget(DMZSettingsState state) {
    final subnetMask =
        ref.read(dmzSettingsProvider).status.subnetMask.split('.');
    return AppListCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      title: AppText.labelLarge(loc(context).dmzDestinationIPAddress),
      description: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRadioList(
            key: const Key('destinationType'),
            initial: state.settings.current.destinationType,
            itemHeight: 56,
            items: [
              AppRadioListItem(
                  title: loc(context).ipAddress,
                  expandedWidget: state.settings.current.destinationType ==
                          DMZDestinationType.ip
                      ? Container(
                          constraints: const BoxConstraints(maxWidth: 429),
                          child: Focus(
                            onFocusChange: (value) {
                              if (!value) {
                                _checkDestinationIPAdress();
                              }
                            },
                            child: AppIpv4TextField(
                              key: const Key('destinationIP'),
                              controller: _destinationIPController,
                              readOnly: SegmentReadOnly(
                                segment1: subnetMask[0] == '255',
                                segment2: subnetMask[1] == '255',
                                segment3: subnetMask[2] == '255',
                              ),
                              onChanged: (value) {
                                ref
                                    .read(dmzSettingsProvider.notifier)
                                    .setSettings(state.settings.current
                                        .copyWith(
                                            destinationIPAddress: () => value));
                              },
                              errorText: _destinationError,
                            ),
                          ),
                        )
                      : null,
                  value: DMZDestinationType.ip),
              AppRadioListItem(
                  title: loc(context).macAddress,
                  expandedWidget: state.settings.current.destinationType ==
                          DMZDestinationType.mac
                      ? Container(
                          constraints: const BoxConstraints(maxWidth: 429),
                          child: Focus(
                            onFocusChange: (value) {
                              if (!value) {
                                _checkDestinationMACAddress();
                              }
                            },
                            child: AppMacAddressTextField(
                              key: const Key('destinationMAC'),
                              label: loc(context).macAddress,
                              invalidFormatMessage:
                                  loc(context).invalidMACAddress,
                              errorText: _destinationError,
                              controller: _destinationMACController,
                              onChanged: (value) {
                                ref
                                    .read(dmzSettingsProvider.notifier)
                                    .setSettings(state.settings.current
                                        .copyWith(
                                            destinationMACAddress: () =>
                                                value));
                              },
                            ),
                          ),
                        )
                      : null,
                  value: DMZDestinationType.mac),
            ],
            onChanged: (index, value) {
              if (value == null ||
                  value == state.settings.current.destinationType) {
                return;
              }
              ref.read(dmzSettingsProvider.notifier).setDestinationType(value);
            },
          ),
          AppGap.lg(),
          AppButton.text(
            label: loc(context).dmzViewDHCP,
            onTap: () async {
              final result = await context.pushNamed<List<DeviceListItem>?>(
                  RouteNamed.devicePicker,
                  extra: {
                    'type': 'ipv4AndMac',
                    'selectMode': 'single',
                    'onlineOnly': true,
                  });
              if (result != null) {
                if (state.settings.current.destinationType ==
                    DMZDestinationType.ip) {
                  _destinationIPController.text = result.first.ipv4Address;
                  ref.read(dmzSettingsProvider.notifier).setSettings(
                      state.settings.current.copyWith(
                          destinationIPAddress: () => result.first.ipv4Address,
                          destinationMACAddress: () => null));
                  _checkDestinationIPAdress();
                } else {
                  _destinationMACController.text = result.first.macAddress;
                  ref.read(dmzSettingsProvider.notifier).setSettings(
                      state.settings.current.copyWith(
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
