import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
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
  final EdgeInsets inputPadding =
      EdgeInsets.symmetric(vertical: Spacing.small3);

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
    _startIpAddressController.text = state.settings.current.firstIPAddress;
    _maxUserAllowedController.text = '${state.settings.current.maxUserAllowed}';
    _clientLeaseTimeController.text =
        '${state.settings.current.clientLeaseTime}';
    _dns1Controller.text = state.settings.current.dns1 ?? '';
    _dns2Controller.text = state.settings.current.dns2 ?? '';
    _dns3Controller.text = state.settings.current.dns3 ?? '';
    _winsController.text = state.settings.current.wins ?? '';
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
      padding: EdgeInsets.all(Spacing.large2),
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
            key: Key('startIpAddressTextField'),
            header: AppText.bodySmall(loc(context).startIpAddress),
            controller: _startIpAddressController,
            border: const OutlineInputBorder(),
            autoFocus: true,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state.status
                    .errorTextMap[LocalNetworkErrorPrompt.startIpAddress.name]),
                ipAddress: state.settings.current.ipAddress,
                subnetMask: state.settings.current.subnetMask),
            octet1ReadOnly: true,
            octet2ReadOnly: true,
            onChanged: (value) {
              _notifier.startIpChanged(context, value);
            },
          ),
        ),
        const AppGap.small2(),
        Padding(
          padding: inputPadding,
          child: AppTextField.minMaxNumber(
            key: Key('maxUsersTextField'),
            headerText: loc(context).maximumNumberOfUsers,
            descriptionText:
                '1 ${loc(context).to} ${state.status.maxUserLimit}',
            min: 1,
            max: state.status.maxUserLimit,
            controller: _maxUserAllowedController,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(
                    state.status.errorTextMap[
                        LocalNetworkErrorPrompt.maxUserAllowed.name])),
            border: const OutlineInputBorder(),
            onChanged: (value) {
              _notifier.maxUserAllowedChanged(context, value);
            },
          ),
        ),
        const AppGap.small1(),
        _ipAddressRange(state),
        const AppGap.large2(),
        Padding(
          padding: inputPadding,
          child: AppTextField.minMaxNumber(
            key: Key('clientLeaseTimeTextField'),
            headerText: loc(context).clientLeaseTime,
            min: state.status.minAllowDHCPLeaseMinutes,
            max: state.status.maxAllowDHCPLeaseMinutes,
            controller: _clientLeaseTimeController,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state.status
                    .errorTextMap[LocalNetworkErrorPrompt.leaseTime.name])),
            border: const OutlineInputBorder(),
            descriptionText: loc(context).minutes,
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
        const AppGap.small1(),
        _dnsAndWinsInput(state),
        _divider(),
        const AppGap.small3(),
        AppCard(
          padding: const EdgeInsets.symmetric(
              vertical: Spacing.medium, horizontal: Spacing.large2),
          child: Row(
            children: [
              Expanded(
                child: AppText.labelLarge(loc(context).dhcpReservations),
              ),
              const Spacer(),
              AppText.labelLarge("${state.status.dhcpReservationList.length}"),
              const AppGap.medium(),
              Icon(LinksysIcons.chevronRight),
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
          const AppGap.small3(),
          Row(
            children: [
              AppText.labelLarge(state.settings.current.firstIPAddress),
              const AppGap.medium(),
              AppText.bodyMedium(loc(context).to),
              const AppGap.medium(),
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
          child: AppIPFormField(
            key: Key('dns1TextField'),
            semanticLabel: 'static Dns 1',
            header: AppText.bodySmall(
              loc(context).staticDns1,
            ),
            controller: _dns1Controller,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.dns1.name])),
            border: const OutlineInputBorder(),
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
          child: AppIPFormField(
            key: Key('dns2TextField'),
            semanticLabel: 'static Dns 2',
            header: AppText.bodySmall(
              loc(context).staticDns2,
            ),
            controller: _dns2Controller,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.dns2.name])),
            border: const OutlineInputBorder(),
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
          child: AppIPFormField(
            key: Key('dns3TextField'),
            semanticLabel: 'static Dns 3',
            header: AppText.bodySmall(
              loc(context).staticDns3,
            ),
            controller: _dns3Controller,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.dns3.name])),
            border: const OutlineInputBorder(),
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
          child: AppIPFormField(
            key: Key('winsTextField'),
            semanticLabel: 'wins',
            header: AppText.bodySmall(
              loc(context).wins,
            ),
            controller: _winsController,
            errorText: LocalNetworkErrorPrompt.getErrorText(
                context: context,
                error: LocalNetworkErrorPrompt.resolve(state
                    .status.errorTextMap[LocalNetworkErrorPrompt.wins.name])),
            border: const OutlineInputBorder(),
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
        AppTextButton(
          loc(context).cancel,
          color: Theme.of(context).colorScheme.onSurface,
          onTap: () {
            context.pop();
          },
        ),
        AppTextButton(
          loc(context).save,
          color: Theme.of(context).colorScheme.primary,
          onTap: () {
            context.pop();
            _notifier.save();
          },
        ),
      ],
    );
  }
}
