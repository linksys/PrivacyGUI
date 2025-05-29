import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/_firewall.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/input_field/ipv6_form_field.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

class Ipv6PortServiceRuleView extends ArgumentsConsumerStatelessView {
  const Ipv6PortServiceRuleView({super.key, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Ipv6PortServiceRuleContentView(
      args: super.args,
    );
  }
}

class Ipv6PortServiceRuleContentView extends ArgumentsConsumerStatefulView {
  const Ipv6PortServiceRuleContentView({super.key, super.args});

  @override
  ConsumerState<Ipv6PortServiceRuleContentView> createState() =>
      _AddRuleContentViewState();
}

class _AddRuleContentViewState
    extends ConsumerState<Ipv6PortServiceRuleContentView> {
  late final Ipv6PortServiceRuleNotifier _notifier;

  final TextEditingController _ruleNameController = TextEditingController();
  final TextEditingController _firstExternalPortController =
      TextEditingController();
  final TextEditingController _lastExternalPortController =
      TextEditingController();
  final TextEditingController _ipAddressController = TextEditingController();
  String? _portError;
  String? _descriptionError;
  String? _ipError;

  bool _isEdit = false;

  @override
  void initState() {
    _notifier = ref.read(ipv6PortServiceRuleProvider.notifier);

    final rules = widget.args['items'] ?? [];
    var rule = widget.args['edit'] as IPv6FirewallRule?;
    int? index;

    if (rule != null) {
      _isEdit = true;

      _ruleNameController.text = rule.description;
      _firstExternalPortController.text =
          '${rule.portRanges.firstOrNull?.firstPort ?? ''}';
      _lastExternalPortController.text =
          '${rule.portRanges.firstOrNull?.lastPort ?? ''}';
      _ipAddressController.text = rule.ipv6Address;
      index = rules.indexOf(rule);
    } else {
      rule = IPv6FirewallRule(
          description: '',
          ipv6Address: '',
          isEnabled: true,
          portRanges: const [
            PortRange(protocol: 'Both', firstPort: 0, lastPort: 0)
          ]);
    }
    doSomethingWithSpinner(context, Future.doWhile(() => !mounted)).then((_) {
      _notifier.init(rules, rule, index);
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _ruleNameController.dispose();
    _firstExternalPortController.dispose();
    _lastExternalPortController.dispose();
    _ipAddressController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ipv6PortServiceRuleProvider);
    return StyledAppPageView(
      scrollable: true,
      title: loc(context).ipv6PortServices,
      bottomBar: PageBottomBar(
        isPositiveEnabled: _notifier.isRuleValid(),
        onPositiveTap: () {
          final rule = ref.read(ipv6PortServiceRuleProvider).rule;
          context.pop(rule);
        },
      ),
      child: (context, constraints) => AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

  List<Widget> _buildAddContents(Ipv6PortServiceRuleState state) {
    return buildInputForms();
  }

  List<Widget> _buildEditContents(Ipv6PortServiceRuleState state) {
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
    final state = ref.watch(ipv6PortServiceRuleProvider);

    return [
      AppTextField.outline(
        headerText: loc(context).ruleName,
        controller: _ruleNameController,
        onFocusChanged: (focus) {
          setState(() {
            _descriptionError = focus
                ? null
                : _notifier.isRuleNameValidate(_ruleNameController.text)
                    ? null
                    : loc(context).notBeEmptyAndLessThanThirtyThree;
          });
        },
        onChanged: (value) {
          _notifier.updateRule(state.rule?.copyWith(description: value));
        },
        errorText: _descriptionError,
      ),
      const AppGap.large2(),
      AppDropdownButton(
        title: loc(context).protocol,
        initial: state.rule?.portRanges.firstOrNull?.protocol ?? 'Both',
        items: const ['TCP', 'UDP', 'Both'],
        label: (e) => getProtocolTitle(context, e),
        onChanged: (value) {
          final portRanges = state.rule?.portRanges ?? [];
          final portRange = portRanges.firstOrNull;
          _notifier.updateRule(
            state.rule?.copyWith(
              portRanges: portRange == null
                  ? null
                  : [portRange.copyWith(protocol: value)],
            ),
          );
        },
      ),
      const AppGap.large2(),
      AppText.labelMedium(loc(context).ipAddress),
      const AppGap.medium(),
      AppIPv6FormField(
        semanticLabel: 'ip address',
        controller: _ipAddressController,
        border: const OutlineInputBorder(),
        onChanged: (value) {
          _notifier.updateRule(state.rule?.copyWith(ipv6Address: value));
        },
        onFocusChanged: (focus) {
          setState(() {
            _ipError = focus
                ? null
                : _notifier.isDeviceIpValidate(_ipAddressController.text)
                    ? null
                    : loc(context).invalidIpAddress;
          });
        },
        errorText: _ipError,
      ),
      const AppGap.large2(),
      AppTextButton(
        loc(context).selectDevices,
        onTap: () async {
          final result = await context.pushNamed<List<DeviceListItem>?>(
              RouteNamed.devicePicker,
              extra: {'type': 'ipv6', 'selectMode': 'single'});

          if (result != null) {
            final device = result.first;
            _ipAddressController.text = device.ipv6Address;
          }
        },
      ),
      const AppGap.large2(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField.minMaxNumber(
              border: const OutlineInputBorder(),
              headerText: loc(context).startPort,
              controller: _firstExternalPortController,
              max: 65535,
              onFocusChanged: (value) => _onPortFocusChange(value,
                  '${state.rule?.portRanges.firstOrNull?.firstPort ?? 0}'),
              onChanged: (value) {
                final portRanges = state.rule?.portRanges ?? [];
                final portRange = portRanges.firstOrNull;
                _notifier.updateRule(
                  state.rule?.copyWith(
                    portRanges: portRange == null
                        ? null
                        : [
                            portRange.copyWith(
                                firstPort: int.tryParse(value) ?? 0)
                          ],
                  ),
                );
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
              border: const OutlineInputBorder(),
              headerText: loc(context).endPort,
              controller: _lastExternalPortController,
              max: 65535,
              onFocusChanged: (value) => _onPortFocusChange(value,
                  '${state.rule?.portRanges.firstOrNull?.lastPort ?? 0}'),
              errorText: _portError,
              onChanged: (value) {
                final portRanges = state.rule?.portRanges ?? [];
                final portRange = portRanges.firstOrNull;
                _notifier.updateRule(
                  state.rule?.copyWith(
                    portRanges: portRange == null
                        ? null
                        : [
                            portRange.copyWith(
                                lastPort: int.tryParse(value) ?? 0)
                          ],
                  ),
                );
              },
            ),
          ),
        ],
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
      setState(() {
        _portError = !isValidPortRange
            ? loc(context).portRangeError
            : isRuleOverlap
                ? loc(context).rulesOverlapError
                : null;
      });
    }
  }
}
