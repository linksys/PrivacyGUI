import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/models/port_range_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/providers/consts.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeForwardingRuleView extends ArgumentsConsumerStatelessView {
  const PortRangeForwardingRuleView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortRangeForwardingRuleContentView(
      args: super.args,
    );
  }
}

class PortRangeForwardingRuleContentView extends ArgumentsConsumerStatefulView {
  const PortRangeForwardingRuleContentView({super.key, super.args});

  @override
  ConsumerState<PortRangeForwardingRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<PortRangeForwardingRuleContentView> {
  late final PortRangeForwardingRuleNotifier _notifier;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstExternalPortController =
      TextEditingController();
  final TextEditingController _lastExternalPortController =
      TextEditingController();
  final TextEditingController _deviceIpAddressController =
      TextEditingController();
  String _protocol = 'Both';
  bool _isEnabled = false;
  List<PortRangeForwardingRule> _rules = [];
  String? _ipError;
  String? _portError;

  @override
  void initState() {
    _notifier = ref.read(portRangeForwardingRuleProvider.notifier);
    _rules = widget.args['rules'] ?? [];
    final rule = widget.args['edit'] as PortRangeForwardingRule?;
    if (rule != null) {
      _notifier.goEdit(_rules, rule).then((_) {
        _ruleNameController.text = rule.description;
        _firstExternalPortController.text = '${rule.firstExternalPort}';
        _lastExternalPortController.text = '${rule.lastExternalPort}';
        _deviceIpAddressController.text = rule.internalServerIPAddress;
        setState(() {
          _isEnabled = rule.isEnabled;
        });
      });
    } else {
      _notifier.goAdd(_rules).then((_) {
        final prefixIp =
            NetworkUtils.getIpPrefix(_notifier.ipAddress, _notifier.subnetMask);
        _deviceIpAddressController.text = prefixIp;
        setState(() {
          _isEnabled = true;
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _ruleNameController.dispose();
    _firstExternalPortController.dispose();
    _lastExternalPortController.dispose();
    _deviceIpAddressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeForwardingRuleProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).portRangeForwarding,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isSaveEnable(),
        isNegitiveEnabled: state.mode == RuleMode.editing ? true : null,
        negitiveLable: loc(context).delete,
        onPositiveTap: () {
          final rule = PortRangeForwardingRule(
              isEnabled: _isEnabled,
              firstExternalPort: int.parse(_firstExternalPortController.text),
              protocol: _protocol,
              internalServerIPAddress: _deviceIpAddressController.text,
              lastExternalPort: int.parse(_lastExternalPortController.text),
              description: _ruleNameController.text);
          doSomethingWithSpinner(
            context,
            _notifier.save(rule),
          ).then(
            (value) {
              if (value == true) {
                showSuccessSnackBar(
                    context,
                    _notifier.isEdit()
                        ? loc(context).ruleUpdated
                        : loc(context).ruleAdded);

                context.pop(true);
              } else {
                showFailedSnackBar(context, loc(context).failedExclamation);
              }
            },
          );
        },
        onNegitiveTap: () {
          doSomethingWithSpinner(
            context,
            _notifier.delete(),
          ).then((value) {
            if (value == true) {
              showSimpleSnackBar(context, loc(context).ruleDeleted);
              context.pop(true);
            } else {
              showFailedSnackBar(context, loc(context).failedExclamation);
            }
          });
        },
      ),
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            if (state.mode == RuleMode.editing)
              ..._buildEditContents(state)
            else
              ..._buildAddContents(state)
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddContents(PortRangeForwardingRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(PortRangeForwardingRuleState state) {
    return [
      AppListCard(
        title: AppText.labelLarge(loc(context).ruleEnabled),
        trailing: AppSwitch(
          semanticLabel: 'rule enabled',
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
          },
        ),
      ),
      const AppGap.large2(),
      ...buildInputForms(),
    ];
  }

  List<Widget> buildInputForms() {
    final submaskToken = _notifier.subnetMask.split('.');

    return [
      AppTextField.outline(
        headerText: loc(context).ruleName,
        controller: _ruleNameController,
        onFocusChanged: _onFocusChange,
      ),
      const AppGap.large2(),
      AppTextField.minMaxNumber(
        border: const OutlineInputBorder(),
        headerText: loc(context).startPort,
        controller: _firstExternalPortController,
        max: 65535,
        onFocusChanged: _onPortFocusChange,
        errorText: _portError != null ? '' : null,
      ),
      const AppGap.large2(),
      AppTextField.minMaxNumber(
        border: const OutlineInputBorder(),
        headerText: loc(context).endPort,
        controller: _lastExternalPortController,
        max: 65535,
        onFocusChanged: _onPortFocusChange,
        errorText: _portError,
      ),
      const AppGap.large2(),
      AppText.labelMedium(loc(context).ipAddress),
      const AppGap.medium(),
      AppIPFormField(
        semanticLabel: 'ip address',
        controller: _deviceIpAddressController,
        border: const OutlineInputBorder(),
        octet1ReadOnly: submaskToken[0] == '255',
        octet2ReadOnly: submaskToken[1] == '255',
        octet3ReadOnly: submaskToken[2] == '255',
        octet4ReadOnly: submaskToken[3] == '255',
        onFocusChanged: (focus) {
          if (!focus) {
            _ipError =
                !_notifier.isDeviceIpValidate(_deviceIpAddressController.text)
                    ? loc(context).invalidIpAddress
                    : null;
            _onFocusChange(focus);
          }
        },
        errorText: _ipError,
      ),
      const AppGap.large2(),
      AppTextButton(
        loc(context).selectDevices,
        onTap: () async {
          final result = await context.pushNamed<List<DeviceListItem>?>(
              RouteNamed.devicePicker,
              extra: {'type': 'ipv4', 'selectMode': 'single'});

          if (result != null) {
            final device = result.first;
            _deviceIpAddressController.text = device.ipv4Address;
          }
        },
      ),
      const AppGap.large2(),
      AppListCard(
        title: AppText.labelLarge(loc(context).protocol),
        description: AppText.bodyLarge(getProtocolTitle(context, _protocol)),
        trailing: const Icon(
          LinksysIcons.edit,
          semanticLabel: 'edit',
        ),
        onTap: () async {
          String? protocol = await showSelectProtocolModal(
            context,
            _protocol,
          );
          if (protocol != null) {
            setState(() {
              _protocol = protocol;
            });
          }
        },
      ),
    ];
  }

  bool _isSaveEnable() {
    return _ruleNameController.text.isNotEmpty &&
        _firstExternalPortController.text.isNotEmpty &&
        _lastExternalPortController.text.isNotEmpty &&
        _notifier.isDeviceIpValidate(_deviceIpAddressController.text) &&
        _portError == null;
  }

  void _onPortFocusChange(bool focus) {
    if (!focus) {
      if (_firstExternalPortController.text.isEmpty ||
          _lastExternalPortController.text.isEmpty) {
        return;
      }
      final firstPort = int.tryParse(_firstExternalPortController.text) ?? 0;
      final lastPort = int.tryParse(_lastExternalPortController.text) ?? 0;
      bool isValidPortRange = lastPort - firstPort > 0;
      bool isRuleOverlap =
          _notifier.isPortConflict(firstPort, lastPort, _protocol);
      _portError = !isValidPortRange
          ? loc(context).portRangeError
          : isRuleOverlap
              ? loc(context).rulesOverlapError
              : null;
      _onFocusChange(focus);
    }
  }

  void _onFocusChange(bool focus) {
    if (!focus) {
      setState(() {});
    }
  }
}
