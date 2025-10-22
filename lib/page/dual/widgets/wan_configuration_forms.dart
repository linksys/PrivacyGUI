import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dual/models/wan_configuration.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';
import 'package:privacy_gui/core/utils/extension.dart'; // For capitalizeWords

// Enum for PPTP IP Address Mode
enum PPTPIpAddressMode {
  dhcp,
  specify,
}

// Static WAN Settings Form
class StaticWANSettingsForm extends StatefulWidget {
  final bool isPrimary;
  final DualWANConfiguration wan;
  final Function(DualWANConfiguration) onChanged;
  final Map<TextEditingController, String?> errors;

  const StaticWANSettingsForm({
    Key? key,
    required this.isPrimary,
    required this.wan,
    required this.onChanged,
    required this.errors,
  }) : super(key: key);

  @override
  State<StaticWANSettingsForm> createState() => _StaticWANSettingsFormState();
}

class _StaticWANSettingsFormState extends State<StaticWANSettingsForm> {
  late final TextEditingController _staticIpAddressController;
  late final TextEditingController _staticSubnetController;
  late final TextEditingController _staticGatewayController;
  late final TextEditingController _staticDNSController;
  late final TextEditingController _staticDNS2Controller;
  late final TextEditingController _staticDNS3Controller;

  @override
  void initState() {
    super.initState();
    _staticIpAddressController = TextEditingController(text: widget.wan.staticIpAddress ?? '');
    _staticSubnetController = TextEditingController(
        text: widget.wan.networkPrefixLength != null
            ? NetworkUtils.prefixLengthToSubnetMask(widget.wan.networkPrefixLength!)
            : '');
    _staticGatewayController = TextEditingController(text: widget.wan.staticGateway ?? '');
    _staticDNSController = TextEditingController(text: widget.wan.staticDns1 ?? '');
    _staticDNS2Controller = TextEditingController(text: widget.wan.staticDns2 ?? '');
    _staticDNS3Controller = TextEditingController(text: widget.wan.staticDns3 ?? '');
  }

  @override
  void dispose() {
    _staticIpAddressController.dispose();
    _staticSubnetController.dispose();
    _staticGatewayController.dispose();
    _staticDNSController.dispose();
    _staticDNS2Controller.dispose();
    _staticDNS3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).ipAddress),
        AppIPFormField(
          key: ValueKey(widget.isPrimary
              ? 'primaryStaticIpAddress'
              : 'secondaryStaticIpAddress'),
          semanticLabel:
              widget.isPrimary ? 'primaryStaticIpAddress' : 'secondaryStaticIpAddress',
          identifier:
              widget.isPrimary ? 'primaryStaticIpAddress' : 'secondaryStaticIpAddress',
          border: const OutlineInputBorder(),
          controller: _staticIpAddressController,
          onChanged: (value) {
            final isValid = IpAddressRequiredValidator().validate(value);
            if (isValid) {
              widget.errors.remove(_staticIpAddressController);
            } else {
              widget.errors[_staticIpAddressController] = loc(context).invalidIpAddress;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _staticIpAddressController.text;
              widget.onChanged(widget.wan.copyWith(staticIpAddress: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_staticIpAddressController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).subnetMask),
        AppIPFormField(
          key: ValueKey(
              widget.isPrimary ? 'primaryStaticSubnet' : 'secondaryStaticSubnet'),
          semanticLabel:
              widget.isPrimary ? 'primaryStaticSubnet' : 'secondaryStaticSubnet',
          identifier:
              widget.isPrimary ? 'primaryStaticSubnet' : 'secondaryStaticSubnet',
          border: const OutlineInputBorder(),
          controller: _staticSubnetController,
          onChanged: (value) {
            final isValid = SubnetMaskValidator().validate(value);
            if (isValid) {
              widget.errors.remove(_staticSubnetController);
            } else {
              widget.errors[_staticSubnetController] = loc(context).invalidSubnetMask;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _staticSubnetController.text;
              // Prevent to update networkPrefixLength if subnet mask is invalid
              if (SubnetMaskValidator().validate(value)) {
                widget.onChanged(widget.wan.copyWith(
                    networkPrefixLength: () =>
                        NetworkUtils.subnetMaskToPrefixLength(value)));
              }
              setState(() {});
            }
          },
          errorText: widget.errors[_staticSubnetController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).gateway),
        AppIPFormField(
          key: ValueKey(
              widget.isPrimary ? 'primaryStaticGateway' : 'secondaryStaticGateway'),
          semanticLabel:
              widget.isPrimary ? 'primaryStaticGateway' : 'secondaryStaticGateway',
          identifier:
              widget.isPrimary ? 'primaryStaticGateway' : 'secondaryStaticGateway',
          border: const OutlineInputBorder(),
          controller: _staticGatewayController,
          onChanged: (value) {
            final isValid = IpAddressValidator().validate(value);
            if (isValid) {
              widget.errors.remove(_staticGatewayController);
            } else {
              widget.errors[_staticGatewayController] = loc(context).invalidIpAddress;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _staticGatewayController.text;
              widget.onChanged(widget.wan.copyWith(staticGateway: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_staticGatewayController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).dns1),
        AppIPFormField(
          key: ValueKey(widget.isPrimary ? 'primaryStaticDNS' : 'secondaryStaticDNS'),
          semanticLabel: widget.isPrimary ? 'primaryStaticDNS' : 'secondaryStaticDNS',
          identifier: widget.isPrimary ? 'primaryStaticDNS' : 'secondaryStaticDNS',
          border: const OutlineInputBorder(),
          controller: _staticDNSController,
          onChanged: (value) {
            final isValid = IpAddressValidator().validate(value);
            if (isValid) {
              widget.errors.remove(_staticDNSController);
            } else {
              widget.errors[_staticDNSController] = loc(context).invalidIpAddress;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _staticDNSController.text;
              widget.onChanged(widget.wan.copyWith(staticDns1: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_staticDNSController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).dns2Optional),
        AppIPFormField(
          key:
              ValueKey(widget.isPrimary ? 'primaryStaticDNS2' : 'secondaryStaticDNS2'),
          semanticLabel:
              widget.isPrimary ? 'primaryStaticDNS2' : 'secondaryStaticDNS2',
          identifier: widget.isPrimary ? 'primaryStaticDNS2' : 'secondaryStaticDNS2',
          border: const OutlineInputBorder(),
          controller: _staticDNS2Controller,
          onChanged: (value) {
            final isValid = IpAddressValidator().validate(value);
            if (isValid) {
              widget.errors.remove(_staticDNS2Controller);
            } else {
              widget.errors[_staticDNS2Controller] = loc(context).invalidIpAddress;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _staticDNS2Controller.text;
              widget.onChanged(
                  widget.wan.copyWith(staticDns2: () => value.isEmpty ? null : value));
              setState(() {});
            }
          },
          errorText: widget.errors[_staticDNS2Controller],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).dns3Optional),
        AppIPFormField(
          key:
              ValueKey(widget.isPrimary ? 'primaryStaticDNS3' : 'secondaryStaticDNS3'),
          semanticLabel:
              widget.isPrimary ? 'primaryStaticDNS3' : 'secondaryStaticDNS3',
          identifier: widget.isPrimary ? 'primaryStaticDNS3' : 'secondaryStaticDNS3',
          border: const OutlineInputBorder(),
          controller: _staticDNS3Controller,
          onChanged: (value) {
            final isValid = IpAddressValidator().validate(value);
            if (isValid) {
              widget.errors.remove(_staticDNS3Controller);
            } else {
              widget.errors[_staticDNS3Controller] = loc(context).invalidIpAddress;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _staticDNS3Controller.text;
              widget.onChanged(
                  widget.wan.copyWith(staticDns3: () => value.isEmpty ? null : value));
              setState(() {});
            }
          },
          errorText: widget.errors[_staticDNS3Controller],
        ),
      ],
    );
  }
}

// PPPoE WAN Settings Form
class PPPoEWANSettingsForm extends StatefulWidget {
  final bool isPrimary;
  final DualWANConfiguration wan;
  final Function(DualWANConfiguration) onChanged;
  final Map<TextEditingController, String?> errors;

  const PPPoEWANSettingsForm({
    Key? key,
    required this.isPrimary,
    required this.wan,
    required this.onChanged,
    required this.errors,
  }) : super(key: key);

  @override
  State<PPPoEWANSettingsForm> createState() => _PPPoEWANSettingsFormState();
}

class _PPPoEWANSettingsFormState extends State<PPPoEWANSettingsForm> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _serviceNameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.wan.username ?? '');
    _passwordController = TextEditingController(text: widget.wan.password ?? '');
    _serviceNameController = TextEditingController(text: widget.wan.serviceName ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).username),
        AppTextField.outline(
          key: ValueKey(
              widget.isPrimary ? 'primaryPPPoEUsername' : 'secondaryPPPoEUsername'),
          semanticLabel:
              widget.isPrimary ? 'primaryPPPoEUsername' : 'secondaryPPPoEUsername',
          identifier:
              widget.isPrimary ? 'primaryPPPoEUsername' : 'secondaryPPPoEUsername',
          controller: _usernameController,
          onChanged: (value) {
            final isValid = value.isNotEmpty;
            if (isValid) {
              widget.errors.remove(_usernameController);
            } else {
              widget.errors[_usernameController] = loc(context).invalidUsername;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _usernameController.text;
              widget.onChanged(widget.wan.copyWith(username: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_usernameController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).password),
        AppTextField.outline(
          key: ValueKey(
              widget.isPrimary ? 'primaryPPPoEPassword' : 'secondaryPPPoEPassword'),
          semanticLabel:
              widget.isPrimary ? 'primaryPPPoEPassword' : 'secondaryPPPoEPassword',
          identifier:
              widget.isPrimary ? 'primaryPPPoEPassword' : 'secondaryPPPoEPassword',
          controller: _passwordController,
          onChanged: (value) {
            final isValid = value.isNotEmpty;
            if (isValid) {
              widget.errors.remove(_passwordController);
            } else {
              widget.errors[_passwordController] = loc(context).invalidPassword;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _passwordController.text;
              widget.onChanged(widget.wan.copyWith(password: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_passwordController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).serviceNameOptional),
        AppTextField.outline(
          key: ValueKey(widget.isPrimary
              ? 'primaryPPPoEServiceName'
              : 'secondaryPPPoEServiceName'),
          semanticLabel: widget.isPrimary
              ? 'primaryPPPoEServiceName'
              : 'secondaryPPPoEServiceName',
          identifier: widget.isPrimary
              ? 'primaryPPPoEServiceName'
              : 'secondaryPPPoEServiceName',
          controller: _serviceNameController,
          onChanged: (value) {}, // No validation for optional field
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _serviceNameController.text;
              widget.onChanged(widget.wan.copyWith(serviceName: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_serviceNameController],
        ),
      ],
    );
  }
}

// PPTP WAN Settings Form
class PPTPWANSettingsForm extends StatefulWidget {
  final bool isPrimary;
  final DualWANConfiguration wan;
  final Function(DualWANConfiguration) onChanged;
  final Map<TextEditingController, String?> errors;

  const PPTPWANSettingsForm({
    Key? key,
    required this.isPrimary,
    required this.wan,
    required this.onChanged,
    required this.errors,
  }) : super(key: key);

  @override
  State<PPTPWANSettingsForm> createState() => _PPTPWANSettingsFormState();
}

class _PPTPWANSettingsFormState extends State<PPTPWANSettingsForm> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.wan.username ?? '');
    _passwordController = TextEditingController(text: widget.wan.password ?? '');
    _serverController = TextEditingController(text: widget.wan.serviceName ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _pptpIpAddressMode(
            widget.wan.useStaticSettings ?? false, widget.wan, widget.isPrimary, widget.onChanged),
        if (widget.wan.useStaticSettings == true) ...[
          StaticWANSettingsForm(
            isPrimary: widget.isPrimary,
            wan: widget.wan,
            onChanged: widget.onChanged,
            errors: widget.errors,
          ),
          const Divider(),
        ],
        AppText.labelLarge(loc(context).serviceIpName),
        AppIPFormField(
          key:
              ValueKey(widget.isPrimary ? 'primaryPPTPServer' : 'secondaryPPTPServer'),
          semanticLabel:
              widget.isPrimary ? 'primaryPPTPServer' : 'secondaryPPTPServer',
          identifier: widget.isPrimary ? 'primaryPPTPServer' : 'secondaryPPTPServer',
          controller: _serverController,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            if (IpAddressL2TPServerRule().validate(value)) {
              widget.errors.remove(_serverController);
            } else {
              widget.errors[_serverController] = loc(context).invalidIpAddress;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final hasError = widget.errors.containsKey(_serverController);
              if (hasError) {
                setState(() {});

                return;
              }
              final value = _serverController.text;

              widget.onChanged(widget.wan.copyWith(serverIp: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_serverController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).username),
        AppTextField.outline(
          key: ValueKey(
              widget.isPrimary ? 'primaryPPTPUsername' : 'secondaryPPTPUsername'),
          semanticLabel:
              widget.isPrimary ? 'primaryPPTPUsername' : 'secondaryPPTPUsername',
          identifier:
              widget.isPrimary ? 'primaryPPTPUsername' : 'secondaryPPTPUsername',
          controller: _usernameController,
          onChanged: (value) {
            final isValid = value.isNotEmpty;
            if (isValid) {
              widget.errors.remove(_usernameController);
            } else {
              widget.errors[_usernameController] = loc(context).invalidUsername;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final hasError = widget.errors.containsKey(_usernameController);
              if (hasError) {
                setState(() {});

                return;
              }
              final value = _usernameController.text;
              widget.onChanged(widget.wan.copyWith(username: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_usernameController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).password),
        AppTextField.outline(
          key: ValueKey(
              widget.isPrimary ? 'primaryPPTPPassword' : 'secondaryPPTPPassword'),
          semanticLabel:
              widget.isPrimary ? 'primaryPPTPPassword' : 'secondaryPPTPPassword',
          identifier:
              widget.isPrimary ? 'primaryPPTPPassword' : 'secondaryPPTPPassword',
          controller: _passwordController,
          onChanged: (value) {
            final isValid = value.isNotEmpty;
            if (isValid) {
              widget.errors.remove(_passwordController);
            } else {
              widget.errors[_passwordController] = loc(context).invalidPassword;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final hasError = widget.errors.containsKey(_passwordController);
              if (hasError) {
                setState(() {});

                return;
              }
              final value = _passwordController.text;
              widget.onChanged(widget.wan.copyWith(password: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_passwordController],
        ),
      ],
    );
  }

  Widget _pptpIpAddressMode(bool useStaticSettings, DualWANConfiguration wan,
      bool isPrimary, Function(DualWANConfiguration) onChanged) {
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
              onChanged(wan.copyWith(
                useStaticSettings: () => type == PPTPIpAddressMode.specify,
              ));
            },
          ),
        ],
      ),
    );
  }
}

// L2TP WAN Settings Form
class L2TPWANSettingsForm extends StatefulWidget {
  final bool isPrimary;
  final DualWANConfiguration wan;
  final Function(DualWANConfiguration) onChanged;
  final Map<TextEditingController, String?> errors;

  const L2TPWANSettingsForm({
    Key? key,
    required this.isPrimary,
    required this.wan,
    required this.onChanged,
    required this.errors,
  }) : super(key: key);

  @override
  State<L2TPWANSettingsForm> createState() => _L2TPWANSettingsFormState();
}

class _L2TPWANSettingsFormState extends State<L2TPWANSettingsForm> {
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.wan.username ?? '');
    _passwordController = TextEditingController(text: widget.wan.password ?? '');
    _serverController = TextEditingController(text: widget.wan.serviceName ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        AppText.labelLarge(loc(context).serviceIpName),
        AppTextField.outline(
          key:
              ValueKey(widget.isPrimary ? 'primaryL2TPServer' : 'secondaryL2TPServer'),
          semanticLabel:
              widget.isPrimary ? 'primaryL2TPServer' : 'secondaryL2TPServer',
          identifier: widget.isPrimary ? 'primaryL2TPServer' : 'secondaryL2TPServer',
          controller: _serverController,
          onChanged: (value) {}, // No validation for optional field
          onFocusChanged: (focus) {
            if (!focus) {
              final value = _serverController.text;
              widget.onChanged(widget.wan.copyWith(serverIp: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_serverController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).username),
        AppTextField.outline(
          key: ValueKey(
              widget.isPrimary ? 'primaryL2TPUsername' : 'secondaryL2TPUsername'),
          semanticLabel:
              widget.isPrimary ? 'primaryL2TPUsername' : 'secondaryL2TPUsername',
          identifier:
              widget.isPrimary ? 'primaryL2TPUsername' : 'secondaryL2TPUsername',
          controller: _usernameController,
          onChanged: (value) {
            final isValid = value.isNotEmpty;
            if (isValid) {
              widget.errors.remove(_usernameController);
            } else {
              widget.errors[_usernameController] = loc(context).invalidUsername;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final hasError = widget.errors.containsKey(_usernameController);
              if (hasError) {
                setState(() {});

                return;
              }
              final value = _usernameController.text;
              widget.onChanged(widget.wan.copyWith(username: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_usernameController],
        ),
        const AppGap.small3(),
        AppText.labelLarge(loc(context).password),
        AppTextField.outline(
          key: ValueKey(
              widget.isPrimary ? 'primaryL2TPPassword' : 'secondaryL2TPPassword'),
          semanticLabel:
              widget.isPrimary ? 'primaryL2TPPassword' : 'secondaryL2TPPassword',
          identifier:
              widget.isPrimary ? 'primaryL2TPPassword' : 'secondaryL2TPPassword',
          controller: _passwordController,
          onChanged: (value) {
            final isValid = value.isNotEmpty;
            if (isValid) {
              widget.errors.remove(_passwordController);
            } else {
              widget.errors[_passwordController] = loc(context).invalidPassword;
            }
          },
          onFocusChanged: (focus) {
            if (!focus) {
              final hasError = widget.errors.containsKey(_passwordController);
              if (hasError) {
                setState(() {});

                return;
              }
              final value = _passwordController.text;
              widget.onChanged(widget.wan.copyWith(password: () => value));
              setState(() {});
            }
          },
          errorText: widget.errors[_passwordController],
        ),
      ],
    );
  }
}