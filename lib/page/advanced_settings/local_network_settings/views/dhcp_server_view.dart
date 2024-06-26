import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class DHCPServerView extends ArgumentsConsumerStatefulView {
  const DHCPServerView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DHCPServerView> createState() => _DHCPServerViewState();
}

class _DHCPServerViewState extends ConsumerState<DHCPServerView> {
  late LocalNetworkSettingsState state;
  final _startIpAddressController = TextEditingController();
  final _maxUserAllowedController = TextEditingController();
  final _clientLeaseTimeController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  final _dns3Controller = TextEditingController();
  final _winsController = TextEditingController();
  final Map<String, String> errors = {};

  @override
  void initState() {
    super.initState();
    state = ref.read(localNetworkSettingProvider.notifier).currentSettings();
    _startIpAddressController.text = state.firstIPAddress;
    _maxUserAllowedController.text = '${state.maxUserAllowed}';
    _clientLeaseTimeController.text = '${state.clientLeaseTime}';
    if (state.dns1 != null) {
      _dns1Controller.text = state.dns1!;
    }
    if (state.dns2 != null) {
      _dns2Controller.text = state.dns2!;
    }
    if (state.dns3 != null) {
      _dns3Controller.text = state.dns3!;
    }
    if (state.wins != null) {
      _winsController.text = state.wins!;
    }
  }

  @override
  void dispose() {
    super.dispose();
    _startIpAddressController.dispose();
    _maxUserAllowedController.dispose();
    _clientLeaseTimeController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _dns3Controller.dispose();
    _winsController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).dhcpServer.capitalizeWords(),
      onBackTap: _isEdited()
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                context.pop();
              }
            }
          : null,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isEdited(),
        onPositiveTap: () {
          ref.read(localNetworkSettingProvider.notifier).updateState(state);
          context.pop();
        },
      ),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSettingCard.noBorder(
              title: loc(context).dhcpServer.capitalizeWords(),
              trailing: AppSwitch(
                value: state.isDHCPEnabled,
                onChanged: (enabled) {
                  setState(() {
                    state = state.copyWith(
                      isDHCPEnabled: enabled,
                    );
                  });
                },
              ),
            ),
            const AppGap.large3(),
            Visibility(
              visible: state.isDHCPEnabled,
              child: dhcpSettings(),
            ),
          ],
        ),
      ),
    );
  }

  bool _isEdited() {
    final currentState = ref.read(localNetworkSettingProvider);
    return state != currentState;
  }

  updateErrorPrompts(String key, String? value) {
    if (value != null) {
      errors[key] = value;
    } else {
      errors.remove(key);
    }
  }

  Widget dhcpSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIPFormField(
          header: AppText.bodySmall(
            loc(context).startIpAddress,
          ),
          controller: _startIpAddressController,
          border: const OutlineInputBorder(),
          errorText: errors['StartIpAddress'],
          octet1ReadOnly: true,
          octet2ReadOnly: true,
          onFocusChanged: (focused) {
            if (focused) return;
            // Start Ip input finishes
            final result =
                ref.read(localNetworkSettingProvider.notifier).startIpFinished(
                      _startIpAddressController.text,
                      state,
                    );
            setState(() {
              updateErrorPrompts(
                'StartIpAddress',
                result.$1 ? null : loc(context).invalidIpOrSameAsHostIp,
              );
              state = result.$2;
            });
          },
          onChanged: (value) {
            setState(() {
              updateErrorPrompts('StartIpAddress', null);
            });
          },
        ),
        const AppGap.large3(),
        AppTextField.minMaxNumber(
          headerText: loc(context).maximumNumberOfUsers,
          descriptionText: '1 ${loc(context).to} ${state.maxUserLimit}',
          max: state.maxUserLimit,
          controller: _maxUserAllowedController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (focused) return;
            // Max user input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .maxUserAllowedFinished(
                  _maxUserAllowedController.text,
                  state,
                );
            setState(() {
              updateErrorPrompts(
                'MaxUserAllowed',
                result.$1 ? null : loc(context).invalidNumber,
              );
              state = result.$2;
            });
          },
        ),
        const AppGap.large3(),
        _ipAddressRange(),
        const AppGap.large3(),
        AppTextField.minMaxNumber(
          headerText: loc(context).clientLeaseTime,
          min: state.minAllowDHCPLeaseMinutes,
          max: state.maxAllowDHCPLeaseMinutes,
          controller: _clientLeaseTimeController,
          border: const OutlineInputBorder(),
          descriptionText: loc(context).minutes,
          onFocusChanged: (focused) {
            if (focused) return;
            // Client lease time input finishes
            final result = ref
                .read(localNetworkSettingProvider.notifier)
                .clientLeaseFinished(
                  _clientLeaseTimeController.text,
                  state,
                );
            setState(() {
              updateErrorPrompts(
                'LeaseTime',
                result.$1 ? null : loc(context).invalidNumber,
              );
              state = result.$2;
            });
          },
        ),
        const AppGap.large3(),
        _dnsAndWinsInput(),
      ],
    );
  }

  Widget _ipAddressRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodySmall(loc(context).ipAddressRange),
        const AppGap.small3(),
        Row(
          children: [
            AppText.labelLarge(state.firstIPAddress),
            const AppGap.medium(),
            AppText.bodyMedium(loc(context).to),
            const AppGap.medium(),
            AppText.labelLarge(state.lastIPAddress),
          ],
        ),
      ],
    );
  }

  Widget _dnsAndWinsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIPFormField(
          header: AppText.bodySmall(
            loc(context).staticDns1,
          ),
          controller: _dns1Controller,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused && _dns1Controller.text.isNotEmpty) {
              // DNS1 input finishes
              final result = ref
                  .read(localNetworkSettingProvider.notifier)
                  .staticDns1Finished(
                    _dns1Controller.text,
                    state,
                  );
              setState(() {
                updateErrorPrompts(
                  'DNS1',
                  result.$1 ? null : loc(context).invalidIpAddress,
                );
                state = result.$2;
              });
            }
          },
        ),
        const AppGap.medium(),
        AppIPFormField(
          header: AppText.bodySmall(
            loc(context).staticDns2,
          ),
          controller: _dns2Controller,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused && _dns2Controller.text.isNotEmpty) {
              // DNS2 input finishes
              final result = ref
                  .read(localNetworkSettingProvider.notifier)
                  .staticDns2Finished(
                    _dns2Controller.text,
                    state,
                  );
              setState(() {
                updateErrorPrompts(
                  'DNS2',
                  result.$1 ? null : loc(context).invalidIpAddress,
                );
                state = result.$2;
              });
            }
          },
        ),
        const AppGap.medium(),
        AppIPFormField(
          header: AppText.bodySmall(
            loc(context).staticDns3,
          ),
          controller: _dns3Controller,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused && _dns3Controller.text.isNotEmpty) {
              // DNS3 input finishes
              final result = ref
                  .read(localNetworkSettingProvider.notifier)
                  .staticDns3Finished(
                    _dns3Controller.text,
                    state,
                  );
              setState(() {
                updateErrorPrompts(
                  'DNS3',
                  result.$1 ? null : loc(context).invalidIpAddress,
                );
                state = result.$2;
              });
            }
          },
        ),
        const AppGap.medium(),
        AppIPFormField(
          header: AppText.bodySmall(
            loc(context).wins,
          ),
          controller: _winsController,
          border: const OutlineInputBorder(),
          onFocusChanged: (focused) {
            if (!focused && _winsController.text.isNotEmpty) {
              // WINS server input finishes
              final result = ref
                  .read(localNetworkSettingProvider.notifier)
                  .winsServerFinished(
                    _winsController.text,
                    state,
                  );
              setState(() {
                updateErrorPrompts(
                  'WINS',
                  result.$1 ? null : loc(context).invalidIpAddress,
                );
                state = result.$2;
              });
            }
          },
        ),
      ],
    );
  }
}
