import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';

class DHCPServerView extends ArgumentsConsumerStatefulView {
  const DHCPServerView({super.key, super.args});

  @override
  ConsumerState<DHCPServerView> createState() => _DHCPServerViewState();
}

class _DHCPServerViewState extends ConsumerState<DHCPServerView> {
  late LocalNetworkSettingsNotifier _notifier;
  late LocalNetworkSettingsState _originState;
  final _startIpAddressController = TextEditingController();
  final _maxUserAllowedController = TextEditingController();
  final _clientLeaseTimeController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  final _dns3Controller = TextEditingController();
  final _winsController = TextEditingController();
  final EdgeInsets inputPadding =
      EdgeInsets.symmetric(vertical: Spacing.small3);
  bool firstLaunch = true;
  bool enable = true;

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(localNetworkSettingProvider.notifier);
    _originState = ref.read(localNetworkSettingProvider);
    _startIpAddressController.text = _originState.firstIPAddress;
    _maxUserAllowedController.text = '${_originState.maxUserAllowed}';
    _clientLeaseTimeController.text = '${_originState.clientLeaseTime}';
    _dns1Controller.text = _originState.dns1 ?? '';
    _dns2Controller.text = _originState.dns2 ?? '';
    _dns3Controller.text = _originState.dns3 ?? '';
    _winsController.text = _originState.wins ?? '';
    enable = _originState.isDHCPEnabled;
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
    final state = ref.read(localNetworkSettingProvider);
    return AppCard(
      padding: EdgeInsets.all(Spacing.large2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSwitchTriggerTile(
            padding: EdgeInsets.only(),
            title: AppText.titleMedium(loc(context).dhcpServer),
            semanticLabel: 'dhcp server',
            value: enable,
            onChanged: (value) {
              _notifier.updateState(state.copyWith(isDHCPEnabled: value));
              setState(() {
                enable = value;
              });
            },
          ),
          Visibility(
            visible: state.isDHCPEnabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _divider(),
                dhcpSettings(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
      child: Divider(),
    );
  }

  Widget dhcpSettings(LocalNetworkSettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'start Ip Address',
            header: AppText.bodySmall(loc(context).startIpAddress),
            controller: _startIpAddressController,
            border: const OutlineInputBorder(),
            errorText: state.errorTextMap['StartIpAddress'],
            octet1ReadOnly: true,
            octet2ReadOnly: true,
            onChanged: (value) {
              final result = _notifier.startIpFinished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'StartIpAddress',
                result.$1 ? null : loc(context).invalidIpOrSameAsHostIp,
              );
            },
          ),
        ),
        const AppGap.small2(),
        Padding(
          padding: inputPadding,
          child: AppTextField.minMaxNumber(
            headerText: loc(context).maximumNumberOfUsers,
            descriptionText: '1 ${loc(context).to} ${state.maxUserLimit}',
            max: state.maxUserLimit,
            controller: _maxUserAllowedController,
            errorText: state.errorTextMap['MaxUserAllowed'],
            border: const OutlineInputBorder(),
            onChanged: (value) {
              final result = _notifier.maxUserAllowedFinished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'MaxUserAllowed',
                result.$1 ? null : loc(context).invalidNumber,
              );
            },
          ),
        ),
        const AppGap.small1(),
        _ipAddressRange(state),
        const AppGap.large2(),
        Padding(
          padding: inputPadding,
          child: AppTextField.minMaxNumber(
            headerText: loc(context).clientLeaseTime,
            min: state.minAllowDHCPLeaseMinutes,
            max: state.maxAllowDHCPLeaseMinutes,
            controller: _clientLeaseTimeController,
            errorText: state.errorTextMap['LeaseTime'],
            border: const OutlineInputBorder(),
            descriptionText: loc(context).minutes,
            onChanged: (value) {
              final result = _notifier.clientLeaseFinished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'LeaseTime',
                result.$1 ? null : loc(context).invalidNumber,
              );
            },
          ),
        ),
        const AppGap.small1(),
        _dnsAndWinsInput(state),
        _divider(),
        const AppGap.small3(),
        AppCard(
          padding: const EdgeInsets.symmetric(
              vertical: Spacing.medium, horizontal: Spacing.large2),
          child: Row(
            children: [
              AppText.labelLarge(loc(context).dhcpReservations),
              const Spacer(),
              AppText.labelLarge("${state.dhcpReservationList.length}"),
              const AppGap.medium(),
              Icon(LinksysIcons.chevronRight),
            ],
          ),
          onTap: () {
            context.pushNamed(RoutePath.dhcpReservation);
          },
        ),
      ],
    );
  }

  Widget _ipAddressRange(LocalNetworkSettingsState state) {
    return Padding(
      padding: inputPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _dnsAndWinsInput(LocalNetworkSettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'static Dns 1',
            header: AppText.bodySmall(
              loc(context).staticDns1,
            ),
            controller: _dns1Controller,
            errorText: state.errorTextMap['DNS1'],
            border: const OutlineInputBorder(),
            onChanged: (value) {
              final result = _notifier.staticDns1Finished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'DNS1',
                result.$1 || value.isEmpty
                    ? null
                    : loc(context).invalidIpAddress,
              );
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'static Dns 2',
            header: AppText.bodySmall(
              loc(context).staticDns2,
            ),
            controller: _dns2Controller,
            errorText: state.errorTextMap['DNS2'],
            border: const OutlineInputBorder(),
            onChanged: (value) {
              final result = _notifier.staticDns2Finished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'DNS2',
                result.$1 || value.isEmpty
                    ? null
                    : loc(context).invalidIpAddress,
              );
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'static Dns 3',
            header: AppText.bodySmall(
              loc(context).staticDns3,
            ),
            controller: _dns3Controller,
            errorText: state.errorTextMap['DNS3'],
            border: const OutlineInputBorder(),
            onChanged: (value) {
              final result = _notifier.staticDns3Finished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'DNS3',
                result.$1 || value.isEmpty
                    ? null
                    : loc(context).invalidIpAddress,
              );
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIPFormField(
            semanticLabel: 'wins',
            header: AppText.bodySmall(
              loc(context).wins,
            ),
            controller: _winsController,
            errorText: state.errorTextMap['WINS'],
            border: const OutlineInputBorder(),
            onChanged: (value) {
              final result = _notifier.winsServerFinished(value, state);
              _notifier.updateState(result.$2);
              _notifier.updateErrorPrompts(
                'WINS',
                result.$1 || value.isEmpty
                    ? null
                    : loc(context).invalidIpAddress,
              );
            },
          ),
        ),
      ],
    );
  }
}
