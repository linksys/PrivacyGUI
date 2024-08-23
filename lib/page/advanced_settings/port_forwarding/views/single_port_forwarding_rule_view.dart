import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/_port_forwarding.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/providers/consts.dart';
import 'package:privacy_gui/page/advanced_settings/port_forwarding/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/devices/_devices.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/semantic.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingRuleView extends ArgumentsConsumerStatelessView {
  const SinglePortForwardingRuleView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SinglePortForwardingRuleContentView(
      args: super.args,
    );
  }
}

class SinglePortForwardingRuleContentView
    extends ArgumentsConsumerStatefulView {
  const SinglePortForwardingRuleContentView({super.key, super.args});

  @override
  ConsumerState<SinglePortForwardingRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<SinglePortForwardingRuleContentView> {
  late final SinglePortForwardingRuleNotifier _notifier;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _externalPortController = TextEditingController();
  final TextEditingController _internalPortController = TextEditingController();
  final TextEditingController _deviceIpAddressController =
      TextEditingController();
  String _protocol = 'Both';
  bool _isEnabled = false;
  List<SinglePortForwardingRule> _rules = [];
  String? _ipError;
  String? _portError;
  final String _tag = 'single-port-forwarding-rule';

  @override
  void initState() {
    _notifier = ref.read(singlePortForwardingRuleProvider.notifier);
    _rules = widget.args['rules'] as List<SinglePortForwardingRule>? ?? [];
    final rule = widget.args['edit'] as SinglePortForwardingRule?;
    if (rule != null) {
      _notifier.goEdit(_rules, rule).then((_) {
        _ruleNameController.text = rule.description;
        _externalPortController.text = '${rule.externalPort}';
        _internalPortController.text = '${rule.internalPort}';
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
    _externalPortController.dispose();
    _internalPortController.dispose();
    _deviceIpAddressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(singlePortForwardingRuleProvider);
    return StyledAppPageView(
      title: loc(context).singlePortForwarding,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _isSaveEnable(),
        isNegitiveEnabled: state.mode == RuleMode.editing ? true : null,
        negitiveLable: loc(context).delete,
        onPositiveTap: () {
          final rule = SinglePortForwardingRule(
              isEnabled: _isEnabled,
              externalPort: int.parse(_externalPortController.text),
              protocol: _protocol,
              internalServerIPAddress: _deviceIpAddressController.text,
              internalPort: int.parse(_internalPortController.text),
              description: _ruleNameController.text);
          final thisContext = context;
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

                thisContext.pop(true);
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
      scrollable: true,
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

  List<Widget> _buildAddContents(SinglePortForwardingRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(SinglePortForwardingRuleState state) {
    return [
      AppListCard(
        title: AppText.labelLarge(
          loc(context).ruleEnabled,
          identifier: semanticIdentifier(tag: _tag, description: 'ruleEnabled'),
        ),
        trailing: AppSwitch(
          identifier: semanticIdentifier(tag: _tag, description: 'ruleEnabled'),
          semanticLabel: loc(context).ruleEnabled,
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
      AppTextField(
        headerText: loc(context).ruleName,
        identifier: semanticIdentifier(tag: _tag, description: 'ruleName'),
        semanticLabel: loc(context).ruleName,
        border: const OutlineInputBorder(),
        controller: _ruleNameController,
        onFocusChanged: _onFocusChange,
      ),
      const AppGap.large2(),
      AppTextField.minMaxNumber(
        headerText: loc(context).externalPort,
        identifier: semanticIdentifier(tag: _tag, description: 'externalPort'),
        semanticLabel: loc(context).externalPort,
        inputType: TextInputType.number,
        border: const OutlineInputBorder(),
        controller: _externalPortController,
        max: 65535,
        min: 0,
        onFocusChanged: _onPortFocusChange,
        errorText: _portError,
      ),
      const AppGap.large2(),
      AppTextField.minMaxNumber(
        headerText: loc(context).internalPort,
        identifier: semanticIdentifier(tag: _tag, description: 'internalPort'),
        semanticLabel: loc(context).internalPort,
        inputType: TextInputType.number,
        border: const OutlineInputBorder(),
        controller: _internalPortController,
        max: 65535,
        min: 0,
        onFocusChanged: _onFocusChange,
      ),
      const AppGap.large2(),
      AppText.labelMedium(
        loc(context).ipAddress,
        identifier: semanticIdentifier(tag: _tag, description: 'ipAddress'),
      ),
      const AppGap.medium(),
      AppIPFormField(
        identifier: semanticIdentifier(tag: _tag, description: 'ipAddress'),
        semanticLabel: loc(context).ipAddress,
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
        identifier: semanticIdentifier(tag: _tag, description: 'selectDevices'),
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
        identifier: semanticIdentifier(tag: _tag, description: 'protocol'),
        semanticLabel: loc(context).protocol,
        title: AppText.labelLarge(
          loc(context).protocol,
          identifier: semanticIdentifier(tag: _tag, description: 'protocol'),
        ),
        description: AppText.bodyLarge(
          getProtocolTitle(context, _protocol),
          identifier: semanticIdentifier(
              tag: _tag, description: 'protocol-description'),
        ),
        trailing: Semantics(
            identifier: semanticIdentifier(tag: _tag, description: 'protocol-edit-icon'),
            label: '${loc(context).protocol} edit icon',
            child: const Icon(LinksysIcons.edit)),
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
        _externalPortController.text.isNotEmpty &&
        _internalPortController.text.isNotEmpty &&
        _notifier.isDeviceIpValidate(_deviceIpAddressController.text) &&
        _portError == null;
  }

  void _onPortFocusChange(bool focus) {
    if (!focus) {
      if (_externalPortController.text.isEmpty) {
        return;
      }
      final externalPort = int.tryParse(_externalPortController.text) ?? 0;
      bool isRuleOverlap = _notifier.isPortConflict(externalPort, _protocol);
      _portError = isRuleOverlap ? loc(context).rulesOverlapError : null;
      _onFocusChange(focus);
    }
  }

  void _onFocusChange(bool focus) {
    if (!focus) {
      setState(() {});
    }
  }
}
