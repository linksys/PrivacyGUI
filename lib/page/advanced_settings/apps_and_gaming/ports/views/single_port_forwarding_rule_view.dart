import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/_ports.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

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

  String? _ipError;
  String? _portError;
  String? _descriptionError;

  bool _isEdit = false;

  @override
  void initState() {
    _notifier = ref.read(singlePortForwardingRuleProvider.notifier);
    final state = ref.read(singlePortForwardingListProvider);
    final routerIp = state.routerIp;
    final subnetMask = state.subnetMask;
    final rules = widget.args['items'] as List<SinglePortForwardingRule>? ?? [];
    var rule = widget.args['edit'] as SinglePortForwardingRule?;
    int? index;

    if (rule != null) {
      _isEdit = true;
      _ruleNameController.text = rule.description;
      _externalPortController.text = '${rule.externalPort}';
      _internalPortController.text = '${rule.internalPort}';
      _deviceIpAddressController.text = rule.internalServerIPAddress;
      index = rules.indexOf(rule);
    } else {
      _isEdit = false;

      final prefixIp =
          NetworkUtils.getIpPrefix(state.routerIp, state.subnetMask);
      _deviceIpAddressController.text = prefixIp.replaceAll('.0', '');
      rule = SinglePortForwardingRule(
          isEnabled: true,
          externalPort: 0,
          protocol: 'Both',
          internalServerIPAddress: prefixIp,
          internalPort: 0,
          description: '');
    }
    doSomethingWithSpinner(context, Future.doWhile(() => !mounted)).then((_) {
      _notifier.init(rules, rule, index, routerIp, subnetMask);
    });

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
    return StyledAppPageView(
      title: loc(context).singlePortForwarding,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _notifier.isRuleValid(),
        positiveLabel: _isEdit ? loc(context).update : loc(context).add,
        onPositiveTap: () {
          final rule = ref.read(singlePortForwardingRuleProvider).rule;
          context.pop(rule);
        },
      ),
      scrollable: true,
      child: (context, constraints, scrollController) =>AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            if (_isEdit) ..._buildEditContents() else ..._buildAddContents()
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddContents() {
    return buildInputForms();
  }

  List<Widget> _buildEditContents() {
    final state = ref.watch(singlePortForwardingRuleProvider);

    return [
      AppListCard(
        showBorder: false,
        padding: EdgeInsets.zero,
        title: AppText.labelLarge(loc(context).ruleEnabled),
        trailing: AppSwitch(
          semanticLabel: 'rule enabled',
          value: state.rule?.isEnabled ?? true,
          onChanged: (value) {
            _notifier.updateRule(state.rule?.copyWith(isEnabled: value));
          },
        ),
      ),
      const AppGap.large2(),
      ...buildInputForms(),
    ];
  }

  List<Widget> buildInputForms() {
    final state = ref.watch(singlePortForwardingRuleProvider);
    final subnetMask = state.subnetMask;
    final submaskToken = subnetMask.split('.');
    return [
      AppTextField(
        headerText: loc(context).applicationName,
        border: const OutlineInputBorder(),
        controller: _ruleNameController,
        onChanged: (value) {
          _notifier.updateRule(state.rule?.copyWith(description: value));
        },
        onFocusChanged: (focus) {
          setState(() {
          _descriptionError = _notifier.isNameValid(state.rule?.description ?? '') ? null : loc(context).theNameMustNotBeEmpty;
          });
        },
        errorText: _descriptionError,
      ),
      const AppGap.large2(),
      AppText.bodyMedium(loc(context).ports),
      const AppGap.medium(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField.minMaxNumber(
              headerText: loc(context).internalPort,
              inputType: TextInputType.number,
              border: const OutlineInputBorder(),
              controller: _internalPortController,
              max: 65535,
              min: 0,
              onFocusChanged: _onFocusChange,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(internalPort: int.tryParse(value) ?? 0));
              },
            ),
          ),
          const AppGap.small1(),
          Expanded(
            child: AppTextField.minMaxNumber(
              headerText: loc(context).externalPort,
              inputType: TextInputType.number,
              border: const OutlineInputBorder(),
              controller: _externalPortController,
              max: 65535,
              min: 0,
              onFocusChanged: (value) =>
                  _onPortFocusChange(value, state.rule?.protocol ?? ''),
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(externalPort: int.tryParse(value) ?? 0));
              },
              errorText: _portError,
            ),
          ),
        ],
      ),
      const AppGap.large2(),
      AppDropdownButton(
        title: loc(context).protocol,
        initial: state.rule?.protocol ?? 'Both',
        items: const ['TCP', 'UDP', 'Both'],
        label: (e) => getProtocolTitle(context, e),
        onChanged: (value) {
          _notifier.updateRule(state.rule?.copyWith(protocol: value));
        },
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
        onChanged: (value) {
          _notifier
              .updateRule(state.rule?.copyWith(internalServerIPAddress: value));
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
    ];
  }

  void _onPortFocusChange(bool focus, String protocol) {
    if (!focus) {
      if (_externalPortController.text.isEmpty) {
        return;
      }
      final externalPort = int.tryParse(_externalPortController.text) ?? 0;
      bool isRuleOverlap = _notifier.isPortConflict(externalPort, protocol);
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
