import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/internet_settings_form_validator.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

class StaticIpForm extends BaseWanForm {
  const StaticIpForm({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<StaticIpForm> createState() => _StaticIpFormState();
}

class _StaticIpFormState extends BaseWanFormState<StaticIpForm> {
  late final TextEditingController _ipAddressController;
  late final TextEditingController _subnetController;
  late final TextEditingController _gatewayController;
  late final TextEditingController _dns1Controller;
  late final TextEditingController _dns2Controller;
  late final TextEditingController _dns3Controller;

  bool _ipAddressTouched = false;
  bool _subnetTouched = false;
  bool _gatewayTouched = false;
  bool _dns1Touched = false;
  bool _dns2Touched = false;
  bool _dns3Touched = false;

  final _validator = InternetSettingsFormValidator();

  static const inputPadding = EdgeInsets.symmetric(vertical: 8);

  @override
  void initState() {
    super.initState();
    final ipv4Setting =
        ref.read(internetSettingsProvider).settings.current.ipv4Setting;
    _ipAddressController =
        TextEditingController(text: ipv4Setting.staticIpAddress ?? '');
    _subnetController = TextEditingController(
        text: ipv4Setting.networkPrefixLength != null
            ? NetworkUtils.prefixLengthToSubnetMask(
                ipv4Setting.networkPrefixLength!)
            : '');
    _gatewayController =
        TextEditingController(text: ipv4Setting.staticGateway ?? '');
    _dns1Controller = TextEditingController(text: ipv4Setting.staticDns1 ?? '');
    _dns2Controller = TextEditingController(text: ipv4Setting.staticDns2 ?? '');
    _dns3Controller = TextEditingController(text: ipv4Setting.staticDns3 ?? '');
  }

  @override
  void dispose() {
    _ipAddressController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _dns3Controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StaticIpForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIpv4Setting =
        ref.read(internetSettingsProvider).settings.original.ipv4Setting;
    final newIpv4Setting =
        ref.read(internetSettingsProvider).settings.current.ipv4Setting;

    if (oldIpv4Setting.staticIpAddress != newIpv4Setting.staticIpAddress) {
      _ipAddressController.text = newIpv4Setting.staticIpAddress ?? '';
    }
    if (oldIpv4Setting.networkPrefixLength !=
        newIpv4Setting.networkPrefixLength) {
      _subnetController.text = newIpv4Setting.networkPrefixLength != null
          ? NetworkUtils.prefixLengthToSubnetMask(
              newIpv4Setting.networkPrefixLength!)
          : '';
    }
    if (oldIpv4Setting.staticGateway != newIpv4Setting.staticGateway) {
      _gatewayController.text = newIpv4Setting.staticGateway ?? '';
    }
    if (oldIpv4Setting.staticDns1 != newIpv4Setting.staticDns1) {
      _dns1Controller.text = newIpv4Setting.staticDns1 ?? '';
    }
    if (oldIpv4Setting.staticDns2 != newIpv4Setting.staticDns2) {
      _dns2Controller.text = newIpv4Setting.staticDns2 ?? '';
    }
    if (oldIpv4Setting.staticDns3 != newIpv4Setting.staticDns3) {
      _dns3Controller.text = newIpv4Setting.staticDns3 ?? '';
    }
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    final ipv4Setting =
        ref.watch(internetSettingsProvider).settings.current.ipv4Setting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoCard(
          loc(context).ipAddress,
          ipv4Setting.staticIpAddress ?? '-',
        ),
        buildInfoCard(
          loc(context).subnetMask,
          ipv4Setting.networkPrefixLength != null
              ? NetworkUtils.prefixLengthToSubnetMask(
                  ipv4Setting.networkPrefixLength!)
              : '-',
        ),
        buildInfoCard(
          loc(context).gateway,
          ipv4Setting.staticGateway ?? '-',
        ),
        if (ipv4Setting.staticDns1 != null ||
            ipv4Setting.staticDns2 != null ||
            ipv4Setting.staticDns3 != null)
          buildInfoCard(
            loc(context).dns,
            [
              if (ipv4Setting.staticDns1 != null) ipv4Setting.staticDns1!,
              if (ipv4Setting.staticDns2 != null) ipv4Setting.staticDns2!,
              if (ipv4Setting.staticDns3 != null) ipv4Setting.staticDns3!,
            ].join(', '),
          ),
      ],
    );
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    final ipv4Setting =
        ref.watch(internetSettingsProvider).settings.current.ipv4Setting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _ipAddressTouched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('ipAddress'),
              semanticLabel: 'ip address',
              header: loc(context).internetIpv4Address,
              controller: _ipAddressController,
              errorText: _ipAddressTouched
                  ? getLocalizedErrorText(context,
                      _validator.validateIpAddress(ipv4Setting.staticIpAddress))
                  : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  staticIpAddress: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _subnetTouched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('subnetMask'),
              semanticLabel: 'subnet mask',
              header: loc(context).subnetMask.capitalizeWords(),
              controller: _subnetController,
              errorText: _subnetTouched
                  ? getLocalizedErrorText(context,
                      _validator.validateSubnetMask(_subnetController.text))
                  : null,
              onChanged: (value) {
                if (_validator.validateSubnetMask(value) == null) {
                  notifier.updateIpv4Settings(ipv4Setting.copyWith(
                    networkPrefixLength: () =>
                        NetworkUtils.subnetMaskToPrefixLength(value),
                  ));
                }
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _gatewayTouched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('gateway'),
              semanticLabel: 'default gateway',
              header: loc(context).defaultGateway,
              controller: _gatewayController,
              errorText: _gatewayTouched
                  ? getLocalizedErrorText(context,
                      _validator.validateIpAddress(ipv4Setting.staticGateway))
                  : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  staticGateway: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _dns1Touched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('dns1'),
              semanticLabel: 'dns 1',
              header: loc(context).dns1,
              controller: _dns1Controller,
              errorText: _dns1Touched
                  ? getLocalizedErrorText(context,
                      _validator.validateIpAddress(ipv4Setting.staticDns1))
                  : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  staticDns1: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _dns2Touched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('dns2'),
              semanticLabel: 'dns 2 optional',
              header: loc(context).dns2Optional,
              controller: _dns2Controller,
              errorText: _dns2Touched
                  ? getLocalizedErrorText(context,
                      _validator.validateIpAddress(ipv4Setting.staticDns2))
                  : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  staticDns2: () => value.isEmpty ? null : value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _dns3Touched = true);
            },
            child: buildIpFormField(
              key: const ValueKey('dns3'),
              semanticLabel: 'dns 3 optional',
              header: loc(context).dns3Optional,
              controller: _dns3Controller,
              errorText: _dns3Touched
                  ? getLocalizedErrorText(context,
                      _validator.validateIpAddress(ipv4Setting.staticDns3))
                  : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  staticDns3: () => value.isEmpty ? null : value,
                ));
              },
            ),
          ),
        ),
        AppGap.xs(),
      ],
    );
  }
}
