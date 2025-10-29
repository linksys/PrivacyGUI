import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/utils/internet_settings_form_validator.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
import './connection_mode_form.dart';

class PptpForm extends BaseWanForm {
  const PptpForm({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<PptpForm> createState() => _PptpFormState();
}

class _PptpFormState extends BaseWanFormState<PptpForm> {
  // Static IP fields
  late final TextEditingController _ipAddressController;
  late final TextEditingController _subnetController;
  late final TextEditingController _gatewayController;
  late final TextEditingController _dns1Controller;
  late final TextEditingController _dns2Controller;
  late final TextEditingController _dns3Controller;

  // PPTP specific fields
  late final TextEditingController _serverIpController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _ipAddressTouched = false,
      _subnetTouched = false,
      _gatewayTouched = false,
      _dns1Touched = false,
      _dns2Touched = false,
      _dns3Touched = false;
  bool _serverIpTouched = false,
      _usernameTouched = false,
      _passwordTouched = false;

  final _validator = InternetSettingsFormValidator();
  static const inputPadding = EdgeInsets.symmetric(vertical: Spacing.small2);

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
    _serverIpController =
        TextEditingController(text: ipv4Setting.serverIp ?? '');
    _usernameController =
        TextEditingController(text: ipv4Setting.username ?? '');
    _passwordController =
        TextEditingController(text: ipv4Setting.password ?? '');
  }

  @override
  void dispose() {
    _ipAddressController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _dns3Controller.dispose();
    _serverIpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PptpForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIpv4Setting =
        ref.read(internetSettingsProvider).settings.original.ipv4Setting;
    final newIpv4Setting =
        ref.read(internetSettingsProvider).settings.current.ipv4Setting;

    // Update static fields
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

    // Update PPTP fields
    if (oldIpv4Setting.serverIp != newIpv4Setting.serverIp) {
      _serverIpController.text = newIpv4Setting.serverIp ?? '';
    }
    if (oldIpv4Setting.username != newIpv4Setting.username) {
      _usernameController.text = newIpv4Setting.username ?? '';
    }
    if (oldIpv4Setting.password != newIpv4Setting.password) {
      _passwordController.text = newIpv4Setting.password ?? '';
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
          loc(context).username,
          ipv4Setting.username ?? '-',
        ),
        buildInfoCard(
          loc(context).serverIpv4Address,
          ipv4Setting.serverIp ?? '-',
        ),
        buildInfoCard(
          loc(context).vlanIdOptional,
          (ipv4Setting.wanTaggingSettingsEnable ?? false)
              ? ipv4Setting.vlanId?.toString() ?? '-'
              : '-',
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
        _pptpIpAddressMode(
            ipv4Setting.useStaticSettings ?? false, ipv4Setting, context),
        if (ipv4Setting.useStaticSettings == true)
          ..._staticIpEditing(ipv4Setting, context),
        const AppGap.small3(),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _serverIpTouched = true);
            },
            child: buildIpFormField(
              semanticLabel: 'server ip address',
              header: loc(context).serverIpv4Address,
              controller: _serverIpController,
              errorText: _serverIpTouched
                  ? getLocalizedErrorText(context,
                      _validator.validateIpAddress(ipv4Setting.serverIp))
                  : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  serverIp: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _usernameTouched = true);
            },
            child: buildEditableField(
              label: loc(context).username,
              controller: _usernameController,
              errorText:
                  _usernameTouched && (ipv4Setting.username?.isEmpty ?? true)
                      ? loc(context).invalidUsername
                      : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  username: () => value,
                ));
              },
            ),
          ),
        ),
        Padding(
          padding: inputPadding,
          child: Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) setState(() => _passwordTouched = true);
            },
            child: buildEditableField(
              label: loc(context).password,
              controller: _passwordController,
              obscureText: true,
              errorText:
                  _passwordTouched && (ipv4Setting.password?.isEmpty ?? true)
                      ? loc(context).invalidPassword
                      : null,
              onChanged: (value) {
                notifier.updateIpv4Settings(ipv4Setting.copyWith(
                  password: () => value,
                ));
              },
            ),
          ),
        ),
        if ((ipv4Setting.wanTaggingSettingsEnable ?? false) &&
            ipv4Setting.vlanId != null)
          buildInfoCard(
              '${loc(context).vlanIdOptional} (${loc(context).optional})',
              ipv4Setting.vlanId?.toString() ?? '-'),
        const Divider(),
        const ConnectionModeForm(),
      ],
    );
  }

  Widget _pptpIpAddressMode(
      bool useStaticSettings, Ipv4Setting ipv4Setting, BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.small3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleSmall(loc(context).ipAddress.capitalizeWords()),
          const AppGap.medium(),
          AppRadioList(
            initial: useStaticSettings
                ? PPTPIpAddressMode.specify
                : PPTPIpAddressMode.dhcp,
            itemHeight: 56,
            items: [
              AppRadioListItem(
                title: loc(context).obtainIPv4AddressAutomatically,
                value: PPTPIpAddressMode.dhcp,
              ),
              AppRadioListItem(
                title: loc(context).specifyIPv4Address,
                value: PPTPIpAddressMode.specify,
              ),
            ],
            onChanged: (index, type) {
              notifier.updateIpv4Settings(ipv4Setting.copyWith(
                useStaticSettings: () => type == PPTPIpAddressMode.specify,
              ));
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _staticIpEditing(Ipv4Setting ipv4Setting, BuildContext context) {
    final notifier = ref.read(internetSettingsProvider.notifier);
    return [
      Padding(
        padding: inputPadding,
        child: Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) setState(() => _ipAddressTouched = true);
          },
          child: buildIpFormField(
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
            key: const Key('staticSubnet'),
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
      const AppGap.small1(),
    ];
  }
}
