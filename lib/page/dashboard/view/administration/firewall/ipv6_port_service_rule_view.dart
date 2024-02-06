import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/models/ipv6_firewall_rule.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/dashboard/view/administration/firewall/ipv6_field_with_device_picker.dart';
import 'package:linksys_app/provider/devices/device_list_provider.dart';
import 'package:linksys_app/provider/ipv6_port_service/_ipv6_port_service.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

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
  String _protocol = 'Both';
  List<IPv6FirewallRule> _rules = [];

  @override
  void initState() {
    _notifier = ref.read(ipv6PortServiceRuleProvider.notifier);
    _rules = widget.args['rules'] ?? [];
    final rule = widget.args['edit'] as IPv6FirewallRule?;
    if (rule != null) {
      _notifier.goEdit(_rules, rule).then((_) {
        _ruleNameController.text = rule.description;
        _firstExternalPortController.text =
            '${rule.portRanges.firstOrNull?.firstPort ?? ''}';
        _lastExternalPortController.text =
            '${rule.portRanges.firstOrNull?.lastPort ?? ''}';
        _ipAddressController.text = rule.ipv6Address;
      });
    } else {
      _notifier.goAdd(_rules);
    }
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
      title: getAppLocalizations(context).port_range_forwarding,
      actions: [
        AppTextButton(
          getAppLocalizations(context).save,
          onTap: () {
            final rule = IPv6FirewallRule(
                isEnabled: true,
                portRanges: [
                  PortRange(
                    protocol: _protocol,
                    firstPort: int.parse(_firstExternalPortController.text),
                    lastPort: int.parse(_lastExternalPortController.text),
                  ),
                ],
                ipv6Address: _ipAddressController.text,
                description: _ruleNameController.text);
            _notifier.save(rule).then((value) {
              if (value) {
                if (_notifier.isEdit()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppToastHelp.positiveToast(context,
                        text: getAppLocalizations(context).rule_updated),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppToastHelp.positiveToast(context,
                        text: getAppLocalizations(context).rule_added),
                  );
                }

                context.pop(true);
              }
            });
          },
        )
      ],
      child: AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppGap.semiBig(),
            if (state.mode == Ipv6PortServiceRuleMode.editing)
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
      AppPanelWithSwitch(
        value: state.rule?.isEnabled ?? false,
        title: getAppLocalizations(context).rule_enabled,
        onChangedEvent: (value) {},
      ),
      ...buildInputForms(),
      AppTextButton(
        getAppLocalizations(context).delete_rule,
        onTap: () {
          _notifier.delete().then((value) {
            if (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppToastHelp.positiveToast(context,
                    text: getAppLocalizations(context).rule_deleted),
              );
              context.pop(true);
            }
          });
        },
      ),
    ];
  }

  List<Widget> buildInputForms() {
    return [
      AppTextField(
          headerText: getAppLocalizations(context).rule_name,
          hintText: getAppLocalizations(context).rule_name,
          controller: _ruleNameController),
      const AppGap.semiSmall(),
      AppTextField.minMaxNumber(
        headerText: getAppLocalizations(context).start_port,
        hintText: getAppLocalizations(context).start_port,
        controller: _firstExternalPortController,
        max: 65535,
      ),
      const AppGap.semiSmall(),
      AppTextField.minMaxNumber(
        headerText: getAppLocalizations(context).end_port,
        hintText: getAppLocalizations(context).end_port,
        controller: _lastExternalPortController,
        max: 65535,
      ),
      const AppGap.semiSmall(),
      AppText.labelMedium(getAppLocalizations(context).device_ip_address),
      AppIpv6FieldWithDevicePicker(
        controller: _ipAddressController,
        deviceList: ref
            .read(deviceListProvider)
            .devices
            .where((element) => element.isOnline)
            .toList(),
        selectedResult: (item) => item.ipv4Address,
      ),
      const AppGap.semiSmall(),
      AppPanelWithInfo(
        title: getAppLocalizations(context).protocol,
        infoText: getProtocolTitle(_protocol),
        onTap: () async {
          String? protocol = await context.pushNamed(
            RouteNamed.selectProtocol,
            extra: {'selected': _protocol},
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

  String getProtocolTitle(String key) {
    if (key == 'UDP') {
      return getAppLocalizations(context).udp;
    } else if (key == 'TCP') {
      return getAppLocalizations(context).tcp;
    } else {
      return getAppLocalizations(context).udp_and_tcp;
    }
  }
}
