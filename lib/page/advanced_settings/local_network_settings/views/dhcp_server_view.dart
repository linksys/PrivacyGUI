import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/components/composed/app_switch_trigger_tile.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';

class DHCPServerView extends ArgumentsConsumerStatefulView {
  const DHCPServerView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<DHCPServerView> createState() => _DHCPServerViewState();
}

class _DHCPServerViewState extends ConsumerState<DHCPServerView> {
  late LocalNetworkSettingsNotifier _notifier;
  final _startIpAddressController = TextEditingController();
  final _maxUserAllowedController = TextEditingController();
  final _clientLeaseTimeController = TextEditingController();
  final _dns1Controller = TextEditingController();
  final _dns2Controller = TextEditingController();
  final _dns3Controller = TextEditingController();
  final _winsController = TextEditingController();
  final EdgeInsets inputPadding = EdgeInsets.symmetric(vertical: AppSpacing.sm);

  /// Returns the number of full octets (value 255) in a subnet mask.
  /// e.g., "255.255.255.0" → 3, "255.255.0.0" → 2, "255.0.0.0" → 1
  int _fullOctetCount(String subnetMask) {
    if (subnetMask.isEmpty) return 0;
    final octets = subnetMask.split('.');
    if (octets.length != 4) return 0;
    int count = 0;
    for (final octet in octets) {
      if (int.tryParse(octet) == 255) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(localNetworkSettingProvider.notifier);
    final state = ref.read(localNetworkSettingProvider);
    _updateControllers(state);
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

  void _updateControllers(LocalNetworkSettingsState state) {
    if (_startIpAddressController.text !=
        state.settings.current.firstIPAddress) {
      _startIpAddressController.text = state.settings.current.firstIPAddress;
    }
    if (_maxUserAllowedController.text !=
        '${state.settings.current.maxUserAllowed}') {
      _maxUserAllowedController.text =
          '${state.settings.current.maxUserAllowed}';
    }
    if (_clientLeaseTimeController.text !=
        '${state.settings.current.clientLeaseTime}') {
      _clientLeaseTimeController.text =
          '${state.settings.current.clientLeaseTime}';
    }
    if (_dns1Controller.text != (state.settings.current.dns1 ?? '')) {
      _dns1Controller.text = state.settings.current.dns1 ?? '';
    }
    if (_dns2Controller.text != (state.settings.current.dns2 ?? '')) {
      _dns2Controller.text = state.settings.current.dns2 ?? '';
    }
    if (_dns3Controller.text != (state.settings.current.dns3 ?? '')) {
      _dns3Controller.text = state.settings.current.dns3 ?? '';
    }
    if (_winsController.text != (state.settings.current.wins ?? '')) {
      _winsController.text = state.settings.current.wins ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localNetworkSettingProvider);

    ref.listen(localNetworkSettingProvider, (previous, next) {
      if (previous != next) {
        _updateControllers(next);
      }
    });

    return AppCard(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSwitchTriggerTile(
            key: const Key('dhcpServerSwitch'),
            padding: EdgeInsets.only(),
            title: AppText.titleMedium(loc(context).dhcpServer),
            semanticLabel: 'dhcp server',
            value: state.settings.current.isDHCPEnabled,
            onChanged: (value) {
              _notifier.updateSettings(
                  state.settings.current.copyWith(isDHCPEnabled: value));
            },
          ),
          Visibility(
            visible: state.settings.current.isDHCPEnabled,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ),
      child: const Divider(),
    );
  }

  Widget dhcpSettings(LocalNetworkSettingsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: inputPadding,
          child: AppIpv4TextField(
            key: Key('startIpAddressTextField'),
            label: loc(context).startIpAddress,
            controller: _startIpAddressController,
            readOnly: SegmentReadOnly.lockPrefix(
              _fullOctetCount(state.settings.current.subnetMask),
            ),
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state.status
                    .errorTextMap[LocalNetworkErrorPrompt.startIpAddress.name]),
                ipAddress: state.settings.current.ipAddress,
                subnetMask: state.settings.current.subnetMask),
            onChanged: (value) {
              _notifier.startIpChanged(context, value);
            },
          ),
        ),
        AppGap.sm(),
        Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: AppText.labelLarge(loc(context).maximumNumberOfUsers)),
        Padding(
          padding: inputPadding,
          child: AppTextField(
            key: Key('maxUsersTextField'),
            hintText: loc(context).maximumNumberOfUsers,
            controller: _maxUserAllowedController,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(
                    state.status.errorTextMap[
                        LocalNetworkErrorPrompt.maxUserAllowed.name])),
            onChanged: (value) {
              _notifier.maxUserAllowedChanged(context, value);
            },
          ),
        ),
        AppGap.xs(),
        _ipAddressRange(state),
        AppGap.xl(),
        Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: AppText.labelLarge(loc(context).clientLeaseTime)),
        Padding(
          padding: inputPadding,
          child: AppTextField(
            key: Key('clientLeaseTimeTextField'),
            hintText: loc(context).clientLeaseTime,
            controller: _clientLeaseTimeController,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state.status
                    .errorTextMap[LocalNetworkErrorPrompt.leaseTime.name])),
            onChanged: (value) {
              final result =
                  _notifier.clientLeaseFinished(value, state.settings.current);
              _notifier.updateSettings(result.$2);
              _notifier.updateErrorPrompts(
                LocalNetworkErrorPrompt.leaseTime.name,
                result.$1 ? null : LocalNetworkErrorPrompt.leaseTime.name,
              );
            },
          ),
        ),
        AppGap.xs(),
        _dnsAndWinsInput(state),
        _divider(),
        AppGap.sm(),
        AppCard(
          padding: EdgeInsets.symmetric(
              vertical: AppSpacing.md, horizontal: AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: AppText.labelLarge(loc(context).dhcpReservations),
              ),
              const Spacer(),
              AppText.labelLarge("${state.status.dhcpReservationList.length}"),
              AppGap.md(),
              Icon(AppFontIcons.chevronRight),
            ],
          ),
          onTap: () {
            if (_notifier.isDirty()) {
              _showSaveChangeAlert();
            } else {
              context.pushNamed(RoutePath.dhcpReservation);
            }
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
          AppGap.sm(),
          Row(
            children: [
              AppText.labelLarge(state.settings.current.firstIPAddress),
              AppGap.md(),
              AppText.bodyMedium(loc(context).to),
              AppGap.md(),
              AppText.labelLarge(state.settings.current.lastIPAddress),
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
          child: AppIpv4TextField(
            key: Key('dns1TextField'),
            label: loc(context).staticDns1,
            controller: _dns1Controller,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.dns1.name])),
            onChanged: (value) {
              final result =
                  _notifier.staticDns1Finished(value, state.settings.current);
              _notifier.updateSettings(result.$2);
              _notifier.updateErrorPrompts(
                LocalNetworkErrorPrompt.dns1.name,
                result.$1 || value.isEmpty
                    ? null
                    : LocalNetworkErrorPrompt.dns1.name,
              );
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIpv4TextField(
            key: Key('dns2TextField'),
            label: loc(context).staticDns2,
            controller: _dns2Controller,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.dns2.name])),
            onChanged: (value) {
              final result =
                  _notifier.staticDns2Finished(value, state.settings.current);
              _notifier.updateSettings(result.$2);
              _notifier.updateErrorPrompts(
                LocalNetworkErrorPrompt.dns2.name,
                result.$1 || value.isEmpty
                    ? null
                    : LocalNetworkErrorPrompt.dns2.name,
              );
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIpv4TextField(
            key: Key('dns3TextField'),
            label: loc(context).staticDns3,
            controller: _dns3Controller,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.dns3.name])),
            onChanged: (value) {
              final result =
                  _notifier.staticDns3Finished(value, state.settings.current);
              _notifier.updateSettings(result.$2);
              _notifier.updateErrorPrompts(
                LocalNetworkErrorPrompt.dns3.name,
                result.$1 || value.isEmpty
                    ? null
                    : LocalNetworkErrorPrompt.dns3.name,
              );
            },
          ),
        ),
        Padding(
          padding: inputPadding,
          child: AppIpv4TextField(
            key: Key('winsTextField'),
            label: loc(context).wins,
            controller: _winsController,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.wins.name])),
            onChanged: (value) {
              final result =
                  _notifier.winsServerFinished(value, state.settings.current);
              _notifier.updateSettings(result.$2);
              _notifier.updateErrorPrompts(
                LocalNetworkErrorPrompt.wins.name,
                result.$1 || value.isEmpty
                    ? null
                    : LocalNetworkErrorPrompt.wins.name,
              );
            },
          ),
        ),
      ],
    );
  }

  _showSaveChangeAlert() {
    showMessageAppDialog(
      context,
      title: '${loc(context).saveChanges}?',
      message:
          '${loc(context).saveLocalNetworkChangesDesc1}\n\n${loc(context).saveLocalNetworkChangesDesc2}\n\n${loc(context).doYouWantToSaveTheLocalNetworkSettings}',
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          label: loc(context).save,
          onTap: () {
            context.pop();
            _notifier.save();
          },
        ),
      ],
    );
  }
}
