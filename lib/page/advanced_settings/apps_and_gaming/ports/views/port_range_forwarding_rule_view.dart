import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
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
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

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
  String? _descriptionError;
  String? _ipError;
  String? _portError;
  bool _isEdit = false;

  @override
  void initState() {
    _notifier = ref.read(portRangeForwardingRuleProvider.notifier);
    final state = ref.read(portRangeForwardingListProvider);
    final routerIp = state.status.routerIp;
    final subnetMask = state.status.subnetMask;
    final List<PortRangeForwardingRuleUIModel> rules = widget.args['items'] ?? [];
    var rule = widget.args['edit'] as PortRangeForwardingRuleUIModel?;
    int? index;

    if (rule != null) {
      _isEdit = true;

      _ruleNameController.text = rule.description;
      _firstExternalPortController.text = '${rule.firstExternalPort}';
      _lastExternalPortController.text = '${rule.lastExternalPort}';
      _deviceIpAddressController.text = rule.internalServerIPAddress;
      index = rules.indexOf(rule);
    } else {
      _isEdit = false;

      final prefixIp = NetworkUtils.getIpPrefix(
          state.status.routerIp, state.status.subnetMask);
      _deviceIpAddressController.text = prefixIp.replaceAll('.0', '');
      rule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 0,
        protocol: 'Both',
        internalServerIPAddress: prefixIp,
        lastExternalPort: 0,
        description: '',
      );
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
    _firstExternalPortController.dispose();
    _lastExternalPortController.dispose();
    _deviceIpAddressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(portRangeForwardingRuleProvider);
    return StyledAppPageView.withSliver(
      scrollable: true,
      title: loc(context).portRangeForwarding,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _notifier.isRuleValid(),
        onPositiveTap: () {
          final rule = ref.read(portRangeForwardingRuleProvider).rule;
          context.pop(rule);
        },
      ),
      child: (context, constraints) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.large2(),
            if (_isEdit)
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
    final state = ref.watch(portRangeForwardingRuleProvider);
    final subnetMask = state.subnetMask;
    final submaskToken = subnetMask.split('.');
    return [
      AppTextField.outline(
        key: const Key('applicationNameTextField'),
        headerText: loc(context).applicationName,
        controller: _ruleNameController,
        onFocusChanged: _onFocusChange,
        onChanged: (value) {
          _notifier.updateRule(state.rule?.copyWith(description: value));
        },
        errorText: _descriptionError,
      ),
      const AppGap.large2(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField.minMaxNumber(
              key: const Key('firstExternalPortTextField'),
              border: const OutlineInputBorder(),
              headerText: loc(context).startPort,
              controller: _firstExternalPortController,
              max: 65535,
              onFocusChanged: (value) =>
                  _onPortFocusChange(value, state.rule?.protocol ?? ''),
              errorText: _portError != null ? '' : null,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(firstExternalPort: int.tryParse(value) ?? 0));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: Spacing.small2,
                right: Spacing.small2,
                top: Spacing.medium),
            child: AppText.bodyMedium(loc(context).to),
          ),
          Expanded(
            child: AppTextField.minMaxNumber(
              key: const Key('lastExternalPortTextField'),
              border: const OutlineInputBorder(),
              headerText: loc(context).endPort,
              controller: _lastExternalPortController,
              max: 65535,
              onFocusChanged: (value) =>
                  _onPortFocusChange(value, state.rule?.protocol ?? ''),
              errorText: _portError,
              onChanged: (value) {
                _notifier.updateRule(state.rule
                    ?.copyWith(lastExternalPort: int.tryParse(value) ?? 0));
              },
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
        key: const Key('ipAddressTextField'),
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
        onChanged: (value) {
          _notifier
              .updateRule(state.rule?.copyWith(internalServerIPAddress: value));
        },
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
      if (_firstExternalPortController.text.isEmpty ||
          _lastExternalPortController.text.isEmpty) {
        return;
      }
      final firstPort = int.tryParse(_firstExternalPortController.text) ?? 0;
      final lastPort = int.tryParse(_lastExternalPortController.text) ?? 0;
      bool isValidPortRange = _notifier.isPortRangeValid(firstPort, lastPort);
      bool isRuleOverlap =
          _notifier.isPortConflict(firstPort, lastPort, protocol);
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
